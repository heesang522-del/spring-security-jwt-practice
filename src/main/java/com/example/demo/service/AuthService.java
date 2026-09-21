package com.example.demo.service;

import com.example.demo.dto.LoginResponse;
import com.example.demo.dto.MemberDto;
import com.example.demo.dto.RefreshTokenDto;
import com.example.demo.repository.MemberRepository;
import com.example.demo.security.CustomAuthenticationProvider;
import com.example.demo.security.CustomUserDetails;
import com.example.demo.security.JwtTokenProvider;
import com.example.demo.security.RefreshTokenRedisService;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseCookie;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class AuthService {

    private final MemberRepository memberRepository;
    private final PasswordEncoder passwordEncoder;
    private final EmailVerificationService emailVerificationService;
    private final CustomAuthenticationProvider customAuthenticationProvider;
    private final JwtTokenProvider jwtTokenProvider;
    private final RefreshTokenRedisService redisService;

    /**
     * 💡 [REST API 로그인 및 RTR 토큰 발급 로직]
     * 계정 상태(휴면, 잠금, 정지 등)를 검증하고 인증 성공 시 토큰 생성 및 Redis에 jti를 저장합니다.
     */
    @Transactional
    public LoginResponse login(String memberId, String memberPassword, boolean rememberMe, HttpServletResponse response) {
        // 1. 입력값 검증
        if (!StringUtils.hasText(memberId) || !StringUtils.hasText(memberPassword)) {
            throw new BadCredentialsException("아이디와 비밀번호를 입력해 주세요.");
        }

        // 2. CustomAuthenticationProvider를 통해 사용자 인증 수행
        Authentication authentication;
        try {
            authentication = customAuthenticationProvider.authenticate(
                    UsernamePasswordAuthenticationToken.unauthenticated(memberId, memberPassword)
            );
        } catch (AuthenticationException e) {
            throw e;
        }

        // 3. SecurityContext에 인증 객체 저장
        SecurityContextHolder.getContext().setAuthentication(authentication);

        CustomUserDetails userDetails = (CustomUserDetails) authentication.getPrincipal();
        MemberDto memberDto = userDetails.getMemberDto();
        String role = memberDto.getMemberRole();

        // 4. 마지막 로그인 시간 갱신
        memberRepository.updateLastLoginAt(memberDto.getMemberId());

        // 5. Access Token 생성 및 쿠키 설정 (페이지 이동 시 자동 전송용)
        String accessToken = jwtTokenProvider.generateAccessToken(memberDto.getMemberId(), role);

        ResponseCookie accessTokenCookie = ResponseCookie.from("accessToken", accessToken)
                .httpOnly(true)
                .secure(false) // HTTPS 적용 시 true
                .path("/")
                .maxAge(jwtTokenProvider.getAccessTokenExpiration() / 1000) // Access Token 만료시간 적용
                .sameSite("Lax")
                .build();

        response.addHeader(org.springframework.http.HttpHeaders.SET_COOKIE, accessTokenCookie.toString());

        // 6. Refresh Token 생성 및 Redis jti 저장 (rememberMe 옵션 시 처리)
        if (rememberMe) {
            RefreshTokenDto refreshTokenDto = jwtTokenProvider.generateRefreshToken(memberDto.getMemberId(), role);
            String refreshToken = refreshTokenDto.getRefreshToken();
            String jti = refreshTokenDto.getJti();

            // Redis에 jti 저장
            redisService.saveRefreshToken(memberDto.getMemberId(), jti, jwtTokenProvider.getRefreshTokenExpiration());

            // Refresh Token 쿠키 설정
            ResponseCookie refreshTokenCookie = ResponseCookie.from("refreshToken", refreshToken)
                    .httpOnly(true)
                    .secure(false)
                    .path("/")
                    .maxAge(jwtTokenProvider.getRefreshTokenExpiration() / 1000)
                    .sameSite("Lax")
                    .build();

            response.addHeader(org.springframework.http.HttpHeaders.SET_COOKIE, refreshTokenCookie.toString());
        }

        return new LoginResponse(
                accessToken,
                "Bearer",
                memberDto.getMemberId(),
                role
        );
    }

    /**
     * 💡 [RTR 기반 토큰 재발급 로직]
     * Refresh Token을 검증하고 Redis의 jti와 교차 검증한 뒤,
     * 새로운 Access Token과 Refresh Token(새 jti)을 발급(Rotation)합니다.
     */
    @Transactional
    public String reissue(String refreshToken, HttpServletResponse response) {
        // 1. 전달받은 Refresh Token의 기본 유효성(서명, 만료일 등)을 검증합니다.
        if (!StringUtils.hasText(refreshToken) || !jwtTokenProvider.validateToken(refreshToken)) {
            throw new BadCredentialsException("유효하지 않거나 만료된 Refresh Token입니다.");
        }

        // 2. 토큰 Payload에서 회원 정보와 jti를 추출합니다. (외부에서 들어온 토큰이므로 해석 필요)
        String memberId = jwtTokenProvider.getMemberId(refreshToken);
        String role = jwtTokenProvider.getRole(refreshToken);
        String jti = jwtTokenProvider.getJtiFromToken(refreshToken);

        // 3. Redis에 저장된 최신 jti와 비교하여 토큰 탈취 여부를 검증합니다.
        if (!redisService.validateJti(memberId, jti)) {
            // 🚨 탈취 정황 감지: 이미 사용되었거나 비정상적인 jti 요청이므로 계정의 Redis 토큰을 즉시 삭제합니다.
            redisService.deleteRefreshToken(memberId);
            throw new BadCredentialsException("토큰 탈취 위험이 감지되어 모든 세션이 만료되었습니다.");
        }

        // 4. [RTR 핵심 Step 1] 기존 Redis jti 삭제
        redisService.deleteRefreshToken(memberId);

        // 5. [RTR 핵심 Step 2] 새 Access Token 생성 및 RefreshTokenDto를 활용한 새 Refresh Token/jti 획득
        String newAccessToken = jwtTokenProvider.generateAccessToken(memberId, role);

        // 💡 재파싱 없이 DTO에서 바로 토큰과 jti를 추출합니다.
        RefreshTokenDto refreshTokenDto = jwtTokenProvider.generateRefreshToken(memberId, role);
        String newRefreshToken = refreshTokenDto.getRefreshToken();
        String newJti = refreshTokenDto.getJti();

        // 6. [RTR 핵심 Step 3] DTO에서 가져온 newJti를 Redis에 즉시 저장 (TTL 설정)
        redisService.saveRefreshToken(memberId, newJti, jwtTokenProvider.getRefreshTokenExpiration());

        // 7. 새 Refresh Token을 HttpOnly 및 SameSite=Lax 속성의 쿠키로 설정하여 Response Header에 추가
        ResponseCookie refreshTokenCookie = ResponseCookie.from("refreshToken", newRefreshToken)
                .httpOnly(true)
                .secure(false) // HTTPS 환경 적용 시 true로 변경
                .path("/")
                .maxAge(jwtTokenProvider.getRefreshTokenExpiration() / 1000)
                .sameSite("Lax")
                .build();

        response.addHeader(org.springframework.http.HttpHeaders.SET_COOKIE, refreshTokenCookie.toString());

        // 7-2. 새 Access Token도 Cookie로 설정하여 추가
        ResponseCookie accessTokenCookie = ResponseCookie.from("accessToken", newAccessToken)
                .httpOnly(true)
                .secure(false)
                .path("/")
                .maxAge(jwtTokenProvider.getAccessTokenExpiration() / 1000)
                .sameSite("Lax")
                .build();

        response.addHeader(org.springframework.http.HttpHeaders.SET_COOKIE, accessTokenCookie.toString());

        // 8. 새 Access Token 반환
        return newAccessToken;
    }

    /* ================= 아이디 / 비밀번호 찾기 ================= */

    public void sendCodeForFindId(String name, String email) {
        String memberId = memberRepository.findMemberIdByNameAndEmail(name, email);
        if (memberId == null) {
            throw new IllegalArgumentException("일치하는 회원 정보가 없습니다.");
        }
        emailVerificationService.sendVerificationCode(email);
    }

    public void sendCodeForFindPw(String memberId, String email) {
        MemberDto member = memberRepository.findByMemberId(memberId);
        if (member == null || !email.equals(member.getMemberEmail())) {
            throw new IllegalArgumentException("일치하는 회원 정보가 없습니다.");
        }
        emailVerificationService.sendVerificationCode(email);
    }

    @Transactional
    public String findMemberId(String memberName, String memberEmail) {
        validateEmailVerification(memberEmail);

        String foundMemberId = memberRepository.findMemberIdByNameAndEmail(memberName, memberEmail);
        if (foundMemberId == null) {
            throw new IllegalArgumentException("일치하는 회원 정보가 없습니다.");
        }

        emailVerificationService.removeVerification(memberEmail);
        return foundMemberId;
    }

    @Transactional
    public void resetPassword(String memberId, String memberEmail, String newPassword) {
        validateEmailVerification(memberEmail);

        String encodedPassword = passwordEncoder.encode(newPassword);
        memberRepository.updatePassword(memberId, encodedPassword);

        emailVerificationService.removeVerification(memberEmail);
    }

    private void validateEmailVerification(String email) {
        if (!emailVerificationService.isVerified(email)) {
            throw new IllegalStateException("이메일 인증이 완료되지 않았습니다.");
        }
    }
}
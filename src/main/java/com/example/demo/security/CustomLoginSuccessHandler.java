package com.example.demo.security;

import com.example.demo.dto.RefreshTokenDto;
import com.example.demo.service.MemberService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpHeaders;
import org.springframework.http.ResponseCookie;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.web.authentication.AuthenticationSuccessHandler;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.util.Objects;

@Slf4j
@Component
@RequiredArgsConstructor
public class CustomLoginSuccessHandler implements AuthenticationSuccessHandler {

    private final MemberService memberService;
    private final JwtTokenProvider jwtTokenProvider;
    private final RefreshTokenRedisService redisService;

    @Override
    public void onAuthenticationSuccess(
            HttpServletRequest request,
            HttpServletResponse response,
            Authentication authentication) throws IOException {

        CustomUserDetails user = (CustomUserDetails) Objects.requireNonNull(authentication.getPrincipal());
        String memberId = user.getUsername();
        String role = user.getAuthorities().stream()
                .findFirst()
                .map(GrantedAuthority::getAuthority)
                .orElse("ROLE_USER");

        // 1. 마지막 로그인 시간 갱신
        memberService.updateLastLoginAt(memberId);

        // 2. Access Token 생성
        String accessToken = jwtTokenProvider.generateAccessToken(memberId, role);

        // 3. 자동 로그인 체크 시 Refresh Token 발급 & Redis jti 저장 & 쿠키 전달
        Boolean rememberMe = (Boolean) request.getAttribute("rememberMe");

        if (Boolean.TRUE.equals(rememberMe)) {
            RefreshTokenDto refreshTokenDto = jwtTokenProvider.generateRefreshToken(memberId, role);
            String refreshToken = refreshTokenDto.getRefreshToken();
            String jti = refreshTokenDto.getJti();

            // 1. Redis 저장
            redisService.saveRefreshToken(memberId, jti, jwtTokenProvider.getRefreshTokenExpiration());

            // 2. ResponseCookie로 변경 (로컬 HTTP 환경 대응 및 SameSite 설정)
            ResponseCookie cookie = ResponseCookie.from("refreshToken", refreshToken)
                    .httpOnly(true)
                    .secure(false) // 🎯 로컬(http://localhost) 환경이므로 false 지정
                    .path("/")
                    .maxAge(jwtTokenProvider.getRefreshTokenExpiration() / 1000)
                    .sameSite("Lax") // 🎯 페이지 이동 시 쿠키가 유지되도록 설정
                    .build();

            response.addHeader(HttpHeaders.SET_COOKIE, cookie.toString());
        }
        // 4. 프론트엔드에 accessToken 반환
        response.setStatus(HttpServletResponse.SC_OK);
        response.setContentType("application/json;charset=UTF-8");
        response.getWriter().write("{\"success\": true, \"message\": \"로그인 성공\"}");
    }
}
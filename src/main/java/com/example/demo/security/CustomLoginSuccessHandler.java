package com.example.demo.security;

import com.example.demo.dto.RefreshTokenDto;
import com.example.demo.service.MemberService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

import com.example.demo.service.AuthCookieService;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.web.authentication.AuthenticationSuccessHandler;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.util.Objects;
import java.util.UUID;

@Slf4j
@Component
@RequiredArgsConstructor
public class CustomLoginSuccessHandler implements AuthenticationSuccessHandler {

    private final MemberService memberService;
    private final JwtTokenProvider jwtTokenProvider;
    private final LoginSessionRepository loginSessionRepository;
    private final AuthCookieService authCookieService;

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
        String sessionId = UUID.randomUUID().toString();
        String accessToken = jwtTokenProvider.generateAccessToken(memberId, role, sessionId);

        // 3. 자동 로그인 체크 시 Refresh Token 발급 & Redis jti 저장 & 쿠키 전달
        Boolean rememberMe = (Boolean) request.getAttribute("rememberMe");
        RefreshTokenDto refreshTokenDto = Boolean.TRUE.equals(rememberMe)
                ? jwtTokenProvider.generateRefreshToken(memberId, role, sessionId) : null;
        loginSessionRepository.replaceCurrentSession(memberId, sessionId,
                refreshTokenDto == null ? null : refreshTokenDto.getJti(),
                Boolean.TRUE.equals(rememberMe) ? jwtTokenProvider.getRefreshTokenExpiration()
                        : jwtTokenProvider.getAccessTokenExpiration());
        authCookieService.setAccessToken(response, accessToken, Boolean.TRUE.equals(rememberMe));
        if (Boolean.TRUE.equals(rememberMe)) {
            authCookieService.setRefreshToken(response, refreshTokenDto.getRefreshToken());
        } else {
            authCookieService.clearRefreshToken(response);
        }
        // 4. 프론트엔드에 accessToken 반환
        response.setStatus(HttpServletResponse.SC_OK);
        response.setContentType("application/json;charset=UTF-8");
        response.getWriter().write("{\"success\": true, \"message\": \"로그인 성공\"}");
    }
}

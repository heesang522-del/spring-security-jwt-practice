package com.example.demo.security;

import com.example.demo.service.MemberService;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.web.authentication.AuthenticationSuccessHandler;
import org.springframework.stereotype.Component;

import java.io.IOException;

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
            Authentication authentication)
            throws IOException, ServletException {

        CustomUserDetails user = (CustomUserDetails) authentication.getPrincipal();
        String memberId = user.getUsername();
        String role = user.getAuthorities().stream()
                .findFirst()
                .map(GrantedAuthority::getAuthority)
                .orElse("ROLE_USER");

        // 1. 마지막 로그인 시간 갱신
        memberService.updateLastLoginAt(memberId);

        // 2. Access Token 생성 및 Response Header 세팅
        String accessToken = jwtTokenProvider.generateAccessToken(memberId, role);
        response.setHeader("Authorization", "Bearer " + accessToken);

        // 3. 자동로그인 체크박스 확인 (수정 부분)
        Boolean rememberMe = (Boolean) request.getAttribute("rememberMe");

        if (Boolean.TRUE.equals(rememberMe)) {
            // 1) Refresh Token 생성
            String refreshToken = jwtTokenProvider.generateRefreshToken(memberId, role);
            // 2) Redis 메모리에 저장
            redisService.saveRefreshToken(memberId, refreshToken, jwtTokenProvider.getRefreshTokenExpiration());
            // 3) HttpOnly 쿠키 생성 후 응답(response)에 추가
            Cookie cookie = new Cookie("refreshToken", refreshToken);
            cookie.setHttpOnly(true);
            cookie.setPath("/");
            cookie.setMaxAge((int) (jwtTokenProvider.getRefreshTokenExpiration() / 1000));
            response.addCookie(cookie);
        }

        // 4. JSON 성공 응답 전송 (세션 사용 X)
        response.setStatus(HttpServletResponse.SC_OK);
        response.setContentType("application/json;charset=UTF-8");
        response.getWriter().write("{\"success\": true, \"message\": \"로그인 성공\"}");
    }
}
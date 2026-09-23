package com.example.demo.security;

import com.example.demo.dto.MemberDto;
import com.example.demo.service.AuthService;
import com.example.demo.service.MemberService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContext;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Slf4j
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtTokenProvider jwtTokenProvider;
    private final MemberService memberService;
    private final AuthService authService;

    // 💡 [추가] 정적 파일(.css, .js, .png 등) 및 파비콘 요청은 JWT 필터 검사를 생략함
    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) throws ServletException {
        String path = request.getRequestURI();
        return path.endsWith(".css") ||
                path.endsWith(".js") ||
                path.endsWith(".png") ||
                path.endsWith(".jpg") ||
                path.endsWith(".ico") ||
                path.startsWith("/css/") ||
                path.startsWith("/js/") ||
                path.startsWith("/images/");
    }

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain)
            throws ServletException, IOException {

        String accessToken = resolveAccessToken(request);
        String refreshToken = resolveCookieToken(request, "refreshToken");

        // 1. Access Token이 유효한 경우 -> 정상 인증
        if (accessToken != null && jwtTokenProvider.validateToken(accessToken)) {
            String memberId = jwtTokenProvider.getMemberId(accessToken);
            setAuthenticationToContext(memberId);
        }
        // 2. Access Token은 만료/없지만 Refresh Token 쿠키가 있는 경우 -> 자동 로그인(reissue)
        else if (refreshToken != null) {
            try {
                String newAccessToken = authService.reissue(refreshToken, response);

                String memberId = jwtTokenProvider.getMemberId(newAccessToken);
                setAuthenticationToContext(memberId);
            } catch (Exception e) {
                log.warn("Refresh Token 재발급 실패 (만료 또는 탈취 감지): {}", e.getMessage());
                SecurityContextHolder.clearContext();
            }
        }

        filterChain.doFilter(request, response);
    }

    private String resolveAccessToken(HttpServletRequest request) {
        String bearerToken = request.getHeader("Authorization");
        if (StringUtils.hasText(bearerToken) && bearerToken.startsWith("Bearer ")) {
            return bearerToken.substring(7);
        }
        return resolveCookieToken(request, "accessToken");
    }

    private String resolveCookieToken(HttpServletRequest request, String cookieName) {
        Cookie[] cookies = request.getCookies();
        if (cookies != null) {
            for (Cookie cookie : cookies) {
                if (cookieName.equals(cookie.getName())) {
                    return cookie.getValue();
                }
            }
        }
        return null;
    }

    private void setAuthenticationToContext(String memberId) {
        MemberDto memberDto = memberService.getMemberById(memberId);
        if (memberDto != null) {
            CustomUserDetails userDetails = new CustomUserDetails(memberDto);
            UsernamePasswordAuthenticationToken authentication =
                    new UsernamePasswordAuthenticationToken(
                            userDetails,
                            null,
                            userDetails.getAuthorities());

            SecurityContext context = SecurityContextHolder.createEmptyContext();
            context.setAuthentication(authentication);
            SecurityContextHolder.setContext(context);
        }
    }
}
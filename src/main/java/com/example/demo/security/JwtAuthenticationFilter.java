package com.example.demo.security;

import com.example.demo.dto.MemberDto;
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
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Slf4j
@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtTokenProvider jwtTokenProvider;
    private final MemberService memberService;

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain)
            throws ServletException, IOException {

        // 💡 [Step 1] Header 또는 Cookie에서 Access Token 추출
        String accessToken = resolveToken(request);

        // 💡 [Step 2] Access Token 유효성 검증 및 SecurityContext 등록
        if (accessToken != null && jwtTokenProvider.validateToken(accessToken)) {
            String memberId = jwtTokenProvider.getMemberId(accessToken);
            setAuthenticationToContext(memberId);
        }

        // 💡 [Step 3] 다음 필터로 요청 전달
        filterChain.doFilter(request, response);
    }

    // 💡 [토큰 추출 메서드] Header 우선 확인 후, 없으면 Cookie에서 accessToken 추출
    private String resolveToken(HttpServletRequest request) {
        // 1. Authorization 헤더 확인 (API / Postman 요청 등)
        String bearerToken = request.getHeader("Authorization");
        if (StringUtils.hasText(bearerToken) && bearerToken.startsWith("Bearer ")) {
            return bearerToken.substring(7);
        }

        // 2. 헤더에 없으면 쿠키 확인 (일반 HTML 페이지 이동 / SSR)
        Cookie[] cookies = request.getCookies();
        if (cookies != null) {
            for (Cookie cookie : cookies) {
                if ("accessToken".equals(cookie.getName())) {
                    return cookie.getValue();
                }
            }
        }

        return null;
    }

    // 💡 [SecurityContext 등록 헬퍼 메서드]
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
package com.example.demo.security;

import com.example.demo.dto.MemberDto;
import com.example.demo.service.MemberService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AnonymousAuthenticationToken;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContext;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtTokenProvider jwtTokenProvider;
    private final RefreshTokenRedisService redisService;
    private final MemberService memberService;

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain)
            throws ServletException, IOException {

        Authentication existingAuth = SecurityContextHolder.getContext().getAuthentication();

        if (existingAuth != null
                && existingAuth.isAuthenticated()
                && !(existingAuth instanceof AnonymousAuthenticationToken)) {
            filterChain.doFilter(request, response);
            return;
        }

        // 1. Authorization 헤더에서 Access Token 추출
        String bearerToken = request.getHeader("Authorization");
        String accessToken = null;

        if (StringUtils.hasText(bearerToken) && bearerToken.startsWith("Bearer ")) {
            accessToken = bearerToken.substring(7);
        }

        // 2. Access Token 검증 진행
        if (accessToken != null && jwtTokenProvider.validateToken(accessToken)) {
            // Case A: Access Token이 유효한 경우 -> 바로 인증 처리
            setAuthenticationToContext(jwtTokenProvider.getMemberId(accessToken));
        } else {
            // Case B: Access Token이 없거나 만료된 경우 -> Refresh Token 검증 및 자동 재발급
            reissueAccessTokenIfRefreshTokenValid(request, response);
        }

        filterChain.doFilter(request, response);
    }

    // Refresh Token 검증 및 Access Token 재발급 메서드
    private void reissueAccessTokenIfRefreshTokenValid(HttpServletRequest request, HttpServletResponse response) {
        Cookie[] cookies = request.getCookies();
        if (cookies == null) return;

        for (Cookie cookie : cookies) {
            if ("refreshToken".equals(cookie.getName())) {
                String refreshToken = cookie.getValue();

                // 1) Refresh Token 자체 유효성 검증
                if (jwtTokenProvider.validateToken(refreshToken)) {
                    String memberId = jwtTokenProvider.getMemberId(refreshToken);

                    // 🎯 2) 쿠키의 토큰에서 jti를 추출하여 Redis 값과 비교
                    String jtiFromToken = jwtTokenProvider.getJtiFromToken(refreshToken);
                    String savedJti = redisService.getRefreshToken(memberId);

                    if (savedJti != null && savedJti.equals(jtiFromToken)) {
                        MemberDto memberDto = memberService.getMemberById(memberId);

                        if (memberDto != null) {
                            // 3) 새로운 Access Token 생성
                            String newAccessToken = jwtTokenProvider.generateAccessToken(
                                    memberDto.getMemberId(),
                                    memberDto.getMemberRole()
                            );

                            // 4) Response Header 전달
                            response.setHeader("Authorization", "Bearer " + newAccessToken);

                            // 5) SecurityContext 인증 등록
                            setAuthenticationToContext(memberId);
                        }
                    } else {
                        clearInvalidCookie(response); // 탈취/불일치 jti 쿠키 삭제[cite: 6]
                    }
                } else {
                    clearInvalidCookie(response); // 만료된 쿠키 삭제[cite: 6]
                }
                break;
            }
        }
    }

    // SecurityContext 등록 헬퍼 메서드
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

    // 쿠키 삭제 헬퍼 메서드[cite: 4]
    private void clearInvalidCookie(HttpServletResponse response) {
        Cookie invalidCookie = new Cookie("refreshToken", null);
        invalidCookie.setMaxAge(0);
        invalidCookie.setPath("/");
        response.addCookie(invalidCookie);
    }
}
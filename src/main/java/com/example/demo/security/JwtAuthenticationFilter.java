package com.example.demo.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtTokenProvider jwtTokenProvider;

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {

        // 1. HTTP 요청에서 Authorization 헤더 가져오기
        String authorization = request.getHeader("Authorization");

        // 2. JWT가 있는지 확인
        if (authorization != null && authorization.startsWith("Bearer ")) {

            // 3. "Bearer " 뒤의 실제 JWT만 추출
            String token = authorization.substring(7);

            // 4. JWT 검증
            if (jwtTokenProvider.validateToken(token)) {

                // 5. JWT에서 memberId 추출
                String memberId = jwtTokenProvider.getMemberId(token);

                // 6. Spring Security 인증 객체 생성
                UsernamePasswordAuthenticationToken authentication =
                        new UsernamePasswordAuthenticationToken(
                                memberId,
                                null,
                                null
                        );

                // 7. SecurityContext에 인증 정보 저장
                SecurityContextHolder.getContext()
                        .setAuthentication(authentication);
            }
        }

        // 8. 다음 필터로 요청 전달
        filterChain.doFilter(request, response);
    }
}
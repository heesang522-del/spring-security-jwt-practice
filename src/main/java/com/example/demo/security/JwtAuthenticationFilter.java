package com.example.demo.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils; // 💡 추가: Spring Core 내장 유틸
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;

@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtTokenProvider jwtTokenProvider;

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {

        // 1. Authorization 헤더 가져오기
        String authorization = request.getHeader("Authorization");

        // 2. StringUtils.hasText()로 null, 빈 문자열(""), 공백문자(" ")를 한 번에 검사
        if (StringUtils.hasText(authorization) && authorization.startsWith("Bearer ")) {

            // 3. "Bearer " 제거 후 순수 토큰만 추출
            String token = authorization.substring(7);

            // 4. JWT 유효성 검증
            if (jwtTokenProvider.validateToken(token)) {

                // 5. 토큰에서 memberId 및 role 추출 (JwtTokenProvider에 getRole()이 구현되어 있다고 가정)
                String memberId = jwtTokenProvider.getMemberId(token);
                String role = jwtTokenProvider.getRole(token); // 예: "USER", "ADMIN"

                // 6. DB 권한명을 Spring Security 규격("ROLE_USER")으로 변환하여 GrantedAuthority 생성
                List<GrantedAuthority> authorities =
                        List.of(new SimpleGrantedAuthority("ROLE_" + role));

                // 7. Security 인증 객체 생성 (credentials는 null, authorities는 권한 리스트)
                UsernamePasswordAuthenticationToken authentication =
                        new UsernamePasswordAuthenticationToken(
                                memberId,
                                null,
                                authorities
                        );

                // 💡 8. 요청 세부 정보(사용자 IP, 세션 ID 등)를 authentication 객체에 추가
                authentication.setDetails(
                        new WebAuthenticationDetailsSource().buildDetails(request)
                );

                // 9. SecurityContext에 최종 인증 객체 저장
                SecurityContextHolder.getContext().setAuthentication(authentication);
            }
        }

        // 10. 다음 필터로 진행
        filterChain.doFilter(request, response);
    }
}
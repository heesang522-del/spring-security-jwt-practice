package com.example.demo.security;

import com.example.demo.dto.MemberDto;
import com.example.demo.service.MemberService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
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
public class jwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtTokenProvider jwtTokenProvider;
    private final MemberService memberService;

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain)
            throws ServletException, IOException {

        Authentication existingAuth = SecurityContextHolder.getContext().getAuthentication();

        // 이미 인증된 요청인 경우 필터 통과[cite: 4]
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

        // 2. Access Token 검증 및 SecurityContext 등록
        if (accessToken != null && jwtTokenProvider.validateToken(accessToken)) {
            String memberId = jwtTokenProvider.getMemberId(accessToken);
            MemberDto memberDto = memberService.getMemberById(memberId);

            if (memberDto != null) {
                CustomUserDetails userDetails = new CustomUserDetails(memberDto);

                UsernamePasswordAuthenticationToken authentication =
                        new UsernamePasswordAuthenticationToken(
                                userDetails,
                                null,
                                userDetails.getAuthorities());

                // 💡 메모리 상의 SecurityContext에만 저장 (세션 생성 X)[cite: 4]
                SecurityContext context = SecurityContextHolder.createEmptyContext();
                context.setAuthentication(authentication);
                SecurityContextHolder.setContext(context);
            }
        }

        filterChain.doFilter(request, response);
    }
}
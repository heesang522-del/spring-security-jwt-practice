package com.example.demo.security;

import com.example.demo.dto.MemberDto;
import com.example.demo.service.MemberService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AnonymousAuthenticationToken;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContext;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.context.HttpSessionSecurityContextRepository;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Component
@RequiredArgsConstructor
public class AutoLoginFilter extends OncePerRequestFilter {

    private final JwtTokenProvider jwtTokenProvider;
    private final RefreshTokenRedisService redisService;
    private final MemberService memberService;

    // 세션에 SecurityContext를 바인딩해주는 객체
    private final HttpSessionSecurityContextRepository securityContextRepository =
            new HttpSessionSecurityContextRepository();

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain)
            throws ServletException, IOException {

        Authentication authentication =
                SecurityContextHolder.getContext().getAuthentication();

        // 이미 인증된 사용자는 그대로 필터 통과
        if (authentication != null
                && authentication.isAuthenticated()
                && !(authentication instanceof AnonymousAuthenticationToken)) {
            filterChain.doFilter(request, response);
            return;
        }

        Cookie[] cookies = request.getCookies();

        if (cookies != null) {
            for (Cookie cookie : cookies) {
                // 1. refreshToken 쿠키 탐색
                if ("refreshToken".equals(cookie.getName())) {

                    String token = cookie.getValue();

                    // 2. JWT 서명 및 유효기간 검증
                    if (jwtTokenProvider.validateToken(token)) {
                        String memberId = jwtTokenProvider.getMemberId(token);

                        // 3. Redis에 저장된 토큰과 일치하는지 비교 (탈취/중복 로그인 검증)
                        String savedToken = redisService.getRefreshToken(memberId);

                        if (savedToken != null && savedToken.equals(token)) {
                            MemberDto memberDto = memberService.getMemberById(memberId);

                            if (memberDto != null) {
                                CustomUserDetails userDetails = new CustomUserDetails(memberDto);

                                UsernamePasswordAuthenticationToken auth =
                                        new UsernamePasswordAuthenticationToken(
                                                userDetails,
                                                null,
                                                userDetails.getAuthorities());

                                // Context 생성 및 저장
                                SecurityContext context = SecurityContextHolder.createEmptyContext();
                                context.setAuthentication(auth);
                                SecurityContextHolder.setContext(context);

                                // 세션 가져오기 및 Context 저장
                                HttpSession session = request.getSession(true);
                                securityContextRepository.saveContext(context, request, response);

                                // 세션에 닉네임 및 프로필 저장
                                session.setAttribute("nickname", memberDto.getNickname());
                                session.setAttribute("profile", memberDto.getProfileImage());
                            }
                        } else {
                            // Redis에 값이 없거나 다른 경우 만료 처리
                            clearInvalidCookie(response);
                        }
                    } else {
                        // JWT 검증 실패 시 만료 처리
                        clearInvalidCookie(response);
                    }
                    break;
                }
            }
        }

        filterChain.doFilter(request, response);
    }

    // 만료되었거나 유효하지 않은 쿠키 삭제 전용 메서드
    private void clearInvalidCookie(HttpServletResponse response) {
        Cookie invalidCookie = new Cookie("refreshToken", null);
        invalidCookie.setMaxAge(0);
        invalidCookie.setPath("/");
        response.addCookie(invalidCookie);
    }
}
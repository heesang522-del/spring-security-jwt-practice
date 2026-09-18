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
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtTokenProvider jwtTokenProvider;
    private final MemberService memberService;

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain)
            throws ServletException, IOException {

        // 💡 [기존 인증 검증] 이미 현재 쓰레드의 SecurityContext에 유효한 인증 객체가 있다면
        // 불필요한 토큰 검증 로직을 건너뛰고 다음 필터로 바로 진행합니다.
        Authentication existingAuth = SecurityContextHolder.getContext().getAuthentication();

        if (existingAuth != null
                && existingAuth.isAuthenticated()
                && !(existingAuth instanceof AnonymousAuthenticationToken)) {
            filterChain.doFilter(request, response);
            return;
        }

        // 💡 [Step 1] HTTP 요청 헤더에서 'Authorization' 값을 읽어와 Access Token만 추출합니다.
        String bearerToken = request.getHeader("Authorization");
        String accessToken = null;

        if (StringUtils.hasText(bearerToken) && bearerToken.startsWith("Bearer ")) {
            accessToken = bearerToken.substring(7); // "Bearer " 접두사(7자) 제거
        }

        // 💡 [Step 2] Access Token의 서명 및 만료 여부를 검증합니다.
        // 토큰이 유효하다면 Payload에서 memberId를 추출하여 SecurityContext에 인증 정보를 등록합니다.
        if (accessToken != null && jwtTokenProvider.validateToken(accessToken)) {
            String memberId = jwtTokenProvider.getMemberId(accessToken);
            setAuthenticationToContext(memberId);
        }

        // 💡 [Step 3] 다음 필터로 요청을 전달합니다.
        // Access Token이 없거나 만료되었더라도 여기서 예외를 던지지 않고 다음 필터로 진행합니다.
        // 인증이 필요한 API일 경우 Security가 401 Unauthorized 응답을 내보내며,
        // 클라이언트는 401을 받아 /api/auth/reissue 엔드포인트로 토큰 재발급 요청을 보냅니다.
        filterChain.doFilter(request, response);
    }

    // 💡 [SecurityContext 등록 헬퍼 메서드]
    // DB에서 회원 정보를 조회하여 Spring Security가 인식할 수 있는 Authentication 객체로 변환 후 저장합니다.
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
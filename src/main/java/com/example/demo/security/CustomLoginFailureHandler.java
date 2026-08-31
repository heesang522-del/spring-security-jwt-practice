package com.example.demo.security;

import com.example.demo.dto.MemberDto;
import com.example.demo.service.MemberService;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.authentication.AuthenticationFailureHandler;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

@Component
@RequiredArgsConstructor
public class CustomLoginFailureHandler implements AuthenticationFailureHandler {

    private final MemberService memberService;

    @Override
    public void onAuthenticationFailure(HttpServletRequest request,
                                        HttpServletResponse response,
                                        AuthenticationException exception) throws IOException, ServletException {

        String memberId = request.getParameter("memberId");
        String message = exception.getMessage();

        // 1. DORMANT (휴면 계정) -> 이메일 인증 페이지로 이동
        if ("DORMANT".equals(message)) {
            MemberDto member = memberService.getMemberById(memberId);
            if (member != null) {
                HttpSession session = request.getSession();
                session.setAttribute("unlockMemberId", member.getMemberId());
                session.setAttribute("unlockMemberEmail", member.getMemberEmail());

                response.sendRedirect("/auth/unlock-dormant");
                return;
            }
        }

        // 2. DELETED (탈퇴 대기 계정) -> 탈퇴 취소 이메일 인증 페이지로 이동
        if ("DELETED".equals(message)) {
            MemberDto member = memberService.getMemberById(memberId);
            if (member != null) {
                HttpSession session = request.getSession();
                session.setAttribute("restoreMemberId", member.getMemberId());
                session.setAttribute("restoreMemberEmail", member.getMemberEmail());

                response.sendRedirect("/auth/restore-account");
                return;
            }
        }

        if ("LOCKED".equals(message)) {
            MemberDto member = memberService.getMemberById(memberId);
            if (member != null) {
                HttpSession session = request.getSession();
                session.setAttribute("unlockMemberId", member.getMemberId());
                session.setAttribute("unlockMemberEmail", member.getMemberEmail());
            }

            String errorMsg = URLEncoder.encode("보안을 위해 계정이 잠겼습니다. 이메일로 발송된 해제 링크를 확인해 주세요.", StandardCharsets.UTF_8);
            response.sendRedirect("/auth/login?error=true&exception=" + errorMsg);
            return;
        }

        // 3. BANNED (이용 정지 계정)
        if ("BANNED".equals(message)) {
            String errorMsg = URLEncoder.encode("운영 정책 위반으로 이용이 정지된 계정입니다.", StandardCharsets.UTF_8);
            response.sendRedirect("/auth/login?error=true&exception=" + errorMsg);
            return;
        }

        // 4. 일반 로그인 실패 및 일시 차단 영역 (주석 부분 대체)
        String errorMsg = URLEncoder.encode(message, StandardCharsets.UTF_8);
        response.sendRedirect("/auth/login?error=true&exception=" + errorMsg);

    }
}
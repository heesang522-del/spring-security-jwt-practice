package com.example.demo.security;

import com.example.demo.service.AuthService;
import com.example.demo.service.MemberService;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.web.authentication.SavedRequestAwareAuthenticationSuccessHandler;
import org.springframework.stereotype.Component;

import java.io.IOException;

@Component
@RequiredArgsConstructor
public class CustomLoginSuccessHandler
        extends SavedRequestAwareAuthenticationSuccessHandler {

    private final MemberService memberService;
    private final AuthService authService;

    @Override
    public void onAuthenticationSuccess(
            HttpServletRequest request,
            HttpServletResponse response,
            Authentication authentication)
            throws IOException, ServletException {

        CustomUserDetails user =
                (CustomUserDetails) authentication.getPrincipal();

        String memberId = user.getUsername();

        // 2. 마지막 로그인 시간 갱신
        memberService.updateLastLoginAt(memberId);

        // 3. 자동로그인 체크박스 확인 ("on" 또는 "true")
        String rememberMe = request.getParameter("remember-me");
        if ("on".equals(rememberMe) || "true".equals(rememberMe)) {
            authService.setupAutoLogin(memberId, response);
        }

        // 4. 기본 이동할 URL 설정
        setDefaultTargetUrl("/");

        // 5. 유저 기본 정보
        HttpSession session = request.getSession();
        session.setAttribute("nickname", user.getMemberDto().getNickname());
        session.setAttribute("profile", user.getMemberDto().getProfileImage());

        super.onAuthenticationSuccess(request, response, authentication);
    }
}
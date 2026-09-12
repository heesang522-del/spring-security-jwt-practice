package com.example.demo.service;

import com.example.demo.dto.AutoLoginDto;
import com.example.demo.dto.LoginResponse;
import com.example.demo.dto.MemberDto;
import com.example.demo.repository.MemberRepository;
import com.example.demo.security.CustomAuthenticationProvider;
import com.example.demo.security.CustomUserDetails;
import com.example.demo.security.JwtTokenProvider;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.util.Date;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class AuthService {

    private final MemberRepository memberRepository;
    private final PasswordEncoder passwordEncoder;
    private final EmailVerificationService emailVerificationService;
    private final CustomAuthenticationProvider customAuthenticationProvider;
    private final JwtTokenProvider jwtTokenProvider;

    @Transactional
    public LoginResponse login(String memberId, String memberPassword, boolean rememberMe) {
        if (!StringUtils.hasText(memberId) || !StringUtils.hasText(memberPassword)) {
            throw new BadCredentialsException("아이디와 비밀번호를 입력해 주세요.");
        }

        Authentication authentication = customAuthenticationProvider.authenticate(
                UsernamePasswordAuthenticationToken.unauthenticated(memberId, memberPassword)
        );
        CustomUserDetails userDetails = (CustomUserDetails) authentication.getPrincipal();
        MemberDto memberDto = userDetails.getMemberDto();
        String role = memberDto.getMemberRole();

        memberRepository.updateLastLoginAt(memberDto.getMemberId());

        return new LoginResponse(
                jwtTokenProvider.generateToken(memberDto.getMemberId(), role, rememberMe),
                "Bearer",
                memberDto.getMemberId(),
                role
        );
    }

    /* ================= 아이디 / 비밀번호 찾기 ================= */

    public void sendCodeForFindId(String name, String email) {
        String memberId = memberRepository.findMemberIdByNameAndEmail(name, email);
        if (memberId == null) {
            throw new IllegalArgumentException("일치하는 회원 정보가 없습니다.");
        }
        emailVerificationService.sendVerificationCode(email);
    }

    public void sendCodeForFindPw(String memberId, String email) {
        MemberDto member = memberRepository.findByMemberId(memberId);
        if (member == null || !email.equals(member.getMemberEmail())) {
            throw new IllegalArgumentException("일치하는 회원 정보가 없습니다.");
        }
        emailVerificationService.sendVerificationCode(email);
    }

    @Transactional
    public String findMemberId(String memberName, String memberEmail) {
        validateEmailVerification(memberEmail);

        String foundMemberId = memberRepository.findMemberIdByNameAndEmail(memberName, memberEmail);
        if (foundMemberId == null) {
            throw new IllegalArgumentException("일치하는 회원 정보가 없습니다.");
        }

        emailVerificationService.removeVerification(memberEmail);
        return foundMemberId;
    }

    @Transactional
    public void resetPassword(String memberId, String memberEmail, String newPassword) {
        validateEmailVerification(memberEmail);

        String encodedPassword = passwordEncoder.encode(newPassword);
        memberRepository.updatePassword(memberId, encodedPassword);

        emailVerificationService.removeVerification(memberEmail);
    }

    private void validateEmailVerification(String email) {
        if (!emailVerificationService.isVerified(email)) {
            throw new IllegalStateException("이메일 인증이 완료되지 않았습니다.");
        }
    }
}

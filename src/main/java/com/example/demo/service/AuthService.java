package com.example.demo.service;

import com.example.demo.dto.AutoLoginDto;
import com.example.demo.dto.MemberDto;
import com.example.demo.repository.AutoLoginRepository;
import com.example.demo.repository.MemberRepository;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Date;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class AuthService {

    private final MemberRepository memberRepository;
    private final AutoLoginRepository autoLoginRepository;
    private final PasswordEncoder passwordEncoder;
    private final EmailVerificationService emailVerificationService;

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


    /* ================= 자동 로그인 토큰 관리 ================= */

    @Transactional
    public void setupAutoLogin(String memberId, HttpServletResponse response) {
        String token = UUID.randomUUID().toString();
        int amount = 60 * 60 * 24 * 7;
        Date limitDate = new Date(System.currentTimeMillis() + ((long) amount * 1000));

        AutoLoginDto autoLoginDto = new AutoLoginDto();
        autoLoginDto.setMemberId(memberId);
        autoLoginDto.setToken(token);
        autoLoginDto.setLimitDate(limitDate);

        autoLoginRepository.upsertToken(autoLoginDto);

        Cookie cookie = new Cookie("remember-me", token);
        cookie.setPath("/");
        cookie.setMaxAge(amount);
        cookie.setHttpOnly(true);
        response.addCookie(cookie);
    }

    @Transactional
    public void removeAutoLoginToken(String token) {
        autoLoginRepository.deleteByToken(token);
    }

    private void validateEmailVerification(String email) {
        if (!emailVerificationService.isVerified(email)) {
            throw new IllegalStateException("이메일 인증이 완료되지 않았습니다.");
        }
    }
}
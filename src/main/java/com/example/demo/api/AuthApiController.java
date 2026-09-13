package com.example.demo.api;

import com.example.demo.dto.LoginRequest;
import com.example.demo.security.CustomLoginFailureHandler;
import com.example.demo.security.CustomLoginSuccessHandler;
import com.example.demo.service.EmailVerificationService;
import com.example.demo.service.MemberService;
import com.example.demo.service.MemberService.AccountRestoreType;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthApiController {

    private final AuthenticationManager authenticationManager;
    private final CustomLoginSuccessHandler customLoginSuccessHandler;
    private final CustomLoginFailureHandler customLoginFailureHandler;
    private final MemberService memberService;
    private final EmailVerificationService emailVerificationService;

    @PostMapping("/login")
    public void login(
            @RequestBody LoginRequest requestDto,
            HttpServletRequest request,
            HttpServletResponse response) throws Exception {

        try {
            // 1. CustomAuthenticationProvider를 통한 인증 시도
            Authentication authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(
                            requestDto.memberId(),
                            requestDto.memberPassword()
                    )
            );

            // 2. 인증 성공 시 커스텀 성공 핸들러 실행
            customLoginSuccessHandler.onAuthenticationSuccess(request, response, authentication);

        } catch (AuthenticationException exception) {
            // 3. 예외(휴면/잠금/정지/비밀번호 오류 등) 발생 시 커스텀 실패 핸들러 실행
            customLoginFailureHandler.onAuthenticationFailure(request, response, exception);
        }
    }

    /* ================= 계정 복구 / 휴면 해제 API ================= */

    @PostMapping("/send-recovery-code")
    public ResponseEntity<?> sendRecoveryCode(@RequestBody Map<String, String> request) {
        String email = request.get("memberEmail");
        try {
            emailVerificationService.sendVerificationCode(email);
            return ResponseEntity.ok(Map.of("success", true, "message", "인증번호가 발송되었습니다."));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("success", false, "message", "메일 발송에 실패했습니다."));
        }
    }

    @PostMapping("/unlock-dormant")
    public ResponseEntity<String> unlockDormant(@RequestBody Map<String, String> request) {
        return processAccountRestore(request, AccountRestoreType.DORMANT);
    }

    @PostMapping("/restore-account")
    public ResponseEntity<String> restoreAccount(@RequestBody Map<String, String> request) {
        return processAccountRestore(request, AccountRestoreType.DELETE);
    }

    private ResponseEntity<String> processAccountRestore(
            Map<String, String> request,
            AccountRestoreType restoreType
    ) {
        String code = request.get("code");
        String memberId = request.get("memberId");
        String memberEmail = request.get("memberEmail");

        if (memberId == null || memberEmail == null) {
            return ResponseEntity.ok("EXPIRED");
        }

        try {
            boolean isCodeValid = emailVerificationService.verifyCode(memberEmail, code);
            if (isCodeValid) {
                memberService.restoreAccountStatus(memberId, memberEmail, restoreType);
                return ResponseEntity.ok("SUCCESS");
            }
            return ResponseEntity.ok("FAIL");
        } catch (Exception e) {
            return ResponseEntity.ok("FAIL");
        }
    }
}
package com.example.demo.api;

import com.example.demo.dto.LoginRequest;
import com.example.demo.dto.LoginResponse;
import com.example.demo.service.AuthService;
import com.example.demo.service.EmailVerificationService;
import com.example.demo.service.MemberService;
import com.example.demo.service.MemberService.AccountRestoreType;
import jakarta.servlet.http.HttpSession;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
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

    private final AuthService authService; // 🎯 메인 비즈니스 로직
    private final MemberService memberService; // 계정 상태 복구용 (필요 시 유지)
    private final EmailVerificationService emailVerificationService;

    @PostMapping("/login")
    public ResponseEntity<LoginResponse> login(@RequestBody LoginRequest request) {
        LoginResponse response = authService.login(
                request.memberId(),
                request.memberPassword(),
                request.rememberMe()
        );
        return ResponseEntity.ok(response);
    }

    /* ================= 아이디 / 비밀번호 찾기 API ================= */

    @PostMapping("/find-id/send-code")
    public ResponseEntity<?> sendCodeForFindId(@RequestBody Map<String, String> request) {
        try {
            authService.sendCodeForFindId(request.get("memberName"), request.get("memberEmail"));
            return ResponseEntity.ok(Map.of("success", true, "message", "인증번호가 발송되었습니다."));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("success", false, "message", e.getMessage()));
        }
    }

    @PostMapping("/find-id")
    public ResponseEntity<?> findId(@RequestBody Map<String, String> request) {
        try {
            String memberId = authService.findMemberId(request.get("memberName"), request.get("memberEmail"));
            return ResponseEntity.ok(Map.of("success", true, "memberId", memberId));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("success", false, "message", e.getMessage()));
        }
    }

    @PostMapping("/find-pw/send-code")
    public ResponseEntity<?> sendCodeForFindPw(@RequestBody Map<String, String> request) {
        try {
            authService.sendCodeForFindPw(request.get("memberId"), request.get("memberEmail"));
            return ResponseEntity.ok(Map.of("success", true, "message", "인증번호가 발송되었습니다."));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("success", false, "message", e.getMessage()));
        }
    }

    @PostMapping("/reset-pw")
    public ResponseEntity<?> resetPassword(@RequestBody Map<String, String> request) {
        try {
            authService.resetPassword(request.get("memberId"), request.get("memberEmail"), request.get("newPassword"));
            return ResponseEntity.ok(Map.of("success", true, "message", "비밀번호가 성공적으로 변경되었습니다."));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("success", false, "message", e.getMessage()));
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
    public ResponseEntity<String> unlockDormant(@RequestBody Map<String, String> request, HttpSession session) {
        return processAccountRestore(request, session, "unlockMemberId", "unlockMemberEmail", AccountRestoreType.DORMANT);
    }

    @PostMapping("/restore-account")
    public ResponseEntity<String> restoreAccount(@RequestBody Map<String, String> request, HttpSession session) {
        return processAccountRestore(request, session, "restoreMemberId", "restoreMemberEmail", AccountRestoreType.DELETE);
    }

    private ResponseEntity<String> processAccountRestore(
            Map<String, String> request,
            HttpSession session,
            String sessionKeyId,
            String sessionKeyEmail,
            AccountRestoreType restoreType
    ) {
        String code = request.get("code");
        String memberId = (String) session.getAttribute(sessionKeyId);
        String memberEmail = (String) session.getAttribute(sessionKeyEmail);

        if (memberId == null || memberEmail == null) {
            return ResponseEntity.ok("EXPIRED");
        }

        try {
            boolean isCodeValid = emailVerificationService.verifyCode(memberEmail, code);
            if (isCodeValid) {
                memberService.restoreAccountStatus(memberId, memberEmail, restoreType);
                session.removeAttribute(sessionKeyId);
                session.removeAttribute(sessionKeyEmail);
                return ResponseEntity.ok("SUCCESS");
            }
            return ResponseEntity.ok("FAIL");
        } catch (Exception e) {
            return ResponseEntity.ok("FAIL");
        }
    }
}

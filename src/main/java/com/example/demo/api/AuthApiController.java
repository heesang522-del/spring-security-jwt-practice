package com.example.demo.api;

import com.example.demo.dto.LoginRequest;
import com.example.demo.dto.LoginResponse;
import com.example.demo.service.AuthService;
import com.example.demo.service.EmailVerificationService;
import com.example.demo.service.MemberService;
import com.example.demo.service.MemberService.AccountRestoreType;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.AuthenticationException;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthApiController {

    private final MemberService memberService;
    private final AuthService authService;
    private final EmailVerificationService emailVerificationService;

    /**
     * 💡 [REST API 로그인 엔드포인트]
     * 성공 시 Access Token 및 Cookie(Refresh Token) 반환
     * 실패 시 예외 메시지(DORMANT, LOCKED, BANNED 등)를 JSON 응답으로 전달
     */
    @PostMapping("/login")
    public ResponseEntity<?> login(
            @RequestBody LoginRequest requestDto,
            HttpServletResponse response) {
        try {
            LoginResponse loginResponse = authService.login(
                    requestDto.memberId(),
                    requestDto.memberPassword(),
                    requestDto.rememberMe(),
                    response
            );
            return ResponseEntity.ok(loginResponse);

        } catch (AuthenticationException e) {
            // 예외 메시지(DORMANT, LOCKED, BANNED 등)를 프론트엔드가 응답받아 분기 처리할 수 있도록 JSON 반환
            String errorType = e.getMessage();

            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of(
                    "success", false,
                    "error", errorType,
                    "message", getErrorMessageDetail(errorType)
            ));
        }
    }

    // 💡 [에러 메시지 매핑 헬퍼 메서드]
    private String getErrorMessageDetail(String errorType) {
        return switch (errorType) {
            case "DORMANT" -> "휴면 계정입니다. 계정 재활성화가 필요합니다.";
            case "DELETED" -> "탈퇴 대기 중인 계정입니다. 계정 복구를 진행해 주세요.";
            case "LOCKED" -> "보안을 위해 계정이 잠겼습니다. 이메일 해제 링크를 확인해 주세요.";
            case "BANNED" -> "운영 정책 위반으로 이용이 정지된 계정입니다.";
            default -> "아이디 또는 비밀번호가 일치하지 않습니다.";
        };
    }

    @PostMapping("/reissue")
    public ResponseEntity<?> reissue(
            @CookieValue(name = "refreshToken", required = false) String refreshToken,
            HttpServletResponse response) {

        if (!StringUtils.hasText(refreshToken)) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("message", "Refresh Token이 존재하지 않습니다."));
        }

        // AuthService의 RTR 재발급 로직 호출
        String newAccessToken = authService.reissue(refreshToken, response);

        return ResponseEntity.ok(Map.of(
                "accessToken", newAccessToken,
                "tokenType", "Bearer"
        ));
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
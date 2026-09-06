package com.example.demo.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.UnsupportedJwtException;
import io.jsonwebtoken.security.Keys;
import io.jsonwebtoken.security.SignatureException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import lombok.extern.slf4j.Slf4j;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;

@Slf4j
@Component
public class JwtTokenProvider {

    private final SecretKey secretKey;
    private final long accessTokenExpiration;
    private final long autoLoginTokenExpiration;

    public JwtTokenProvider(
            @Value("${jwt.secret}") String secret,
            @Value("${jwt.access-token-expiration}") long accessTokenExpiration,
            @Value("${jwt.auto-login-token-expiration}") long autoLoginTokenExpiration
    ) {
        this.secretKey = Keys.hmacShaKeyFor(
                secret.getBytes(StandardCharsets.UTF_8)
        );
        this.accessTokenExpiration = accessTokenExpiration;
        this.autoLoginTokenExpiration = autoLoginTokenExpiration;
    }

    // JWT 생성 (role claim과 자동 로그인 만료 시간을 반영)
    public String generateToken(String memberId, String role, boolean rememberMe) {

        Date now = new Date();
        Date expiration = new Date(
                now.getTime() + (rememberMe ? autoLoginTokenExpiration : accessTokenExpiration)
        );

        return Jwts.builder()
                .subject(memberId)
                .claim("role", role) // Custom Claim으로 권한 정보 저장 (예: "USER", "ADMIN")
                .issuedAt(now)
                .expiration(expiration)
                .signWith(secretKey)
                .compact();
    }

    // JWT 검증
    public boolean validateToken(String token) {
        try {
            Jwts.parser()
                    .verifyWith(secretKey)
                    .build()
                    .parseSignedClaims(token);
            return true;
        } catch (SecurityException | SignatureException e) {
            log.error("잘못된 JWT 서명입니다.", e);
        } catch (ExpiredJwtException e) {
            log.error("만료된 JWT 토큰입니다.", e);
        } catch (UnsupportedJwtException e) {
            log.error("지원되지 않는 JWT 토큰입니다.", e);
        } catch (IllegalArgumentException e) {
            log.error("JWT 토큰이 비어있거나 잘못되었습니다.", e);
        }
        return false;
    }

    // JWT에서 memberId 추출
    public String getMemberId(String token) {
        return getClaims(token).getSubject();
    }

    // 💡 2. JWT에서 role 추출하는 메서드 추가
    public String getRole(String token) {
        return getClaims(token).get("role", String.class);
    }

    // 💡 3. Claims 추출 중복 코드를 공통 메서드로 분리 (가독성 개선)
    private Claims getClaims(String token) {
        return Jwts.parser()
                .verifyWith(secretKey)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }
}

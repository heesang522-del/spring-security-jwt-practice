package com.example.demo.security;

import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;

@Service
@RequiredArgsConstructor
public class RefreshTokenRedisService {

    private final StringRedisTemplate redisTemplate;
    private static final String PREFIX = "RT:";

    // 1. Redis에 Refresh Token의 jti 저장 (TTL 설정)
    public void saveRefreshToken(String memberId, String jti, long timeoutMillis) {
        redisTemplate.opsForValue().set(
                PREFIX + memberId,
                jti,
                Duration.ofMillis(timeoutMillis)
        );
    }

    // 2. Redis에서 저장된 jti 조회
    public String getRefreshToken(String memberId) {
        return redisTemplate.opsForValue().get(PREFIX + memberId);
    }

    // 3. jti 일치 여부 검증 (RTR 및 탈취 감지용)
    public boolean validateJti(String memberId, String jti) {
        String savedJti = getRefreshToken(memberId);
        return savedJti != null && savedJti.equals(jti);
    }

    // 4. Redis에서 토큰 정보 삭제 (로그아웃 / 탈취 감지 시 강제 만료)
    public void deleteRefreshToken(String memberId) {
        redisTemplate.delete(PREFIX + memberId);
    }
}
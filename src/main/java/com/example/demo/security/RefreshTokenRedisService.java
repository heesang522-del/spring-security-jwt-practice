package com.example.demo.security;

import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.util.concurrent.TimeUnit;

@Service
@RequiredArgsConstructor
public class RefreshTokenRedisService {

    private final StringRedisTemplate redisTemplate;
    private static final String PREFIX = "RT:";

    // Redis에 Refresh Token 저장 (TTL 설정)
    public void saveRefreshToken(String memberId, String refreshToken, long timeoutMillis) {
        redisTemplate.opsForValue().set(
                PREFIX + memberId,
                refreshToken,
                timeoutMillis,
                TimeUnit.MILLISECONDS
        );
    }

    // Redis에서 Refresh Token 조회
    public String getRefreshToken(String memberId) {
        return redisTemplate.opsForValue().get(PREFIX + memberId);
    }

    // Redis에서 Refresh Token 삭제 (로그아웃 시)
    public void deleteRefreshToken(String memberId) {
        redisTemplate.delete(PREFIX + memberId);
    }
}
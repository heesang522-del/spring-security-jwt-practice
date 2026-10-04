package com.example.demo.security;

import lombok.RequiredArgsConstructor;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.script.DefaultRedisScript;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
@RequiredArgsConstructor
public class RefreshTokenRedisService {
    private final StringRedisTemplate redisTemplate;
    private static final String PREFIX = "LOGIN:";
    private static final DefaultRedisScript<Long> LOGIN_SCRIPT = new DefaultRedisScript<>("""
            redis.call('DEL', KEYS[1])
            redis.call('HSET', KEYS[1], 'sid', ARGV[1], 'jti', ARGV[2])
            redis.call('PEXPIRE', KEYS[1], ARGV[3])
            return 1
            """, Long.class);
    private static final DefaultRedisScript<Long> ROTATE_SCRIPT = new DefaultRedisScript<>("""
            local sid = redis.call('HGET', KEYS[1], 'sid')
            if not sid or sid ~= ARGV[1] then return -1 end
            local jti = redis.call('HGET', KEYS[1], 'jti')
            if not jti or jti == '' or jti ~= ARGV[2] then
                redis.call('DEL', KEYS[1])
                return 0
            end
            redis.call('HSET', KEYS[1], 'jti', ARGV[3])
            redis.call('PEXPIRE', KEYS[1], ARGV[4])
            return 1
            """, Long.class);
    private static final DefaultRedisScript<Long> LOGOUT_SCRIPT = new DefaultRedisScript<>("""
            if redis.call('HGET', KEYS[1], 'sid') ~= ARGV[1] then return 0 end
            return redis.call('DEL', KEYS[1])
            """, Long.class);

    public void startSession(String memberId, String sessionId, String jti, long timeoutMillis) {
        requirePositiveTimeout(timeoutMillis);
        redisTemplate.execute(LOGIN_SCRIPT, List.of(PREFIX + memberId),
                sessionId, jti == null ? "" : jti, Long.toString(timeoutMillis));
    }
    public boolean isCurrentSession(String memberId, String sessionId) {
        return sessionId != null && sessionId.equals(redisTemplate.opsForHash().get(PREFIX + memberId, "sid"));
    }
    // 1: 성공, 0: 같은 세션의 토큰 재사용, -1: 종료되거나 교체된 세션
    public long rotateRefreshToken(String memberId, String sessionId, String currentJti,
                                   String newJti, long timeoutMillis) {
        requirePositiveTimeout(timeoutMillis);
        Long result = redisTemplate.execute(ROTATE_SCRIPT, List.of(PREFIX + memberId),
                sessionId, currentJti, newJti, Long.toString(timeoutMillis));
        if (result == null) throw new IllegalStateException("Redis 세션 확인에 실패했습니다.");
        return result;
    }
    public void endSession(String memberId, String sessionId) {
        if (sessionId != null) redisTemplate.execute(LOGOUT_SCRIPT, List.of(PREFIX + memberId), sessionId);
    }
    // 회원 탈퇴 등 계정 전체의 로그인 종료에 사용합니다.
    public void deleteRefreshToken(String memberId) { redisTemplate.delete(PREFIX + memberId); }
    private void requirePositiveTimeout(long timeoutMillis) {
        if (timeoutMillis <= 0) throw new IllegalArgumentException("만료 시간은 양수여야 합니다.");
    }
}

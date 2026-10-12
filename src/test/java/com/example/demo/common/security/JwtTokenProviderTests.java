package com.example.demo.common.security;

import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.junit.jupiter.api.Test;

import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.*;

class JwtTokenProviderTests {
    private static final String SECRET = "test-secret-key-at-least-thirty-two-bytes-long-0123456789";
    private final JwtTokenProvider provider = new JwtTokenProvider(SECRET, 1800000, 1209600000);

    @Test
    void accessTokenContainsOnlyMemberNumberAndTimes() {
        String token = provider.generateAccessToken(42L, "session-1");
        var claims = Jwts.parser().verifyWith(Keys.hmacShaKeyFor(SECRET.getBytes(StandardCharsets.UTF_8)))
                .build().parseSignedClaims(token).getPayload();
        assertEquals(Set.of("sub", "iat", "exp", "sid", "type"), claims.keySet());
        assertEquals("42", claims.getSubject());
        assertEquals(42L, provider.getMemberNumber(token));
        assertTrue(provider.validateToken(token) && provider.isTokenType(token, "access"));
    }

    @Test
    void refreshTokenCannotAuthenticateAsAccessToken() {
        var refresh = provider.generateRefreshToken(42L, "session-1");
        assertTrue(provider.validateToken(refresh.getRefreshToken()));
        assertFalse(provider.validateToken(refresh.getRefreshToken()) && provider.isTokenType(refresh.getRefreshToken(), "access"));
        assertEquals(42L, provider.getMemberNumber(refresh.getRefreshToken()));
        assertEquals(refresh.getJti(), provider.getJtiFromToken(refresh.getRefreshToken()));
    }

    @Test
    void legacyTokenIsRejectedEvenWhenLoginIdIsNumeric() {
        String token = Jwts.builder().subject("42").claim("role", "ADMIN")
                .expiration(new Date(System.currentTimeMillis() + 60000))
                .signWith(Keys.hmacShaKeyFor(SECRET.getBytes(StandardCharsets.UTF_8))).compact();
        assertFalse(provider.validateToken(token));
    }

    @Test
    void expiredAndMalformedTokensAreRejected() {
        var expired = new JwtTokenProvider(SECRET, -60000, 1209600000);
        assertFalse(provider.validateToken(expired.generateAccessToken(42L, "session-1")));
        assertFalse(provider.validateToken("invalid-token"));
    }
}

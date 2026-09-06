package com.example.demo.dto;

public record LoginRequest(
        String memberId,
        String memberPassword,
        boolean rememberMe
) {
}

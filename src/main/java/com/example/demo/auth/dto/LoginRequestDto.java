package com.example.demo.auth.dto;

public record LoginRequestDto(
        String memberId,
        String memberPassword,
        boolean rememberMe
) {
}

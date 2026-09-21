package com.example.demo.dto;

public record LoginRequestDto(
        String memberId,
        String memberPassword,
        boolean rememberMe
) {
}

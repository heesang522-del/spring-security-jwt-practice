package com.example.demo.dto;

import lombok.*;

import java.util.Date; // 또는 필요에 따라 LocalDateTime

@Getter
@Setter
@ToString
@NoArgsConstructor
@AllArgsConstructor
public class AutoLoginDto {
    private Long id;              // 고유 번호 (PK)
    private String memberId;      // 회원 아이디 (FK)
    private String token;         // 자동 로그인 암호 토큰 (UUID)
    private Date limitDate;       // 토큰 만료 일시
    private Date createdAt;       // 생성일
}
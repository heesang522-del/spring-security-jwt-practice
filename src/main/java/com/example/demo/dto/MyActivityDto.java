package com.example.demo.dto;

import lombok.Data;
import java.time.LocalDateTime;

@Data
public class MyActivityDto {
    private String actType;    // 'CHAT' 또는 'NOTICE'
    private Long targetId;
    private Long memberId;      // String -> int로 변경
    private String content;    // 메시지/제목
    private LocalDateTime actAt;
    private String linkUrl;
}
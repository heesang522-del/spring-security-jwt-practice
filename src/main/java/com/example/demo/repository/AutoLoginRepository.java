package com.example.demo.repository;

import com.example.demo.dto.AutoLoginDto;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface AutoLoginRepository {

    // 1. 자동 로그인 토큰 저장 및 갱신 (기존 2개 메서드를 하나로 통합)
    void upsertToken(AutoLoginDto autoLoginDto);

    // 2. 토큰으로 회원 아이디 조회 (인터셉터용)
    String findMemberIdByToken(String token);

    // 3. 토큰 직접 삭제 (로그아웃용)
    void deleteByToken(String token);
}
ALTER TABLE member
    ADD deleted_at DATETIME NULL COMMENT '삭제일(탈퇴일)' AFTER updated_at;

-- 1. 마지막 로그인 시간 컬럼 추가
ALTER TABLE member
    ADD last_login_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '마지막 로그인 일시' AFTER deleted_at;
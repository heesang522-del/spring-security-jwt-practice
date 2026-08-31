CREATE TABLE remember_me (
    id BIGINT AUTO_INCREMENT COMMENT '자동로그인 고유 번호',
    member_id VARCHAR(50) NOT NULL COMMENT '회원 로그인 아이디',
    token VARCHAR(255) NOT NULL COMMENT '자동 로그인 인증 토큰',
    limit_date DATETIME NOT NULL COMMENT '토큰 만료 일시',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일',
    PRIMARY KEY (id),
    UNIQUE KEY uq_token (token),
    CONSTRAINT fk_remember_me_member FOREIGN KEY (member_id)
    REFERENCES member (member_id) ON DELETE CASCADE
) COMMENT '자동 로그인 토큰 관리';
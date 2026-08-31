CREATE TABLE notice_board (
    notice_id BIGINT NOT NULL AUTO_INCREMENT COMMENT '공지사항 번호',
    member_id BIGINT NULL COMMENT '작성자 아이디',
    category VARCHAR(30) NOT NULL COMMENT '공지 분류',
    title VARCHAR(200) NOT NULL COMMENT '제목',
    content TEXT NOT NULL COMMENT '내용',
    `count` INT NOT NULL DEFAULT 0 COMMENT '조회 수',
    is_pinned TINYINT NOT NULL DEFAULT 0 COMMENT '상단 고정 여부',
    create_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '작성일',
    update_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '수정일',
    PRIMARY KEY (notice_id),
    KEY idx_notice_board_member (member_id),
    CONSTRAINT fk_notice_board_member
        FOREIGN KEY (member_id) REFERENCES member (id)
        ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='공지사항';

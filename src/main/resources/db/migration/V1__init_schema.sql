CREATE TABLE member (
    id BIGINT AUTO_INCREMENT COMMENT '회원 고유 일련번호',
    member_id VARCHAR(50) NOT NULL COMMENT '로그인 아이디',
    member_password VARCHAR(255) NOT NULL COMMENT '암호화된 비밀번호',
    nickname VARCHAR(50) NOT NULL COMMENT '사용자 닉네임',
    member_name VARCHAR(20) NOT NULL COMMENT '이름',
    member_phone VARCHAR(20) NULL COMMENT '휴대폰 번호',
    member_email VARCHAR(100) NOT NULL COMMENT '로그인 이메일',
    profile_image VARCHAR(255) NULL COMMENT '프로필 이미지 저장 경로',
    member_role VARCHAR(20) NOT NULL DEFAULT 'USER' COMMENT '권한 (USER, ADMIN, MANAGER)',
    member_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' COMMENT '상태 (ACTIVE, DORMANT, BANNED, DELETED)',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '가입일',
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '수정일',
    PRIMARY KEY (id),
    UNIQUE KEY uq_member_id (member_id),
    UNIQUE KEY uq_member_nickname (nickname),
    UNIQUE KEY uq_member_email (member_email)
) COMMENT '회원';

INSERT INTO member (
    member_id,
    member_password,
    nickname,
    member_name,
    member_phone,
    member_email,
    profile_image,
    member_role,
    member_status
) VALUES
      ('admin_master', '$2a$10$7R0Z4/zSgK88xG7e2Z3k/O.9L9gT0aD1W.X2z7m9K2lM3n4o5p6q', '최고관리자', '김관리', '010-1234-5678', 'admin@example.com', '/uploads/profiles/admin.jpg', 'ADMIN', 'ACTIVE'),
      ('hong1234', '$2a$10$e8Z4kSgK88xG7e2Z3k/O.9L9gT0aD1W.X2z7m9K2lM3n4o5p6q1', '길동이', '홍길동', '010-9876-5432', 'hong@example.com', '/uploads/profiles/hong.png', 'USER', 'ACTIVE'),
      ('kim_dev', '$2a$10$a1B2c3D4e5F6g7H8i9J0k.L1M2N3O4P5Q6R7S8T9U0V1W2X3Y4Z5a', '코딩왕', '김철수', '010-5555-1234', 'chulsoo@example.com', NULL, 'USER', 'ACTIVE'),
      ('lee_design', '$2a$10$b2C3d4E5f6G7h8I9j0K1l.M2N3O4P5Q6R7S8T9U0V1W2X3Y4Z5b', '디자인요정', '이영희', '010-7777-8888', 'younghee@example.com', '/uploads/profiles/lee.png', 'USER', 'ACTIVE'),
      ('park_runner', '$2a$10$c3D4e5F6g7H8i9J0k1L2m.N3O4P5Q6R7S8T9U0V1W2X3Y4Z5c6', '러너박', '박민수', '010-3333-4444', 'minsoo@example.com', NULL, 'USER', 'ACTIVE'),
      ('jung_sleep', '$2a$10$d4E5f6G7h8I9j0K1l2M3n.O4P5Q6R7S8T9U0V1W2X3Y4Z5d7e', '잠만보', '정수진', NULL, 'sujin@example.com', NULL, 'USER', 'DORMANT'),
      ('choi_gamer', '$2a$10$e5F6g7H8i9J0k1L2m3N4o.P5Q6R7S8T9U0V1W2X3Y4Z5e8f9', '프로게이머', '최현우', '010-2222-9999', 'hyunwoo@example.com', '/uploads/profiles/choi.jpg', 'USER', 'ACTIVE'),
      ('kang_music', '$2a$10$f6G7h8I9j0K1l2M3n4O5p.Q6R7S8T9U0V1W2X3Y4Z5f9g0', '음악대장', '강지훈', '010-4444-1111', 'jihoon@example.com', NULL, 'USER', 'ACTIVE'),
      ('yoon_banned', '$2a$10$g7H8i9J0k1L2m3N4o5P6q.R7S8T9U0V1W2X3Y4Z5g0h1', '트롤러', '윤성민', '010-6666-3333', 'sungmin@example.com', NULL, 'USER', 'BANNED'),
      ('han_deleted', '$2a$10$h8I9j0K1l2M3n4O5p6Q7r.S8T9U0V1W2X3Y4Z5h1i2', '탈퇴한유저', '한지은', NULL, 'jieun@example.com', NULL, 'USER', 'DELETED');

UPDATE member
SET created_at = '2024-01-01 09:00:00'
WHERE member_id IN ('user01', 'user02');

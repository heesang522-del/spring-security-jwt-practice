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
      ('asd123', '$2a$10$Y0tMPpqr/6Uhm41Ynnh6pOyopi.NGNXfCGZg3qVVdPTfHvGJdNwEO', '길고양', '김물산', '010-1111-1111', 'kim123@example.com', NULL, 'USER', 'ACTIVE'),
      ('qwe123', '$2a$10$Kx/bnLuX5tlBqFtnI86IzOxL87lIt4jbsOYMZ7f902i6TvsuPCa7C', '스울부싼', '김해산', '010-1111-1112', 'kim1234@example.com', NULL, 'USER', 'ACTIVE'),
      ('zxc123', '$2a$10$GRzpZXsxJHoNHGsHU4A9weBAzhDQKDOWR6k6UXIPNiR6rHx1Fwd/m', '제주도왕귤', '김강산', '010-1111-1113', 'kim12345@example.com', NULL, 'USER', 'ACTIVE'),
      ('zxcv1234', '$2a$10$GRzpZXsxJHoNHGsHU4A9weBAzhDQKDOWR6k6UXIPNiR6rHx1Fwd/m', '첩첩산', '김강사', '010-1111-1153', 'kim12346@example.com', NULL, 'ADMIN', 'ACTIVE');

-- asd123 / asdf123$
-- qwe123 / qwer123$
-- zxc123 / zxcv123$
-- zxcv1234 / zxcv123$
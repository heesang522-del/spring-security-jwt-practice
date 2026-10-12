# 패키지 구성

기능을 기준으로 `auth`, `member`, `common`에 코드를 모았습니다.

```text
src/main/java/com/example/demo/
├── auth/
│   ├── controller/   로그인·이메일 인증 API와 화면 컨트롤러
│   ├── dto/          로그인·토큰·이메일 인증 데이터
│   ├── repository/   로그인 실패·계정 잠금 관련 회원 DB 처리
│   ├── security/     사용자 인증·로그인 처리·Refresh token 저장
│   └── service/      로그인·재발급·이메일 인증·계정 찾기
├── member/
│   ├── controller/   회원가입·회원 관리 화면과 중복 확인 API
│   ├── dto/          회원 데이터
│   ├── repository/   회원 조회·등록·수정·삭제
│   ├── scheduler/    휴면 전환·탈퇴 회원 정리
│   └── service/      회원 관리·계정 복구
├── common/
│   ├── config/       Security·비밀번호 인코더·웹 설정
│   ├── security/     JWT 생성·검증 및 요청 인증 필터
│   └── util/         파일 처리
└── demoApplication.java

src/main/resources/mapper/
├── auth/             MemberSecurityRepository.xml
└── member/           MemberRepository.xml
```

MyBatis XML의 namespace와 DTO 경로는 새 Java 패키지를 참조하며,
`application.yml`의 mapper-locations는 `classpath:mapper/**/*.xml`입니다.

이번 변경은 패키지와 Mapper 위치 정리입니다. URL, JSP 화면 경로,
DB 스키마, 로그인·토큰 동작 및 Maven 빌드 방식은 유지합니다.

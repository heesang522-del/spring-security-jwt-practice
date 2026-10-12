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

## 병합 후 인증 구조

토큰의 `sub`는 내부 회원 번호(`member.id`)이며 권한은 DB에서 조회합니다.
중복 로그인 종료를 위한 `sid`, Access/Refresh 구분을 위한 `type`은 유지합니다.
Refresh token에는 교체 검증용 `jti`도 포함됩니다. 기존 role 포함 토큰은 거절됩니다.

Redis 로그인 정보는 `LOGIN:member-number:{회원번호}` Hash에 저장됩니다.
일반 로그인도 저장되며, 자동 로그인 선택 시 Refresh token의 `jti`가 함께 저장됩니다.
회원 번호 12의 정보는 `HGETALL LOGIN:member-number:12`, 만료 시간은
`TTL LOGIN:member-number:12`로 확인합니다. 기존 키는 마이그레이션하지 않으므로
서버 재시작 후 다시 로그인해야 합니다.

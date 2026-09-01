# 로그인 인증 방식 변경

## 1. 변경 목적

기존에는 **Spring Security + Session + Cookie** 방식으로 로그인 인증을 구현하였다.

React 프론트엔드와 Spring 백엔드를 분리하는 구조로 변경하면서, 로그인 인증 방식을 **Session 기반 인증에서 JWT(JSON Web Token) 기반 인증으로 변경**한다.

이번 작업에서는 우선 **로그인 기능만 JWT 방식으로 변경**하고, 회원가입 및 회원정보 수정 기능은 이후 작업에서 진행한다.

---

## 2. 기존 로그인 방식

기존에는 로그인 성공 후 서버에서 세션을 생성하고, 쿠키를 통해 로그인 상태를 유지하였다.

```text
로그인 요청
    ↓
Spring Security
    ↓
CustomAuthenticationProvider
    ↓
회원 조회 및 비밀번호 검증
    ↓
인증 성공
    ↓
Session 생성
    ↓
JSESSIONID Cookie
    ↓
이후 요청에서 Session 확인
```

또한 `remember-me` 기능을 이용한 자동 로그인도 별도로 구현되어 있었다.

---

## 3. JWT 로그인 방식으로 변경

JWT 방식에서는 로그인 성공 후 서버가 JWT를 생성하여 클라이언트에게 전달한다.

이후 클라이언트는 API 요청 시 JWT를 함께 전달하고, 서버에서는 JWT의 유효성을 검증하여 사용자를 인증한다.

```text
로그인 요청
    ↓
Spring Security
    ↓
CustomAuthenticationProvider
    ↓
회원 조회 및 비밀번호 검증
    ↓
인증 성공
    ↓
JWT 생성
    ↓
클라이언트에게 JWT 전달
    ↓
이후 API 요청
    ↓
JwtAuthenticationFilter
    ↓
JWT 검증
    ↓
인증된 사용자로 요청 처리
```

### 기존 방식과의 차이

| 구분          | 기존 방식              | 변경 방식          |
| ----------- | ------------------ | -------------- |
| 인증 상태       | Session            | JWT            |
| 클라이언트 인증 정보 | JSESSIONID Cookie  | JWT            |
| 로그인 성공 처리   | Session 생성         | JWT 생성         |
| 이후 요청       | Session 확인         | JWT 검증         |
| 자동 로그인      | Remember-me Cookie | JWT 기반으로 별도 설계 |
| 인증 방식       | Stateful           | Stateless      |

---

## 4. 기존 코드에서 유지되는 부분

JWT를 사용한다고 해서 기존 Spring Security 인증 로직을 모두 제거하는 것은 아니다.

### `CustomAuthenticationProvider`

유지한다.

다음과 같은 기존 인증 로직은 JWT와 관계없이 필요하다.

* 로그인 아이디로 회원 조회
* BCrypt를 이용한 비밀번호 검증
* 로그인 실패 횟수 확인
* 계정 잠금 확인
* 회원 상태 확인

    * `ACTIVE`
    * `DORMANT`
    * `BANNED`
    * `DELETED`
* 인증 성공 시 `Authentication` 반환

즉, **"아이디와 비밀번호가 올바른 사용자인가?"를 확인하는 역할은 그대로 유지한다.**

---

### `CustomUserDetailsService`

유지한다.

```text
memberId
   ↓
MemberRepository
   ↓
DB에서 회원 조회
   ↓
CustomUserDetails 생성
```

Spring Security가 회원 정보를 가져오는 역할은 JWT를 사용해도 필요하다.

---

### `LoginAttemptService`

유지한다.

로그인 실패 횟수와 계정 잠금 기능은 JWT 자체와 관계없는 인증 보안 기능이므로 그대로 사용한다.

---

### `LoginUnlockTokenService`

유지한다.

잠긴 계정의 잠금 해제 토큰을 관리하는 기능 역시 JWT 전환과 직접적인 관계가 없으므로 그대로 유지한다.

---

## 5. 수정되는 부분

### `SecurityConfig`

수정한다.

기존의 Session 및 `formLogin()` 기반 설정을 JWT 인증 구조에 맞게 변경한다.

주요 변경 사항:

```text
Session 기반 인증
        ↓
Stateless 인증
```

JWT 인증을 처리하는 `JwtAuthenticationFilter`도 Security Filter Chain에 추가한다.

---

### `CustomLoginFailureHandler`

수정한다.

기존에는 로그인 실패 시 JSP 페이지로 redirect하는 방식이었다.

JWT + React 구조에서는 페이지 이동보다는 **로그인 실패 결과를 JSON 형태의 API 응답으로 전달**하는 방식으로 변경한다.

```text
기존

로그인 실패
    ↓
redirect
    ↓
로그인 페이지


변경

로그인 실패
    ↓
JSON 응답
    ↓
React에서 결과 처리
```

---

### `CustomUserDetails`

필요한 부분을 JWT 인증 구조에 맞게 수정한다.

Spring Security가 인증된 사용자와 권한 정보를 관리할 수 있도록 기존 구조를 활용하되, JWT에서 사용할 사용자 식별 정보와 권한을 고려한다.

---

## 6. 제거되는 부분

### `CustomLoginSuccessHandler`

제거한다.

기존에는 로그인 성공 후 다음과 같은 작업을 담당했다.

* Session 생성
* Session에 사용자 정보 저장
* Remember-me 처리
* 로그인 성공 후 페이지 redirect

JWT 방식에서는 로그인 성공 후 **JWT를 생성하여 클라이언트에게 전달하는 방식**으로 변경하므로 기존 SuccessHandler의 역할이 더 이상 필요하지 않다.

---

### `AutoLoginFilter`

제거한다.

기존 `AutoLoginFilter`는 `remember-me` Cookie를 확인하여 사용자를 자동 로그인시키고 Session에 인증 정보를 저장하는 역할을 담당했다.

JWT 방식에서는 기존 Session + Remember-me 구조를 사용하지 않으므로 제거한다.

---

## 7. 새로 추가되는 부분

### `JwtTokenProvider`

JWT를 생성하고 검증하는 역할을 담당한다.

주요 역할:

```text
JWT 생성
JWT 유효성 검사
JWT에서 사용자 식별 정보 추출
JWT 만료 여부 확인
```

로그인 인증이 성공하면 `JwtTokenProvider`를 통해 JWT를 생성한다.

---

### `JwtAuthenticationFilter`

로그인 이후 API 요청에서 JWT를 확인하는 역할을 담당한다.

클라이언트가 다음과 같이 요청한다고 가정한다.

```http
Authorization: Bearer {JWT}
```

필터는 JWT를 추출하고 검증한 뒤, 유효한 토큰이라면 Spring Security의 인증 정보로 등록한다.

```text
API 요청
    ↓
Authorization Header 확인
    ↓
JWT 추출
    ↓
JWT 검증
    ↓
유효한 JWT
    ↓
Spring Security 인증 정보 등록
    ↓
Controller 실행
```

---

## 8. 최종적인 로그인 구조

JWT 전환이 완료되면 로그인 인증 구조는 다음과 같다.

```text
┌─────────────┐
│    React    │
└──────┬──────┘
       │
       │ ID / Password
       ▼
┌──────────────────────┐
│ Spring Security      │
│                      │
│ CustomAuthentication │
│ Provider             │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ 회원 조회             │
│ BCrypt 비밀번호 검증  │
│ 회원 상태 확인        │
└──────────┬───────────┘
           │
           │ 인증 성공
           ▼
┌──────────────────────┐
│ JwtTokenProvider     │
│                      │
│ JWT 생성              │
└──────────┬───────────┘
           │
           │ JWT
           ▼
┌─────────────┐
│    React    │
└──────┬──────┘
       │
       │ API 요청 + JWT
       ▼
┌──────────────────────┐
│ JwtAuthentication    │
│ Filter               │
└──────────┬───────────┘
           │
           │ JWT 검증
           ▼
┌──────────────────────┐
│ Spring Security      │
│ SecurityContext      │
└──────────┬───────────┘
           │
           ▼
      Controller
```

---

## 9. 파일 변경 요약

| 파일                             | 변경 내용              |
| ------------------------------ | ------------------ |
| `SecurityConfig`               | 🔧 JWT 방식으로 수정     |
| `AutoLoginFilter`              | ❌ 제거               |
| `CustomAuthenticationProvider` | ✅ 유지               |
| `CustomLoginFailureHandler`    | 🔧 JSON 응답 방식으로 수정 |
| `CustomLoginSuccessHandler`    | ❌ 제거               |
| `CustomUserDetails`            | 🔧 JWT 인증에 맞게 수정   |
| `CustomUserDetailsService`     | ✅ 유지               |
| `LoginAttemptService`          | ✅ 유지               |
| `LoginUnlockTokenService`      | ✅ 유지               |
| `JwtTokenProvider`             | 🆕 추가              |
| `JwtAuthenticationFilter`      | 🆕 추가              |

---

## 10. 작업 범위

이번 작업에서는 **로그인 기능의 JWT 전환만 진행한다.**

### 이번 작업

* [x] 기존 Session 기반 로그인 구조 분석
* [ ] JWT 의존성 추가
* [ ] `JwtTokenProvider` 구현
* [ ] `JwtAuthenticationFilter` 구현
* [ ] `SecurityConfig` JWT 방식으로 변경
* [ ] 로그인 API JWT 방식으로 변경
* [ ] 로그인 실패 응답 변경
* [ ] 기존 Session / Remember-me 로그인 제거
* [ ] JWT 로그인 테스트

### 이후 작업

* [ ] 회원가입
* [ ] 회원정보 조회
* [ ] 회원정보 수정
* [ ] 비밀번호 변경
* [ ] JWT 로그아웃
* [ ] Refresh Token
* [ ] CORS 설정

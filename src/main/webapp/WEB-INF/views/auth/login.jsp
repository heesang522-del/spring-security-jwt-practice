<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!doctype html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="description" content="Youwin 음악 커뮤니티 로그인">
    <title>로그인 | Youwin</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/app.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/auth.css">
</head>
<body>
<div class="auth-page">
    <aside class="auth-aside" aria-label="Youwin 소개">
        <a class="brand auth-brand" href="${pageContext.request.contextPath}/" aria-label="Youwin 홈">
            <span class="brand__mark">YW</span><span>Youwin</span>
        </a>
        <div class="auth-aside__copy">
            <p class="auth-aside__eyebrow">Your music, your people</p>
            <h2>좋아하는 음악이<br>대화가 되는 곳</h2>
            <p class="auth-aside__description">취향이 닿는 사람들과 플레이리스트를 나누고, 지금 재생 중인 음악에 관해 이야기해 보세요.</p>
        </div>
        <p class="auth-aside__note">© 2026 Youwin music community</p>
    </aside>

    <main class="auth-main">
        <section class="auth-card" aria-labelledby="login-title">
            <a class="auth-back" href="${pageContext.request.contextPath}/">← 홈으로 돌아가기</a>
            <div class="auth-heading">
                <p class="auth-heading__eyebrow">Welcome back</p>
                <h1 class="auth-title" id="login-title">다시 만나 반가워요</h1>
                <p class="auth-description">계정에 로그인하고 오늘의 음악 이야기를 이어가세요.</p>
            </div>

            <form id="loginForm" class="auth-form" action="${pageContext.request.contextPath}/auth/login" method="post">
                <div class="input-group">
                    <label for="memberId">아이디</label>
                    <input type="text" id="memberId" name="memberId" value="${savedMemberId}" required autocomplete="username" placeholder="아이디를 입력하세요">
                </div>
                <div class="input-group">
                    <label for="memberPassword">비밀번호</label>
                    <input type="password" id="memberPassword" name="memberPassword" required autocomplete="current-password" placeholder="비밀번호를 입력하세요">
                </div>

                <div id="loginErrorMsg" class="error-msg" aria-live="polite"></div>
                <c:if test="${param.error == 'true'}">
                    <div class="error-msg show" role="alert"><c:out value="${param.exception}"/></div>
                </c:if>

                <div class="checkbox-group">
                    <input type="checkbox" id="remember-me" name="remember-me" value="true">
                    <label for="remember-me">자동 로그인 유지</label>
                </div>
                <button type="submit" class="btn-submit">로그인</button>
            </form>

            <nav class="footer-links" aria-label="계정 도움말">
                <a href="${pageContext.request.contextPath}/auth/find-id">아이디 찾기</a>
                <span class="bar" aria-hidden="true">·</span>
                <a href="${pageContext.request.contextPath}/auth/find-password">비밀번호 찾기</a>
                <span class="bar" aria-hidden="true">·</span>
                <a href="${pageContext.request.contextPath}/member/join-step1">회원가입</a>
            </nav>
        </section>
    </main>
</div>

    <script>
    document.addEventListener('DOMContentLoaded', function() {
        // URL의 쿼리 파라미터 읽기
        const urlParams = new URLSearchParams(window.location.search);

        // 다른 곳에서 로그인하여 세션이 만료된 경우 (기존 유저만 해당)
        if (urlParams.has('expired')) {
            alert('다른 기기나 브라우저에서 로그인하여 접속이 종료되었습니다.');

            // alert 확인 후 주소창의 ?expired=true 파라미터 깔끔하게 제거
            history.replaceState(null, null, window.location.pathname);
        }

        // 2. 로그인 실패 / 차단 관련 알림 팝업 (추가)
        if (urlParams.has('error')) {
            // 새로고침 시 에러 메시지가 다시 렌더링되거나 중복 처리되는 것을 방지하기 위해 URL만 깔끔하게 뒤로 넘김
            history.replaceState(null, null, window.location.pathname);
        }
    });
</script>
</body>
</html>

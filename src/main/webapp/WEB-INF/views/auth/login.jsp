<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="false"%>
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

            <form id="loginForm" class="auth-form">
                <div class="input-group">
                    <label for="memberId">아이디</label>
                    <input type="text" id="memberId" name="memberId" value="${savedMemberId}" required autocomplete="username" placeholder="아이디를 입력하세요">
                </div>
                <div class="input-group">
                    <label for="memberPassword">비밀번호</label>
                    <input type="password" id="memberPassword" name="memberPassword" required autocomplete="current-password" placeholder="비밀번호를 입력하세요">
                </div>

                <div id="loginErrorMsg" class="error-msg" aria-live="polite"></div>

                <div class="checkbox-group">
                    <input type="checkbox" id="remember-me" name="remember-me">
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
        const loginForm = document.getElementById('loginForm');
        const loginErrorMsg = document.getElementById('loginErrorMsg');
        const contextPath = '${pageContext.request.contextPath}';

        loginForm.addEventListener('submit', async function(event) {
            event.preventDefault();
            loginErrorMsg.textContent = '';
            loginErrorMsg.classList.remove('show');

            try {
                const response = await fetch(`${contextPath}/api/auth/login`, {
                    method: 'POST',
                    headers: {'Content-Type': 'application/json'},
                    body: JSON.stringify({
                        memberId: document.getElementById('memberId').value,
                        memberPassword: document.getElementById('memberPassword').value,
                        rememberMe: document.getElementById('remember-me').checked
                    })
                });

                const result = await response.json();

                if (!response.ok) {
                    throw new Error(result.message || '로그인에 실패했습니다.');
                }

                // 기존 토큰 삭제 후 설정
                localStorage.removeItem('accessToken');

                const tokenStorage = document.getElementById('remember-me').checked
                    ? localStorage
                    : sessionStorage;
                tokenStorage.setItem('accessToken', result.accessToken);

                window.location.href = `${contextPath}/`;
            } catch (error) {
                loginErrorMsg.textContent = error.message;
                loginErrorMsg.classList.add('show');
            }
        });

        // 세션 만료 알림 처리
        const urlParams = new URLSearchParams(window.location.search);
        if (urlParams.has('expired')) {
            alert('다른 기기나 브라우저에서 로그인하여 접속이 종료되었습니다.');
            history.replaceState(null, null, window.location.pathname);
        }
    });
</script>
</body>
</html>
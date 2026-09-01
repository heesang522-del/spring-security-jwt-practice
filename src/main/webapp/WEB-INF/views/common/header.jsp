<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>

<c:set var="ctx" value="${pageContext.request.contextPath}" scope="request" />

<!doctype html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="description" content="취향으로 연결되는 음악 커뮤니티 Youwin">
    <title>Youwin | 음악으로 연결되는 순간</title>
    <link rel="stylesheet" href="${ctx}/app.css">
    <link rel="stylesheet" href="${ctx}/home.css">
    <link rel="stylesheet" href="${ctx}/account.css">
</head>
<body>
<div class="site-shell">
    <header class="site-header">
        <div class="site-container site-header__inner">
            <a class="brand" href="${ctx}/" aria-label="Youwin 홈">
                <span class="brand__mark">YW</span>
                <span>Youwin</span>
            </a>

            <nav class="site-nav" data-site-nav aria-label="주요 메뉴">
                <a href="${ctx}/">홈</a>
                <a href="${ctx}/board">게시판</a>
                <a href="${ctx}/index">채팅방</a>

                <!-- 🟢 로그인 상태일 때만 마이페이지 노출 -->
                <sec:authorize access="isAuthenticated()">
                    <a href="${ctx}/member/mypage">마이페이지</a>
                </sec:authorize>

                <div class="user-menu">
                    <!-- 1. 로그인 상태인 경우 -->
                    <sec:authorize access="isAuthenticated()">
                        <span class="welcome-msg">
                            <strong>${sessionScope.nickname}</strong>님 환영합니다!
                        </span>
                        <!-- 스프링 시큐리티 로그아웃 (CSRF 설정에 따라 POST 요청 권장) -->
                        <form action="${ctx}/member/logout" method="post" style="display:inline;">
                            <!-- Spring Security CSRF 토큰 (CSRF 사용 시 필요) -->
                            <input type="hidden" name="${_csrf.parameterName}" value="${_csrf.token}" />
                            <button type="submit" class="auth-btn logout-btn">로그아웃</button>
                        </form>
                    </sec:authorize>

                    <!-- 2. 비로그인(익명) 상태인 경우 -->
                    <sec:authorize access="isAnonymous()">
                        <a href="${ctx}/auth/login" class="auth-btn">로그인</a>
                        <a href="${ctx}/member/join-step1" class="auth-btn">회원가입</a>
                    </sec:authorize>
                </div>
            </nav>

            <div class="site-header__actions">
                <form class="header-search" data-home-search role="search">
                    <label class="sr-only" for="global-search">통합 검색</label>
                    <input id="global-search" name="query" type="search" placeholder="아티스트, 노래, 게시글 검색">
                </form>
                <a class="avatar-link" href="${ctx}/member/mypage" aria-label="마이페이지">YU</a>
            </div>

            <button class="menu-toggle" type="button" data-menu-toggle aria-label="메뉴 열기" aria-expanded="false"></button>
        </div>
    </header>
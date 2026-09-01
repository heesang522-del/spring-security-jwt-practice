<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%@ taglib prefix="sec" uri="http://www.springframework.org/security/tags" %>

<!-- 공통 Header Include -->
<%@ include file="/WEB-INF/views/common/header.jsp" %>

    <main class="page-main home-main">
        <div class="site-container">
            <section class="hero" aria-labelledby="hero-title">
                <div class="hero__copy">
                    <p class="hero__eyebrow">Music community, live now</p>
                    <h1 id="hero-title">같이 들으면<br>더 선명해지는 음악</h1>
                    <p class="hero__description">좋아하는 아티스트와 노래를 중심으로 대화하고, 오늘의 플레이리스트를 발견하세요.</p>
                    <div class="hero__actions">
                        <a class="button" href="${pageContext.request.contextPath}/index">지금 대화 참여하기</a>
                        <a class="button button--secondary" href="#open-rooms">인기 채팅방 보기</a>
                    </div>
                </div>
                <div class="hero__stage" aria-hidden="true">
                    <div class="now-playing">
                        <div class="now-playing__visual"></div>
                        <div class="now-playing__top">
                            <div>
                                <p class="now-playing__title"><strong>Midnight Drive</strong></p>
                                <p class="now-playing__artist">Youwin Radio · City Pop</p>
                            </div>
                            <div class="equalizer"><span></span><span></span><span></span><span></span></div>
                        </div>
                    </div>
                </div>
            </section>

            <section class="home-section" id="open-rooms" aria-labelledby="room-title">
                <div class="section-head">
                    <div>
                        <h2 class="section-title" id="room-title">지금 활발한 오픈 톡</h2>
                        <p class="section-copy">같은 곡을 듣고 있는 사람들과 바로 이야기해 보세요.</p>
                    </div>
                    <a class="text-link" href="${pageContext.request.contextPath}/index">전체 채팅방 보기 →</a>
                </div>
                <div class="room-grid">
                    <a class="room-card" href="${pageContext.request.contextPath}/chatroom">
                        <span class="room-card__art"></span>
                        <div class="room-card__top">
                            <span class="chip chip--live">LIVE</span>
                            <span class="room-card__count">128명 참여 중</span>
                        </div>
                        <h3>오늘 공개된 신곡,<br>첫인상 같이 나눠요</h3>
                        <div class="room-card__footer">
                            <span class="room-card__host">HOST · 윤슬</span>
                            <span class="room-card__enter">입장하기 →</span>
                        </div>
                    </a>
                    <a class="room-card" href="${pageContext.request.contextPath}/chatroom">
                        <span class="room-card__art"></span>
                        <div class="room-card__top">
                            <span class="chip">PLAYLIST</span>
                            <span class="room-card__count">76명 참여 중</span>
                        </div>
                        <h3>새벽 작업을 위한<br>잔잔한 인디 플레이리스트</h3>
                        <div class="room-card__footer">
                            <span class="room-card__host">HOST · 파란밤</span>
                            <span class="room-card__enter">입장하기 →</span>
                        </div>
                    </a>
                    <a class="room-card" href="${pageContext.request.contextPath}/chatroom">
                        <span class="room-card__art"></span>
                        <div class="room-card__top">
                            <span class="chip">ARTIST</span>
                            <span class="room-card__count">54명 참여 중</span>
                        </div>
                        <h3>이번 주 콘서트<br>셋리스트 예상 모임</h3>
                        <div class="room-card__footer">
                            <span class="room-card__host">HOST · 네온사인</span>
                            <span class="room-card__enter">입장하기 →</span>
                        </div>
                    </a>
                </div>
            </section>

            <section class="home-section home-columns" aria-label="커뮤니티 소식">
                <div class="surface feed-card">
                    <div class="section-head">
                        <div>
                            <h2 class="section-title">커뮤니티 인기글</h2>
                            <p class="section-copy">오늘 가장 많은 이야기가 오간 게시글</p>
                        </div>
                        <a class="text-link" href="${pageContext.request.contextPath}/board">더보기 →</a>
                    </div>
                    <ol class="feed-list">
                        <li class="feed-item">
                            <span class="feed-item__rank">01</span>
                            <div><a class="feed-item__title" href="${pageContext.request.contextPath}/board">비 오는 날 첫 곡으로 듣기 좋은 음악을 추천해 주세요</a><p class="feed-item__meta">플레이리스트 · 파란밤 · 12분 전</p></div>
                            <span class="feed-item__comments">댓글 34</span>
                        </li>
                        <li class="feed-item">
                            <span class="feed-item__rank">02</span>
                            <div><a class="feed-item__title" href="${pageContext.request.contextPath}/board">이번 페스티벌 라인업에서 꼭 봐야 할 무대</a><p class="feed-item__meta">공연 · 모노 · 28분 전</p></div>
                            <span class="feed-item__comments">댓글 21</span>
                        </li>
                        <li class="feed-item">
                            <span class="feed-item__rank">03</span>
                            <div><a class="feed-item__title" href="${pageContext.request.contextPath}/board">헤드폰으로 다시 듣고 놀랐던 앨범 이야기</a><p class="feed-item__meta">자유 · 리듬 · 1시간 전</p></div>
                            <span class="feed-item__comments">댓글 18</span>
                        </li>
                    </ol>
                </div>
                <aside class="surface schedule-card" aria-labelledby="schedule-title">
                    <div class="section-head">
                        <div><h2 class="section-title" id="schedule-title">오늘의 세션</h2><p class="section-copy">곧 시작하는 라이브 토크</p></div>
                    </div>
                    <div class="schedule-list">
                        <div class="schedule-item"><span class="schedule-item__time">19:30</span><div><strong>퇴근길 시티팝</strong><span>DJ 민트 · 46명 예약</span></div></div>
                        <div class="schedule-item"><span class="schedule-item__time">21:00</span><div><strong>신보 같이 듣기</strong><span>HOST 윤슬 · 82명 예약</span></div></div>
                        <div class="schedule-item"><span class="schedule-item__time">23:00</span><div><strong>심야 재즈 라운지</strong><span>DJ 모노 · 31명 예약</span></div></div>
                    </div>
                </aside>
            </section>
        </div>
    </main>

<!-- 공통 Footer Include -->
<%@ include file="/WEB-INF/views/common/footer.jsp" %>
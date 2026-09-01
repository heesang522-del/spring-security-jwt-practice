<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="sec" uri="http://www.springframework.org/security/tags" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>

<!-- 공통 Header Include -->
<%@ include file="/WEB-INF/views/common/header.jsp" %>
<!-- 🟢 마이페이지 전용 CSS 불러오기 -->
<link rel="stylesheet" href="${pageContext.request.contextPath}/mypage.css">

<!-- 🟢 Spring Security principal 및 memberDto 변수 안전하게 바인딩 -->
<sec:authorize access="isAuthenticated()">
    <sec:authentication property="principal" var="principal"/>
    <c:set var="member" value="${not empty principal.memberDto ? principal.memberDto : member}"/>
</sec:authorize>

    <main class="page-main">
        <div class="site-container">
            <section class="surface profile-hero" aria-labelledby="profile-title">
                <!-- 1. 프로필 사진 (경로 안전 바인딩) -->
                <div class="profile-avatar">
                    <c:choose>
                        <c:when test="${not empty member.profileImage}">
                            <img id="mainAvatarImg"
                                 src="${pageContext.request.contextPath}${member.profileImage}"
                                 class="profile-img"
                                 alt="사용자 프로필 사진">
                        </c:when>
                        <c:otherwise>
                            <img id="mainAvatarImg"
                                 src="${pageContext.request.contextPath}/upload/profile/default-profile.svg"
                                 class="profile-img"
                                 alt="기본 프로필 사진">
                        </c:otherwise>
                    </c:choose>
                </div>

                <div class="profile-copy">
                    <p class="profile-copy__label">MY MUSIC PROFILE</p>
                    <h1 id="profile-title"><c:out value="${member.nickname}"/></h1>
                    <div class="profile-copy__meta">
                        <span>@<c:out value="${member.memberId}"/></span>
                        <span>가입일 <c:out value="${member.formattedCreatedAt}"/></span>
                        <span>수정일 <c:out value="${member.formattedUpdatedAt}"/></span>
                    </div>
                </div>

                <div class="profile-hero__actions">
                    <a class="button button--secondary" href="${pageContext.request.contextPath}/member/settings">프로필 수정</a>
                    <a class="button" href="${pageContext.request.contextPath}/index">채팅방 가기</a>
                </div>
            </section>

            <section class="profile-stats" aria-label="활동 통계">
                <div class="surface stat-card"><span class="stat-card__label">저장한 곡</span><strong class="stat-card__value">48</strong></div>
                <div class="surface stat-card"><span class="stat-card__label">참여한 채팅</span><strong class="stat-card__value">12</strong></div>
                <div class="surface stat-card"><span class="stat-card__label">작성한 글</span><strong class="stat-card__value">7</strong></div>
                <div class="surface stat-card"><span class="stat-card__label">받은 공감</span><strong class="stat-card__value">126</strong></div>
            </section>

            <div class="mypage-grid">
                <section class="surface mypage-card" aria-labelledby="playlist-title">
                    <div class="section-head">
                    <div>
                        <h2 class="section-title" id="playlist-title">내 채팅방</h2>
                        <p class="section-copy">가입한 채팅방 목록입니다.</p>
                    </div>
                </div>

                <div class="playlist">

                    <c:forEach var="room" items="${myRooms}" varStatus="status">

                        <a class="playlist-item" href="${pageContext.request.contextPath}/chatroom?roomId=${room.roomId}">

                            <span class="playlist-item__number">${(currentPage-1)*10 + status.index + 1}</span>
                            <span class="playlist-item__cover"></span>

                            <div>
                                <strong class="playlist-item__title">${room.roomName}</strong>
                                <span class="playlist-item__artist">${room.roomDescription}</span>
                            </div>
                        </a>
                    </c:forEach>
                    <c:if test="${empty myRooms}"><div class="playlist-item">가입한 채팅방이 없습니다.</div></c:if>

                    </div>

                    <div class="pagination">

                    <c:if test="${currentPage > 1}">
                        <a href="${pageContext.request.contextPath}/member/mypage?page=${currentPage-1}">이전</a>
                    </c:if>

                    <c:forEach begin="1" end="${totalPage}" var="i">
                    <a href="${pageContext.request.contextPath}/member/mypage?page=${i}" class="${i==currentPage?'active':''}">${i}</a>

                    </c:forEach>

                    <c:if test="${currentPage < totalPage}"><a href="${pageContext.request.contextPath}/member/mypage?page=${currentPage+1}">다음</a>
                    </c:if>

                    </div>
                </section>

                <aside>
                    <section class="surface mypage-card" aria-labelledby="activity-title">
                        <div class="section-head">
                            <div>
                                <h2 class="section-title" id="activity-title">최근 활동</h2>
                                <p class="section-copy">내 커뮤니티 기록</p>
                            </div>
                        </div>
                        <div class="activity-list">
                            <c:forEach var="act" items="${recentActivities}">
                                <article class="activity-item">
                                    <p class="activity-item__type">
                                        <c:choose>
                                            <c:when test="${act.actType == 'CHAT'}">채팅</c:when>
                                            <c:when test="${act.actType == 'NOTICE'}">게시글</c:when>
                                            <c:otherwise>기타</c:otherwise>
                                        </c:choose>
                                    </p>
                                    <p class="activity-item__title">
                                        <a href="${ctx}${act.linkUrl}">
                                            <c:out value="${act.content}" />
                                        </a>
                                    </p>
                                    <time datetime="${act.actAt}">
                                        <fmt:parseDate value="${act.actAt}" pattern="yyyy-MM-dd'T'HH:mm" var="parsedDate" type="both" />
                                        <fmt:formatDate value="${parsedDate}" pattern="MM월 dd일 HH:mm" />
                                    </time>
                                </article>
                            </c:forEach>

                            <c:if test="${empty recentActivities}">
                                <article class="activity-item">
                                    <p class="activity-item__title">최근 활동 내역이 없습니다.</p>
                                </article>
                            </c:if>
                        </div>
                    </section>
                </aside>
            </div>
        </div>
    </main>

<!-- 공통 Footer Include -->
<%@ include file="/WEB-INF/views/common/footer.jsp" %>
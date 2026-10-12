<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" session="false"%>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="sec" uri="http://www.springframework.org/security/tags" %>

<!-- 공통 Header Include -->
<%@ include file="/WEB-INF/views/common/header.jsp" %>

<!-- 설정 페이지 전용 CSS 추가 -->
<link rel="stylesheet" href="${ctx}/mypage.css">

<%-- Security Context의 memberDto 객체를 member 변수로 안전하게 바인딩 --%>
<sec:authorize access="isAuthenticated()">
  <sec:authentication property="principal" var="principal"/>
  <c:set var="member" value="${not empty principal.memberDto ? principal.memberDto : memberDto}"/>
</sec:authorize>

  <main class="page-main">
    <div class="site-container settings-container">
      <section class="settings-head page-heading">
        <p class="page-eyebrow">Account settings</p>
        <h1 class="page-title">계정 및 프로필 설정</h1>
        <p class="page-description">프로필과 로그인 정보를 안전하게 관리하세요.</p>
      </section>

      <!-- 1. 프로필 사진 카드 -->
      <section class="surface settings-card">
        <div class="settings-card__head"><h2 class="section-title">프로필 사진</h2><span class="chip">PROFILE</span></div>
        <div class="profile-avatar-edit">
          <div class="profile-avatar" id="avatarPreviewContainer">
            <img id="mainAvatarImg"
                 src="${not empty member.profileImage ? pageContext.request.contextPath.concat(member.profileImage) : pageContext.request.contextPath.concat('/uploads/profile/default-profile.svg')}"
                 class="profile-img" alt="프로필 사진">
          </div>
          <button type="button" class="button button--secondary" data-modal-open="modalProfile">사진 변경</button>
        </div>
      </section>

      <!-- 2. 계정 정보 리스트 카드 -->
      <section class="surface settings-card">
        <div class="settings-card__head"><h2 class="section-title">계정 정보</h2><span class="chip">SECURITY</span></div>

        <div class="setting-row">
          <div class="setting-info"><label>닉네임</label><p>${member.nickname}</p></div>
          <button type="button" class="button button--text" data-modal-open="modalNickname">변경</button>
        </div>

        <div class="setting-row">
          <div class="setting-info"><label>전화번호</label><p>${member.memberPhone}</p></div>
          <button type="button" class="button button--text" data-modal-open="modalPhone">변경</button>
        </div>

        <div class="setting-row">
          <div class="setting-info"><label>이메일</label><p>${member.memberEmail}</p></div>
          <button type="button" class="button button--text" data-modal-open="modalEmail">변경</button>
        </div>

        <div class="setting-row">
          <div class="setting-info"><label>비밀번호</label><p>••••••••</p></div>
          <button type="button" class="button button--text" data-modal-open="modalPassword">변경</button>
        </div>
      </section>

      <!-- 3. 계정 삭제(탈퇴) -->
      <div class="settings-danger"><p>더 이상 서비스를 이용하지 않는 경우 계정을 삭제할 수 있습니다.</p><a href="#modalDelete" data-modal-open="modalDelete">계정 삭제</a></div>
    </div>
  </main>

<!-- ==================== 팝업(모달) 영역들 ==================== -->

<!-- 1. 닉네임 변경 팝업 -->
<div class="modal-overlay" id="modalNickname">
  <div class="modal-content">
    <div class="modal-header">
      <h3>닉네임 변경</h3>
      <button type="button" class="modal-close" data-modal-close="modalNickname">&times;</button>
    </div>
    <form action="${pageContext.request.contextPath}/member/updateNickname" method="post" id="formNickname" data-validated-form>
      <input type="hidden" name="${_csrf.parameterName}" value="${_csrf.token}" />

      <div class="form-group" style="margin-bottom: 1rem;">
        <label for="nickname">새 닉네임</label>
        <div class="input-with-btn" style="display: flex; gap: 8px; margin-top: 4px;">
          <input type="text" id="nickname" name="nickname" value="${member.nickname}" class="input-control" style="flex: 1;">
          <button type="button" class="button button--secondary" id="btn-check-nickname" data-settings-action="checkDuplicateNickname">중복확인</button>
        </div>
        <span class="error-msg" id="err-nickname" data-default="공백 없이 2자 이상 10자 이하로 입력해 주세요.">공백 없이 2자 이상 10자 이하로 입력해 주세요.</span>
      </div>
      <button type="button" class="button button--full" data-settings-action="submitNicknameForm">수정 완료</button>
    </form>
  </div>
</div>

<!-- 2. 전화번호 변경 팝업 -->
<div class="modal-overlay" id="modalPhone">
  <div class="modal-content">
    <div class="modal-header">
      <h3>전화번호 변경</h3>
      <button type="button" class="modal-close" data-modal-close="modalPhone">&times;</button>
    </div>
    <form action="${pageContext.request.contextPath}/member/updatePhone" method="post" id="formPhone" data-validated-form>
      <input type="hidden" name="${_csrf.parameterName}" value="${_csrf.token}" />

      <div class="form-group" style="margin-bottom: 1rem;">
        <label for="memberPhone">새 전화번호</label>
        <input type="tel" id="memberPhone" name="memberPhone" value="${member.memberPhone}" maxlength="11" class="input-control">
        <span class="error-msg" id="err-phone" data-default="숫자만 입력해 주세요. (예: 01012345678)">숫자만 입력해 주세요. (예: 01012345678)</span>
      </div>
      <button type="button" id="btnPhone" class="button button--full" data-settings-action="submitPhoneForm">수정 완료</button>
    </form>
  </div>
</div>

<!-- 3. 이메일 변경 팝업 -->
<div class="modal-overlay" id="modalEmail">
  <div class="modal-content">
    <div class="modal-header">
      <h3>이메일 변경</h3>
      <button type="button" class="modal-close" data-modal-close="modalEmail">&times;</button>
    </div>
    <form action="${pageContext.request.contextPath}/member/updateEmail" method="post" id="formEmail" data-validated-form>
      <input type="hidden" name="${_csrf.parameterName}" value="${_csrf.token}" />

      <div class="form-group" style="margin-bottom: 1rem;">
        <label for="memberEmail">새 이메일</label>
        <div class="input-with-btn" style="display: flex; gap: 8px; margin-top: 4px;">
          <input type="email" id="memberEmail" name="memberEmail" value="${member.memberEmail}" class="input-control" style="flex: 1;">
          <button type="button" class="button button--secondary" id="btn-check-email" data-settings-action="checkDuplicateEmail">중복확인</button>
        </div>
        <span class="error-msg" id="err-email" data-default="올바른 이메일 형식을 입력해 주세요. (예: example@domain.com)">올바른 이메일 형식을 입력해 주세요. (예: example@domain.com)</span>
      </div>
      <button type="button" id="btnEmail" class="button button--full" data-settings-action="submitEmailForm">수정 완료</button>
    </form>
  </div>
</div>

<!-- 4. 비밀번호 변경 팝업 -->
<div class="modal-overlay" id="modalPassword">
  <div class="modal-content">
    <div class="modal-header">
      <h3>비밀번호 변경</h3>
      <button type="button" class="modal-close" data-modal-close="modalPassword">&times;</button>
    </div>
    <form action="${pageContext.request.contextPath}/member/updatePasswordInSettings" method="post" id="formPassword" data-validated-form>
      <input type="hidden" name="${_csrf.parameterName}" value="${_csrf.token}" />

      <div class="form-group" style="margin-bottom: 0.5rem;">
        <label for="currentPassword">현재 비밀번호</label>
        <input type="password" id="currentPassword" name="currentPassword" class="input-control">
        <span class="error-msg" id="err-currentPw" data-default="현재 사용 중인 비밀번호를 입력해 주세요.">현재 사용 중인 비밀번호를 입력해 주세요.</span>
      </div>
      <div class="form-group" style="margin-bottom: 0.5rem;">
        <label for="newPassword">새 비밀번호</label>
        <input type="password" id="newPassword" name="newPassword" class="input-control">
        <span class="error-msg" id="err-newPw" data-default="영문, 숫자, 특수문자 포함 8자~20자">영문, 숫자, 특수문자 포함 8자~20자</span>
      </div>
      <div class="form-group" style="margin-bottom: 1rem;">
        <label for="confirmPassword">새 비밀번호 확인</label>
        <input type="password" id="confirmPassword" name="confirmPassword" class="input-control">
        <span class="error-msg" id="err-confirmPw" data-default="새 비밀번호를 한번 더 입력해 주세요.">새 비밀번호를 한번 더 입력해 주세요.</span>
      </div>
      <button type="button" id="btnPassword" class="button button--full" data-settings-action="submitPasswordForm">비밀번호 변경</button>
    </form>
  </div>
</div>

<!-- 5. 프로필 사진 변경 팝업 -->
<div class="modal-overlay" id="modalProfile">
  <div class="modal-content modal-content--center">
    <div class="modal-header">
      <h3>프로필 사진 변경</h3>
      <button type="button" class="modal-close" data-modal-close="modalProfile">&times;</button>
    </div>

    <form action="${pageContext.request.contextPath}/member/updateProfileImage" method="post" enctype="multipart/form-data" id="formProfile">
      <input type="hidden" name="${_csrf.parameterName}" value="${_csrf.token}" />
      <input type="hidden" name="deleteProfile" id="deleteProfile" value="false">

      <div class="profile-avatar modal-avatar-wrapper" id="modalAvatarPreview">
        <img id="modalAvatarImg"
             src="${not empty member.profileImage ? pageContext.request.contextPath.concat(member.profileImage) : pageContext.request.contextPath.concat('/uploads/profile/default-profile.svg')}"
             class="profile-img" alt="프로필 미리보기">
      </div>

      <div class="modal-actions-row">
        <input type="file" id="profile" name="profile" accept="image/*" hidden>
        <label for="profile" class="button button--secondary">새 사진 선택</label>
        <button type="button" id="modalResetAvatarBtn" class="button button--secondary">기본 이미지로 변경</button>
      </div>

      <button type="submit" class="button button--full">저장하기</button>
    </form>
  </div>
</div>

<!-- 6. 회원 삭제(Delete) 모달 팝업 -->
<div class="modal-overlay" id="modalDelete">
  <div class="modal-content">
    <div class="modal-header">
      <h3 style="color: #e53e3e;">계정 삭제</h3>
      <button type="button" class="modal-close" data-modal-close="modalDelete">&times;</button>
    </div>

    <form action="${pageContext.request.contextPath}/member/delete" method="post" id="formDelete" data-validated-form>
      <input type="hidden" name="${_csrf.parameterName}" value="${_csrf.token}" />

      <div class="settings-delete-note">
        <p style="font-size: 0.85rem; color: #c53030; font-weight: 600; margin-bottom: 0.5rem;">⚠️ 삭제 전 반드시 확인해 주세요</p>
        <ul style="font-size: 0.8rem; color: #4a5568; padding-left: 1.2rem; margin: 0; line-height: 1.5;">
          <li>계정 삭제 신청 후 30일간 보관되며, 이후 영구 삭제됩니다.</li>
          <li><b>작성하신 게시글 및 댓글은 계정을 삭제해도 자동으로 삭제되지 않습니다.</b></li>
          <li>삭제를 원하시는 게시물은 미리 직접 삭제해 주세요.</li>
        </ul>
      </div>

      <div class="settings-delete-agree">
        <label style="font-size: 0.85rem; cursor: pointer; display: flex; align-items: center; gap: 6px;">
          <input type="checkbox" id="agreeDelete" style="width: 16px; height: 16px;">
          <span>안내문을 확인했으며, 계정 삭제에 동의합니다.</span>
        </label>
        <span class="error-msg" id="err-agreeDelete"></span>
      </div>

      <div class="form-group" style="margin-bottom: 1.5rem; text-align: left;">
        <label for="deletePassword">현재 비밀번호 확인</label>
        <input type="password" id="deletePassword" name="password" class="input-control" placeholder="비밀번호를 입력하세요">
        <span class="error-msg" id="err-deletePw"></span>
      </div>

      <button type="button" class="button button--full" style="background: #e53e3e; color: #fff;" data-settings-action="submitDeleteForm">삭제 확정</button>
    </form>
  </div>
</div>

<script id="settingsScript" src="${ctx}/settings.js" data-context-path="${ctx}" defer></script>

<!-- 공통 Footer Include -->
<%@ include file="/WEB-INF/views/common/footer.jsp" %>
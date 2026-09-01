<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
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
                 src="${not empty member.profileImage ? pageContext.request.contextPath.concat(member.profileImage) : pageContext.request.contextPath.concat('/upload/profile/default-profile.svg')}"
                 class="profile-img" alt="프로필 사진">
          </div>
          <button type="button" class="button button--secondary" onclick="openModal('modalProfile')">사진 변경</button>
        </div>
      </section>

      <!-- 2. 계정 정보 리스트 카드 -->
      <section class="surface settings-card">
        <div class="settings-card__head"><h2 class="section-title">계정 정보</h2><span class="chip">SECURITY</span></div>

        <div class="setting-row">
          <div class="setting-info"><label>닉네임</label><p>${member.nickname}</p></div>
          <button type="button" class="button button--text" onclick="openModal('modalNickname')">변경</button>
        </div>

        <div class="setting-row">
          <div class="setting-info"><label>전화번호</label><p>${member.memberPhone}</p></div>
          <button type="button" class="button button--text" onclick="openModal('modalPhone')">변경</button>
        </div>

        <div class="setting-row">
          <div class="setting-info"><label>이메일</label><p>${member.memberEmail}</p></div>
          <button type="button" class="button button--text" onclick="openModal('modalEmail')">변경</button>
        </div>

        <div class="setting-row">
          <div class="setting-info"><label>비밀번호</label><p>••••••••</p></div>
          <button type="button" class="button button--text" onclick="openModal('modalPassword')">변경</button>
        </div>
      </section>

      <!-- 3. 계정 삭제(탈퇴) -->
      <div class="settings-danger"><p>더 이상 서비스를 이용하지 않는 경우 계정을 삭제할 수 있습니다.</p><a href="javascript:void(0);" onclick="openModal('modalDelete')">계정 삭제</a></div>
    </div>
  </main>

<!-- ==================== 팝업(모달) 영역들 ==================== -->

<!-- 1. 닉네임 변경 팝업 -->
<div class="modal-overlay" id="modalNickname">
  <div class="modal-content">
    <div class="modal-header">
      <h3>닉네임 변경</h3>
      <button type="button" class="modal-close" onclick="closeModal('modalNickname')">&times;</button>
    </div>
    <form action="${pageContext.request.contextPath}/member/updateNickname" method="post" id="formNickname" onsubmit="return false;">
      <input type="hidden" name="${_csrf.parameterName}" value="${_csrf.token}" />

      <div class="form-group" style="margin-bottom: 1rem;">
        <label for="nickname">새 닉네임</label>
        <div class="input-with-btn" style="display: flex; gap: 8px; margin-top: 4px;">
          <input type="text" id="nickname" name="nickname" value="${member.nickname}" class="input-control" style="flex: 1;">
          <button type="button" class="button button--secondary" id="btn-check-nickname" onclick="checkDuplicateNickname()">중복확인</button>
        </div>
        <span class="error-msg" id="err-nickname" data-default="공백 없이 2자 이상 10자 이하로 입력해 주세요.">공백 없이 2자 이상 10자 이하로 입력해 주세요.</span>
      </div>
      <button type="button" class="button button--full" onclick="submitNicknameForm()">수정 완료</button>
    </form>
  </div>
</div>

<!-- 2. 전화번호 변경 팝업 -->
<div class="modal-overlay" id="modalPhone">
  <div class="modal-content">
    <div class="modal-header">
      <h3>전화번호 변경</h3>
      <button type="button" class="modal-close" onclick="closeModal('modalPhone')">&times;</button>
    </div>
    <form action="${pageContext.request.contextPath}/member/updatePhone" method="post" id="formPhone" onsubmit="return false;">
      <input type="hidden" name="${_csrf.parameterName}" value="${_csrf.token}" />

      <div class="form-group" style="margin-bottom: 1rem;">
        <label for="memberPhone">새 전화번호</label>
        <input type="tel" id="memberPhone" name="memberPhone" value="${member.memberPhone}" maxlength="11" class="input-control">
        <span class="error-msg" id="err-phone" data-default="숫자만 입력해 주세요. (예: 01012345678)">숫자만 입력해 주세요. (예: 01012345678)</span>
      </div>
      <button type="button" id="btnPhone" class="button button--full" onclick="submitPhoneForm()">수정 완료</button>
    </form>
  </div>
</div>

<!-- 3. 이메일 변경 팝업 -->
<div class="modal-overlay" id="modalEmail">
  <div class="modal-content">
    <div class="modal-header">
      <h3>이메일 변경</h3>
      <button type="button" class="modal-close" onclick="closeModal('modalEmail')">&times;</button>
    </div>
    <form action="${pageContext.request.contextPath}/member/updateEmail" method="post" id="formEmail" onsubmit="return false;">
      <input type="hidden" name="${_csrf.parameterName}" value="${_csrf.token}" />

      <div class="form-group" style="margin-bottom: 1rem;">
        <label for="memberEmail">새 이메일</label>
        <div class="input-with-btn" style="display: flex; gap: 8px; margin-top: 4px;">
          <input type="email" id="memberEmail" name="memberEmail" value="${member.memberEmail}" class="input-control" style="flex: 1;">
          <button type="button" class="button button--secondary" id="btn-check-email" onclick="checkDuplicateEmail()">중복확인</button>
        </div>
        <span class="error-msg" id="err-email" data-default="올바른 이메일 형식을 입력해 주세요. (예: example@domain.com)">올바른 이메일 형식을 입력해 주세요. (예: example@domain.com)</span>
      </div>
      <button type="button" id="btnEmail" class="button button--full" onclick="submitEmailForm()">수정 완료</button>
    </form>
  </div>
</div>

<!-- 4. 비밀번호 변경 팝업 -->
<div class="modal-overlay" id="modalPassword">
  <div class="modal-content">
    <div class="modal-header">
      <h3>비밀번호 변경</h3>
      <button type="button" class="modal-close" onclick="closeModal('modalPassword')">&times;</button>
    </div>
    <form action="${pageContext.request.contextPath}/member/updatePasswordInSettings" method="post" id="formPassword" onsubmit="return false;">
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
      <button type="button" id="btnPassword" class="button button--full" onclick="submitPasswordForm()">비밀번호 변경</button>
    </form>
  </div>
</div>

<!-- 5. 프로필 사진 변경 팝업 -->
<div class="modal-overlay" id="modalProfile">
  <div class="modal-content modal-content--center">
    <div class="modal-header">
      <h3>프로필 사진 변경</h3>
      <button type="button" class="modal-close" onclick="closeModal('modalProfile')">&times;</button>
    </div>

    <form action="${pageContext.request.contextPath}/member/updateProfileImage" method="post" enctype="multipart/form-data" id="formProfile">
      <input type="hidden" name="${_csrf.parameterName}" value="${_csrf.token}" />
      <input type="hidden" name="deleteProfile" id="deleteProfile" value="false">

      <div class="profile-avatar modal-avatar-wrapper" id="modalAvatarPreview">
        <img id="modalAvatarImg"
             src="${not empty member.profileImage ? pageContext.request.contextPath.concat(member.profileImage) : pageContext.request.contextPath.concat('/upload/profile/default-profile.svg')}"
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
      <button type="button" class="modal-close" onclick="closeModal('modalDelete')">&times;</button>
    </div>

    <form action="${pageContext.request.contextPath}/member/delete" method="post" id="formDelete" onsubmit="return false;">
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

      <button type="button" class="button button--full" style="background: #e53e3e; color: #fff;" onclick="submitDeleteForm()">삭제 확정</button>
    </form>
  </div>
</div>

<script>
  const DEFAULT_IMAGE_SRC = "${pageContext.request.contextPath}/upload/profile/default-profile.svg";
  const currentProfileImgSrc = "${not empty member.profileImage ? pageContext.request.contextPath.concat(member.profileImage) : pageContext.request.contextPath.concat('/upload/profile/default-profile.svg')}";

  function openModal(id) {
    const modal = document.getElementById(id);
    if (modal) modal.classList.add('is-active');
  }

  function closeModal(id) {
    const modal = document.getElementById(id);
    if (!modal) return;
    modal.classList.remove('is-active');
    if (id === 'modalProfile') cancelProfileChange();
  }

  function cancelProfileChange() {
    const modalProfileInput = document.getElementById('profile');
    const deleteProfileInput = document.getElementById('deleteProfile');
    const modalAvatarImg = document.getElementById('modalAvatarImg');
    const mainAvatarImg = document.getElementById('mainAvatarImg');

    if (modalProfileInput) modalProfileInput.value = "";
    if (deleteProfileInput) deleteProfileInput.value = "false";
    if (modalAvatarImg) modalAvatarImg.src = currentProfileImgSrc;
    if (mainAvatarImg) mainAvatarImg.src = currentProfileImgSrc;
  }

  document.addEventListener('DOMContentLoaded', function() {
    window.addEventListener('click', function(e) {
      if (e.target.classList.contains('modal-overlay')) {
        closeModal(e.target.id);
      }
    });

    const modalProfileInput = document.getElementById('profile');
    if (modalProfileInput) {
      modalProfileInput.addEventListener('change', function(e) {
        const file = e.target.files[0];
        if (!file) return;

        document.getElementById('deleteProfile').value = "false";
        const reader = new FileReader();
        reader.onload = function(event) {
          const base64Src = event.target.result;
          const modalAvatarImg = document.getElementById('modalAvatarImg');
          const mainAvatarImg = document.getElementById('mainAvatarImg');

          if (modalAvatarImg) modalAvatarImg.src = base64Src;
          if (mainAvatarImg) mainAvatarImg.src = base64Src;
        };
        reader.readAsDataURL(file);
      });
    }

    const modalResetBtn = document.getElementById('modalResetAvatarBtn');
    if (modalResetBtn) {
      modalResetBtn.addEventListener('click', function() {
        const modalProfileInput = document.getElementById('profile');
        const deleteProfileInput = document.getElementById('deleteProfile');
        const modalAvatarImg = document.getElementById('modalAvatarImg');
        const mainAvatarImg = document.getElementById('mainAvatarImg');

        if (modalProfileInput) modalProfileInput.value = "";
        if (deleteProfileInput) deleteProfileInput.value = "true";

        if (modalAvatarImg) modalAvatarImg.src = DEFAULT_IMAGE_SRC;
        if (mainAvatarImg) mainAvatarImg.src = DEFAULT_IMAGE_SRC;
      });
    }
  });

  function showError(inputElem, errElem, message) {
    if (errElem) {
      errElem.innerText = message;
      errElem.classList.remove('success-msg');
      errElem.classList.add('has-error');
    }
  }

  function showSuccess(inputElem, errElem, message) {
    if (errElem) {
      errElem.innerText = message;
      errElem.classList.remove('has-error');
      errElem.classList.add('success-msg');
    }
  }

  function resetGuide(errElem) {
    if (errElem) {
      const defaultMsg = errElem.getAttribute('data-default') || '';
      errElem.innerText = defaultMsg;
      errElem.classList.remove('has-error', 'success-msg');
    }
  }

  function checkField(inputElem, errElem, validateFn) {
    const msg = validateFn(inputElem.value);
    if (msg) {
      showError(inputElem, errElem, msg);
      return false;
    } else {
      resetGuide(errElem);
      return true;
    }
  }

  const currentNickname = "${member.nickname}";
  const currentPhone = "${member.memberPhone}";
  const currentEmail = "${member.memberEmail}";

  let isNicknameChecked = true;

  function validateNickname(val) {
    if (!val || val.trim() === '') return '닉네임을 입력해 주세요.';
    if (/\s/.test(val)) return '공백(띄어쓰기)을 포함할 수 없습니다.';
    if (val.length < 2 || val.length > 10) return '닉네임은 2자 이상 10자 이하로 입력해 주세요.';
    return '';
  }

  function validatePhone(phoneValue) {
    if (!phoneValue || phoneValue.trim() === '') return '휴대전화번호를 입력해 주세요.';
    if (/\s/.test(phoneValue)) return '휴대전화번호에는 공백(띄어쓰기)을 포함할 수 없습니다.';
    const phonePattern = /^010-?\d{4}-?\d{4}$/;
    if (!phonePattern.test(phoneValue)) {
      return '올바른 휴대전화번호 형식이 아닙니다. (예: 01012345678)';
    }
    return '';
  }

  function validateEmail(val) {
    if (!val || val.trim() === '') return '이메일을 입력해 주세요.';
    if (/\s/.test(val)) return '공백(띄어쓰기)을 포함할 수 없습니다.';
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(val)) return '올바른 이메일 형식이 아닙니다.';
    return '';
  }

  function validatePassword(val) {
    if (!val || val.trim() === '') return '비밀번호를 입력해 주세요.';
    if (/\s/.test(val)) return '공백(띄어쓰기)을 포함할 수 없습니다.';
    if (val.length < 8 || val.length > 20) return '비밀번호는 8자 이상 20자 이하로 입력해 주세요.';
    const hasLetter = /[a-zA-Z]/.test(val);
    const hasNumber = /[0-9]/.test(val);
    const hasSpecial = /[!@#$%^&*]/.test(val);
    if (!hasLetter || !hasNumber || !hasSpecial) return '영문, 숫자, 특수문자를 모두 포함해야 합니다.';
    return '';
  }

  function checkDuplicateNickname() {
    const nicknameInput = document.getElementById('nickname');
    const errNickname = document.getElementById('err-nickname');
    const nicknameValue = nicknameInput.value.trim();

    if (nicknameValue === currentNickname) {
      showSuccess(nicknameInput, errNickname, '현재 사용 중인 본인의 닉네임입니다.');
      isNicknameChecked = true;
      return;
    }

    if (!checkField(nicknameInput, errNickname, validateNickname)) {
      isNicknameChecked = false;
      return;
    }

    fetch('${pageContext.request.contextPath}/api/member/check-nickname?nickname=' + encodeURIComponent(nicknameValue))
            .then(response => {
              if (!response.ok) throw new Error('서버 응답 오류');
              return response.json();
            })
            .then(isDuplicate => {
              if (isDuplicate) {
                showError(nicknameInput, errNickname, '이미 사용 중인 닉네임입니다.');
                isNicknameChecked = false;
              } else {
                showSuccess(nicknameInput, errNickname, '사용 가능한 닉네임입니다.');
                isNicknameChecked = true;
              }
            })
            .catch(error => {
              console.error('Error:', error);
              showError(nicknameInput, errNickname, '중복 확인 중 오류가 발생했습니다.');
              isNicknameChecked = false;
            });
  }

  document.getElementById('nickname').addEventListener('input', function() {
    const val = this.value.trim();
    const errNickname = document.getElementById('err-nickname');
    if (val === currentNickname) {
      isNicknameChecked = true;
      showSuccess(this, errNickname, '현재 사용 중인 본인의 닉네임입니다.');
    } else {
      isNicknameChecked = false;
      checkField(this, errNickname, validateNickname);
    }
  });

  function submitNicknameForm() {
    const nicknameInput = document.getElementById('nickname');
    const errNickname = document.getElementById('err-nickname');
    const nicknameValue = nicknameInput.value.trim();

    if (nicknameValue === currentNickname) {
      showError(nicknameInput, errNickname, '현재 사용 중인 닉네임과 동일합니다.');
      nicknameInput.focus();
      return;
    }

    let isNicknameValid = checkField(nicknameInput, errNickname, validateNickname);
    if (isNicknameValid && !isNicknameChecked) {
      showError(nicknameInput, errNickname, '닉네임 중복확인을 진행해 주세요.');
      isNicknameValid = false;
    }

    if (isNicknameValid) {
      nicknameInput.value = nicknameValue;
      document.getElementById('formNickname').submit();
    } else {
      nicknameInput.focus();
    }
  }

  const phoneInput = document.getElementById('memberPhone');
  const errPhone = document.getElementById('err-phone');

  phoneInput.addEventListener('input', function() {
    this.value = this.value.replace(/[^0-9-]/g, '');
    const val = this.value.trim();

    if (val === currentPhone) {
      showSuccess(this, errPhone, '현재 사용 중인 전화번호입니다.');
    } else {
      checkField(this, errPhone, validatePhone);
    }
  });

  function submitPhoneForm() {
    const phoneInput = document.getElementById('memberPhone');
    const errPhone = document.getElementById('err-phone');
    const phoneValue = phoneInput.value.trim();

    if (phoneValue === currentPhone) {
      showError(phoneInput, errPhone, '현재 사용 중인 전화번호와 동일합니다.');
      phoneInput.focus();
      return;
    }

    if (checkField(phoneInput, errPhone, validatePhone)) {
      phoneInput.value = phoneValue;
      document.getElementById('formPhone').submit();
    } else {
      phoneInput.focus();
    }
  }

  const emailInput = document.getElementById('memberEmail');
  const errEmail = document.getElementById('err-email');
  let isEmailChecked = true;

  function checkDuplicateEmail() {
    const emailValue = emailInput.value.trim();

    if (emailValue === currentEmail) {
      showSuccess(emailInput, errEmail, '현재 사용 중인 본인의 이메일입니다.');
      isEmailChecked = true;
      return;
    }

    if (!checkField(emailInput, errEmail, validateEmail)) {
      isEmailChecked = false;
      return;
    }

    fetch('${pageContext.request.contextPath}/api/member/check-email?memberEmail=' + encodeURIComponent(emailValue))
            .then(response => {
              if (!response.ok) throw new Error('서버 응답 오류');
              return response.json();
            })
            .then(isDuplicate => {
              if (isDuplicate) {
                showError(emailInput, errEmail, '이미 사용 중인 이메일입니다.');
                isEmailChecked = false;
              } else {
                showSuccess(emailInput, errEmail, '사용 가능한 이메일입니다.');
                isEmailChecked = true;
              }
            })
            .catch(error => {
              console.error('Error:', error);
              showError(emailInput, errEmail, '중복 확인 중 오류가 발생했습니다.');
              isEmailChecked = false;
            });
  }

  emailInput.addEventListener('input', function() {
    const val = this.value.trim();

    if (val === currentEmail) {
      isEmailChecked = true;
      showSuccess(this, errEmail, '현재 사용 중인 본인의 이메일입니다.');
    } else {
      isEmailChecked = false;
      checkField(this, errEmail, validateEmail);
    }
  });

  function submitEmailForm() {
    const emailValue = emailInput.value.trim();

    if (emailValue === currentEmail) {
      showError(emailInput, errEmail, '현재 사용 중인 이메일과 동일합니다.');
      emailInput.focus();
      return;
    }

    let isEmailValid = checkField(emailInput, errEmail, validateEmail);

    if (isEmailValid && !isEmailChecked) {
      showError(emailInput, errEmail, '이메일 중복확인을 진행해 주세요.');
      isEmailValid = false;
    }

    if (isEmailValid) {
      emailInput.value = emailValue;
      document.getElementById('formEmail').submit();
    } else {
      emailInput.focus();
    }
  }

  const curPw = document.getElementById('currentPassword');
  const newPw = document.getElementById('newPassword');
  const confirmPw = document.getElementById('confirmPassword');

  const errCur = document.getElementById('err-currentPw');
  const errNew = document.getElementById('err-newPw');
  const errConfirm = document.getElementById('err-confirmPw');

  curPw.addEventListener('input', function() {
    const curVal = this.value;
    const newVal = newPw.value;

    if (!curVal || curVal.trim() === '') {
      showError(this, errCur, '현재 비밀번호를 입력해 주세요.');
    } else {
      resetGuide(errCur);
    }

    if (newVal && curVal && newVal === curVal) {
      showError(newPw, errNew, '현재 비밀번호와 동일한 비밀번호는 사용할 수 없습니다.');
    } else if (newVal) {
      checkField(newPw, errNew, validatePassword);
    }
  });

  newPw.addEventListener('input', function() {
    const newVal = this.value;
    const curVal = curPw.value;

    if (newVal && curVal && newVal === curVal) {
      showError(this, errNew, '현재 비밀번호와 동일한 비밀번호는 사용할 수 없습니다.');
    } else {
      checkField(this, errNew, validatePassword);
    }

    if (confirmPw.value) {
      if (confirmPw.value !== newVal) {
        showError(confirmPw, errConfirm, '새 비밀번호가 일치하지 않습니다.');
      } else {
        showSuccess(confirmPw, errConfirm, '비밀번호가 일치합니다.');
      }
    }
  });

  confirmPw.addEventListener('input', function() {
    if (this.value !== newPw.value) {
      showError(this, errConfirm, '새 비밀번호가 일치하지 않습니다.');
    } else {
      showSuccess(this, errConfirm, '비밀번호가 일치합니다.');
    }
  });

  function submitPasswordForm() {
    const curVal = curPw.value;
    const newVal = newPw.value;
    const confirmVal = confirmPw.value;

    let isValid = true;

    if (!curVal || curVal.trim() === '') {
      showError(curPw, errCur, '현재 비밀번호를 입력해 주세요.');
      isValid = false;
    }

    if (!checkField(newPw, errNew, validatePassword)) {
      isValid = false;
    } else if (newVal === curVal) {
      showError(newPw, errNew, '현재 비밀번호와 동일한 비밀번호는 사용할 수 없습니다.');
      isValid = false;
    }

    if (confirmVal !== newVal) {
      showError(confirmPw, errConfirm, '새 비밀번호가 일치하지 않습니다.');
      isValid = false;
    }

    if (isValid) {
      document.getElementById('formPassword').submit();
    }
  }

  document.addEventListener('keydown', function(event) {
    if (event.key === 'Enter') {
      const target = event.target;

      if (target.id === 'nickname') {
        event.preventDefault();
        if (isNicknameChecked) submitNicknameForm();
        else checkDuplicateNickname();
      }
      else if (target.id === 'memberPhone') {
        event.preventDefault();
        submitPhoneForm();
      }
      else if (target.id === 'memberEmail') {
        event.preventDefault();
        if (isEmailChecked) submitEmailForm();
        else checkDuplicateEmail();
      }
      else if (target.id === 'currentPassword') {
        event.preventDefault();
        newPw.focus();
      }
      else if (target.id === 'newPassword') {
        event.preventDefault();
        confirmPw.focus();
      }
      else if (target.id === 'confirmPassword') {
        event.preventDefault();
        submitPasswordForm();
      }
    }
  });

  function submitDeleteForm() {
    const agreeCheck = document.getElementById('agreeDelete');
    const deletePw = document.getElementById('deletePassword');
    const errAgree = document.getElementById('err-agreeDelete');
    const errPw = document.getElementById('err-deletePw');

    let isValid = true;

    if (!agreeCheck.checked) {
      showError(null, errAgree, '안내문 확인 동의에 체크해 주세요.');
      isValid = false;
    } else {
      resetGuide(errAgree);
    }

    if (!deletePw.value || deletePw.value.trim() === '') {
      showError(deletePw, errPw, '현재 비밀번호를 입력해 주세요.');
      isValid = false;
    } else {
      resetGuide(errPw);
    }

    if (isValid) {
      if (confirm('정말로 계정을 삭제하시겠습니까? 30일간 보관 후 영구 삭제됩니다.')) {
        document.getElementById('formDelete').submit();
      }
    }
  }
</script>

<!-- 공통 Footer Include -->
<%@ include file="/WEB-INF/views/common/footer.jsp" %>
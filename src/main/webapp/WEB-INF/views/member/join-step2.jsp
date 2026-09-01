<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>

<c:set var="ctx" value="${pageContext.request.contextPath}" scope="request" />

<!-- 프로필 이미지 업로드 섹션 -->
<div class="form-group profile-group">
  <label>프로필 이미지</label>
  <div class="profile-section">
    <!-- 프로필 이미지 미리보기 -->
    <div class="profile-img-preview" id="image-preview">
      <img id="preview-img"
           src="${ctx}/upload/profile/default-profile.svg"
           alt="프로필 미리보기">
    </div>

    <!-- 숨김 파일 Input -->
    <input type="file" id="profile-file" name="profile" accept="image/*" onchange="previewImage(this)">

    <!-- 프로필 사진 삭제 여부를 서버로 보낼 hidden input (필요시 사용) -->
    <input type="hidden" name="deleteProfile" id="deleteProfile" value="false">

    <!-- 선택 / 기본 이미지 버튼 그룹 -->
    <div class="profile-btn-row">
      <label for="profile-file" class="btn-secondary">새 사진 선택</label>
      <button type="button" class="btn-secondary" id="btn-reset-profile" onclick="resetDefaultImage()">기본 이미지로 변경</button>
    </div>
  </div>
</div>

<!-- 닉네임 입력 및 중복 확인 -->
<div class="form-group">
  <label for="nickname">닉네임</label>
  <div class="input-with-btn">
    <input type="text" id="nickname" name="nickname" placeholder="닉네임을 입력해주세요 (2~10자)">
    <button type="button" class="btn-check" id="btn-check-nickname" onclick="checkDuplicateNickname()">중복확인</button>
  </div>
  <span class="error-msg" id="err-nickname"></span>
</div>

<!-- 제출 버튼 -->
<div class="btn-container">
  <button type="button" class="btn" onclick="submitForm()">가입완료</button>
</div>

<script>
  let isNicknameChecked = false;

  // 기본 프로필 경로 설정
  const DEFAULT_PROFILE_URL = "${ctx}/upload/profile/default-profile.svg";

  // 프로필 이미지 미리보기 함수 (완전 수정본)
  function previewImage(input) {
    const previewImg = document.getElementById('preview-img');
    const deleteInput = document.getElementById('deleteProfile');

    // 선택된 파일이 존재할 때만 실행
    if (input && input.files && input.files[0]) {
      const file = input.files[0];

      // 이미지 파일인지 1차 검증
      if (!file.type.startsWith('image/')) {
        alert('이미지 파일만 선택 가능합니다.');
        input.value = '';
        return;
      }

      const reader = new FileReader();

      // 파일 읽기가 완료된 후에 src를 교체하도록 안전하게 작성
      reader.onload = function(e) {
        if (previewImg && e.target && e.target.result) {
          previewImg.src = e.target.result;
        }
      };

      // DataURL 형태로 파일 읽기 시작
      reader.readAsDataURL(file);

      if (deleteInput) {
        deleteInput.value = "false";
      }
    }
  }

  // 기본 이미지로 변경 함수
  function resetDefaultImage() {
    const fileInput = document.getElementById('profile-file');
    const previewImg = document.getElementById('preview-img');
    const deleteInput = document.getElementById('deleteProfile');

    fileInput.value = ''; // file input 값 초기화
    previewImg.src = DEFAULT_PROFILE_URL; // 기본 이미지로 교체
    if (deleteInput) deleteInput.value = "true";
  }

  // 닉네임 유효성 검사 규칙
  function validateNickname(nicknameValue) {
    if (!nicknameValue || nicknameValue.trim() === '') return '닉네임을 입력해 주세요.';
    if (/\s/.test(nicknameValue)) return '닉네임에는 공백(띄어쓰기)을 포함할 수 없습니다.';
    if (nicknameValue.length < 2 || nicknameValue.length > 10) return '닉네임은 2자 이상 10자 이하로 입력해 주세요.';
    return '';
  }

  // 닉네임 중복 확인 (Ajax)
  function checkDuplicateNickname() {
    const nicknameInput = document.getElementById('nickname');
    const errNickname = document.getElementById('err-nickname');
    const nicknameValue = nicknameInput.value;

    const msg = validateNickname(nicknameValue);
    if (msg) {
      showError(nicknameInput, errNickname, msg);
      isNicknameChecked = false;
      return;
    }

    fetch('${ctx}/api/member/check-nickname?nickname=' + encodeURIComponent(nicknameValue))
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

  // 닉네임 수정 시 인증 상태 초기화
  document.getElementById('nickname').addEventListener('input', function() {
    isNicknameChecked = false;
    clearError(this, document.getElementById('err-nickname'));
  });

  // 최종 가입 Submit
  function submitForm() {
    const nicknameInput = document.getElementById('nickname');
    const errNickname = document.getElementById('err-nickname');

    const isNicknameValid = checkField(nicknameInput, errNickname, validateNickname);

    if (!isNicknameValid) {
      nicknameInput.focus();
      return;
    }

    if (!isNicknameChecked) {
      showError(nicknameInput, errNickname, '닉네임 중복확인을 진행해 주세요.');
      nicknameInput.focus();
      return;
    }

    // 전체 유효성 검사 통과 시 서브밋
    document.getElementById('joinForm').submit();
  }
</script>
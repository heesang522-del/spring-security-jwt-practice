(function () {
  'use strict';
  const contextPath = document.getElementById('settingsScript').dataset.contextPath;
  const DEFAULT_IMAGE_SRC = contextPath + '/uploads/profile/default-profile.svg';
  const currentProfileImgSrc = document.getElementById('mainAvatarImg').getAttribute('src');

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

  const currentNickname = document.getElementById('nickname').defaultValue;
  const currentPhone = document.getElementById('memberPhone').defaultValue;
  const currentEmail = document.getElementById('memberEmail').defaultValue;

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

    fetch(contextPath + '/api/member/check-nickname?nickname=' + encodeURIComponent(nicknameValue))
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

    fetch(contextPath + '/api/member/check-email?memberEmail=' + encodeURIComponent(emailValue))
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

  const actions = {
    checkDuplicateNickname,
    checkDuplicateEmail,
    submitNicknameForm,
    submitPhoneForm,
    submitEmailForm,
    submitPasswordForm,
    submitDeleteForm
  };

  document.querySelectorAll('[data-modal-open]').forEach(button => {
    button.addEventListener('click', event => {
      event.preventDefault();
      openModal(button.dataset.modalOpen);
    });
  });
  document.querySelectorAll('[data-modal-close]').forEach(button => {
    button.addEventListener('click', () => closeModal(button.dataset.modalClose));
  });
  document.querySelectorAll('[data-settings-action]').forEach(button => {
    button.addEventListener('click', actions[button.dataset.settingsAction]);
  });
  document.querySelectorAll('[data-validated-form]').forEach(form => {
    form.addEventListener('submit', event => event.preventDefault());
  });
})();

<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>회원가입</title>
  <meta name="description" content="Youwin 음악 커뮤니티 회원가입">
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
      <p class="auth-aside__eyebrow">Create your profile</p>
      <h2>나의 취향으로<br>새로운 연결을 시작해요</h2>
      <p class="auth-aside__description">간단한 정보와 프로필을 등록하면 취향에 맞는 채팅방과 커뮤니티를 만날 수 있어요.</p>
    </div>
    <p class="auth-aside__note">안전한 커뮤니티를 위해 이메일 인증을 진행합니다.</p>
  </aside>

  <main class="auth-main">
    <section class="auth-card join-container" aria-labelledby="pageTitle">
      <a class="auth-back" href="${pageContext.request.contextPath}/auth/login">← 로그인으로 돌아가기</a>
      <div class="join-progress" id="joinProgress" aria-label="가입 진행 단계">
        <span></span><span></span><span class="join-progress__label" id="progressLabel">1 / 2</span>
      </div>
      <div class="auth-heading">
        <p class="auth-heading__eyebrow">Join Youwin</p>
        <h1 class="join-title" id="pageTitle">회원 정보</h1>
        <p class="auth-description" id="stepDescription">로그인과 본인 확인에 사용할 정보를 입력해 주세요.</p>
      </div>

  <form id="joinForm" action="/member/join" method="post" enctype="multipart/form-data" class="join-form" onsubmit="return false;">

    <!-- Step 1: 회원 정보 -->
    <div id="step1" class="form-step">

      <div class="form-group">
        <label for="member-id">아이디</label>
        <div class="input-with-btn">
          <input type="text" id="member-id" name="memberId" placeholder="영문 시작, 영문+숫자 4~16자">
          <button type="button" class="btn-check" id="btn-check-id" onclick="checkDuplicateId()">중복확인</button>
        </div>
        <span class="error-msg" id="err-id"></span>
      </div>

      <div class="form-group">
        <label for="member-password">비밀번호</label>
        <input type="password" id="member-password" name="memberPassword" placeholder="8~20자, 특수문자 포함 3가지 이상 조합">
        <span class="error-msg" id="err-password"></span>
      </div>

      <div class="form-group">
        <label for="member-name">이름</label>
        <input type="text" id="member-name" name="memberName" placeholder="이름">
        <span class="error-msg" id="err-name"></span>
      </div>

      <!-- 이메일 및 인증번호 발송 -->
      <div class="form-group">
        <label for="member-email">이메일</label>
        <div class="input-with-btn">
          <input type="email" id="member-email" name="memberEmail" placeholder="이메일">
          <button type="button" class="btn-check" id="btn-send-code" onclick="sendAuthCode()">인증 요청</button>
        </div>
        <span class="error-msg" id="err-email"></span>
      </div>

      <!-- 인증번호 입력란 (기본 hidden 처리) -->
      <div class="form-group hidden" id="auth-code-group">
        <label for="auth-code">인증번호</label>
        <div class="input-with-btn">
          <input type="text" id="auth-code" maxlength="6" placeholder="인증번호 6자리">
          <span class="timer-text" id="timer">05:00</span>
          <button type="button" class="btn-check" id="btn-verify-code" onclick="verifyAuthCode()">확인</button>
        </div>
        <span class="error-msg" id="err-auth-code"></span>
      </div>

      <div class="form-group">
        <label for="member-phone">휴대전화번호</label>
        <input type="tel" id="member-phone" name="memberPhone" maxlength="11" placeholder="숫자만 입력 (예: 01012345678)">
        <span class="error-msg" id="err-phone"></span>
      </div>

      <div class="btn-container">
        <button type="button" class="btn" onclick="goToNextStep()">다음</button>
      </div>
    </div>

    <!-- Step 2: 회원 설정 -->
    <div id="step2" class="form-step hidden">
      <jsp:include page="join-step2.jsp" />
    </div>

  </form>
    </section>
  </main>
</div>

<script>
  let isIdChecked = false;
  let isEmailVerified = false; // 이메일 최종 인증 성공 여부
  let timerInterval = null;

  // 공통 메시지 표시 함수
  function showError(inputElem, errElem, message) {
    inputElem.classList.remove('input-success');
    inputElem.classList.add('input-error');
    errElem.classList.remove('success-msg');
    errElem.innerText = message;
    errElem.classList.add('show');
  }

  function showSuccess(inputElem, errElem, message) {
    inputElem.classList.remove('input-error');
    inputElem.classList.add('input-success');
    errElem.classList.add('success-msg');
    errElem.innerText = message;
    errElem.classList.add('show');
  }

  function clearError(inputElem, errElem) {
    inputElem.classList.remove('input-error', 'input-success');
    errElem.innerText = '';
    errElem.classList.remove('show', 'success-msg');
  }

  // 입력 요소 1개를 검사하고 화면 에러 처리를 전담하는 헬퍼 함수
  function checkField(inputElem, errElem, validateFn) {
    const msg = validateFn(inputElem.value);
    if (msg) {
      showError(inputElem, errElem, msg);
      return false;
    } else {
      clearError(inputElem, errElem);
      return true;
    }
  }

  // 유효성 검사 규칙들
  function validateId(idValue) {
    if (!idValue || idValue.trim() === '') return '아이디를 입력해 주세요.';
    if (/\s/.test(idValue)) return '아이디에는 공백(띄어쓰기)을 포함할 수 없습니다.';
    if (!/^[a-zA-Z]/.test(idValue)) return '첫 글자는 영문이어야 합니다.';
    if (!/^[a-zA-Z0-9]{4,16}$/.test(idValue)) return '영문과 숫자로만 4~16자로 입력해 주세요.';
    if (!/[a-zA-Z]/.test(idValue) || !/[0-9]/.test(idValue)) return '영문과 숫자를 모두 포함해야 합니다.';
    return '';
  }

  function validatePassword(pwValue) {
    if (!pwValue || pwValue.trim() === '') return '비밀번호를 입력해 주세요.';
    if (/\s/.test(pwValue)) return '비밀번호에는 공백(띄어쓰기)을 포함할 수 없습니다.';
    if (pwValue.length < 8 || pwValue.length > 20) return '비밀번호는 8자 이상 20자 이하로 입력해 주세요.';

    const hasLetter = /[a-zA-Z]/.test(pwValue);
    const hasNumber = /[0-9]/.test(pwValue);
    const hasSpecial = /[!@#$%^&*]/.test(pwValue);

    if (!hasLetter || !hasNumber || !hasSpecial) {
      return '영문, 숫자, 특수문자(!@#$%^&*)를 모두 포함해야 합니다.';
    }
    return '';
  }

  function validateName(nameValue) {
    if (!nameValue || nameValue.trim() === '') return '이름을 입력해 주세요.';
    if (/\s/.test(nameValue)) return '이름에는 공백(띄어쓰기)을 포함할 수 없습니다.';
    if (nameValue.length < 2 || nameValue.length > 20) return '이름은 2자 이상 20자 이하로 입력해 주세요.';
    return '';
  }

  function validateEmail(emailValue) {
    if (!emailValue || emailValue.trim() === '') return '이메일을 입력해 주세요.';
    if (/\s/.test(emailValue)) return '이메일에는 공백(띄어쓰기)을 포함할 수 없습니다.';
    const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailPattern.test(emailValue)) return '올바른 이메일 형식이 아닙니다.';
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

  // 아이디 중복 체크 (Ajax)
  function checkDuplicateId() {
    const idInput = document.getElementById('member-id');
    const errId = document.getElementById('err-id');
    const idValue = idInput.value;

    const msg = validateId(idValue);
    if (msg) {
      showError(idInput, errId, msg);
      isIdChecked = false;
      return;
    }

    fetch('/api/member/check-id?memberId=' + encodeURIComponent(idValue))
            .then(response => {
              if (!response.ok) throw new Error('서버 응답 오류');
              return response.json();
            })
            .then(isDuplicate => {
              if (isDuplicate) {
                showError(idInput, errId, '이미 사용 중인 아이디입니다.');
                isIdChecked = false;
              } else {
                showSuccess(idInput, errId, '사용 가능한 아이디입니다.');
                isIdChecked = true;
              }
            })
            .catch(error => {
              console.error('Error:', error);
              showError(idInput, errId, '중복 확인 중 오류가 발생했습니다.');
              isIdChecked = false;
            });
  }

  // [이메일 관련] 1. 인증번호 발송 요청
  function sendAuthCode() {
    const emailInput = document.getElementById('member-email');
    const errEmail = document.getElementById('err-email');
    const emailVal = emailInput.value;

    const msg = validateEmail(emailVal);
    if (msg) {
      showError(emailInput, errEmail, msg);
      return;
    }

    fetch('/api/member/check-email?memberEmail=' + encodeURIComponent(emailVal))
            .then(res => res.json())
            .then(isDuplicate => {
              if (isDuplicate) {
                showError(emailInput, errEmail, '이미 가입된 이메일입니다.');
              } else {
                showSuccess(emailInput, errEmail, '인증번호 발송 중...');

                fetch('/api/email/send-code', {
                  method: 'POST',
                  headers: { 'Content-Type': 'application/json' },
                  body: JSON.stringify({ memberEmail: emailVal })
                })
                        .then(res => res.json())
                        .then(data => {
                          if (data.success) {
                            showSuccess(emailInput, errEmail, '인증번호가 발송되었습니다.');
                            document.getElementById('auth-code-group').classList.remove('hidden');
                            document.getElementById('auth-code').focus(); // 발송 성공 시 인증번호 입력창으로 포커스
                            startTimer(300); // 5분 타이머
                          } else {
                            showError(emailInput, errEmail, data.message);
                          }
                        });
              }
            });
  }

  // [이메일 관련] 2. 인증번호 대조 확인
  function verifyAuthCode() {
    const emailVal = document.getElementById('member-email').value;
    const codeInput = document.getElementById('auth-code');
    const errCode = document.getElementById('err-auth-code');

    if (!codeInput.value || codeInput.value.length !== 6) {
      showError(codeInput, errCode, '6자리 인증번호를 입력해 주세요.');
      return;
    }

    fetch('/api/email/verify-code', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ memberEmail: emailVal, code: codeInput.value })
    })
            .then(res => res.json())
            .then(data => {
              if (data.success) {
                showSuccess(codeInput, errCode, '이메일 인증이 완료되었습니다.');
                isEmailVerified = true;
                clearInterval(timerInterval);
                document.getElementById('timer').innerText = '';
                document.getElementById('member-email').readOnly = true;
                codeInput.readOnly = true;
                document.getElementById('member-phone').focus(); // 인증 성공 시 다음 칸(휴대전화)으로 이동
              } else {
                showError(codeInput, errCode, data.message);
                isEmailVerified = false;
              }
            });
  }

  // 타이머 헬퍼
  function startTimer(duration) {
    let timer = duration, minutes, seconds;
    clearInterval(timerInterval);
    timerInterval = setInterval(function () {
      minutes = parseInt(timer / 60, 10);
      seconds = parseInt(timer % 60, 10);
      minutes = minutes < 10 ? "0" + minutes : minutes;
      seconds = seconds < 10 ? "0" + seconds : seconds;

      document.getElementById('timer').innerText = minutes + ":" + seconds;

      if (--timer < 0) {
        clearInterval(timerInterval);
        document.getElementById('timer').innerText = "만료";
        showError(document.getElementById('auth-code'), document.getElementById('err-auth-code'), '인증시간이 만료되었습니다. 재발송 해주세요.');
      }
    }, 1000);
  }

  // input 변경 시 초기화
  document.getElementById('member-id').addEventListener('input', function() {
    isIdChecked = false;
    clearError(this, document.getElementById('err-id'));
  });

  document.getElementById('member-email').addEventListener('input', function() {
    isEmailVerified = false;
    clearError(this, document.getElementById('err-email'));
  });

  // 다음 단계 이동 및 전체 유효성 검사
  function goToNextStep() {
    const idInput = document.getElementById('member-id');
    const pwInput = document.getElementById('member-password');
    const nameInput = document.getElementById('member-name');
    const emailInput = document.getElementById('member-email');
    const phoneInput = document.getElementById('member-phone');

    const errId = document.getElementById('err-id');
    const errPw = document.getElementById('err-password');
    const errName = document.getElementById('err-name');
    const errEmail = document.getElementById('err-email');
    const errPhone = document.getElementById('err-phone');

    let isIdValid = checkField(idInput, errId, validateId);
    if (isIdValid && !isIdChecked) {
      showError(idInput, errId, '아이디 중복확인을 진행해 주세요.');
      isIdValid = false;
    }

    const isPwValid = checkField(pwInput, errPw, validatePassword);
    const isNameValid = checkField(nameInput, errName, validateName);

    let isEmailValid = checkField(emailInput, errEmail, validateEmail);
    if (isEmailValid && !isEmailVerified) {
      showError(emailInput, errEmail, '이메일 인증을 완료해 주세요.');
      isEmailValid = false;
    }
    const isPhoneValid = checkField(phoneInput, errPhone, validatePhone);

    if (!isIdValid) idInput.focus();
    else if (!isPwValid) pwInput.focus();
    else if (!isNameValid) nameInput.focus();
    else if (!isEmailValid) emailInput.focus();
    else if (!isPhoneValid) phoneInput.focus();

    if (isIdValid && isPwValid && isNameValid && isEmailValid && isPhoneValid) {
      document.getElementById('step1').classList.add('hidden');
      document.getElementById('step2').classList.remove('hidden');
      document.getElementById('pageTitle').innerText = '회원 설정';
      document.getElementById('joinProgress').classList.add('is-step-2');
      document.getElementById('progressLabel').innerText = '2 / 2';
      document.getElementById('stepDescription').innerText = '커뮤니티에서 사용할 프로필을 완성해 주세요.';
    }
  }

  // 엔터키 순차 포커스 이동 처리 (이메일 인증 로직 반영)
  document.getElementById('joinForm').addEventListener('keydown', function(event) {
    if (event.key === 'Enter') {
      event.preventDefault();

      const target = event.target;
      const step1 = document.getElementById('step1');

      // ----------------------------------------------------
      // [Step 1] 회원정보 입력 단계
      // ----------------------------------------------------
      if (!step1.classList.contains('hidden')) {

        const pwInput = document.getElementById('member-password');
        const nameInput = document.getElementById('member-name');
        const emailInput = document.getElementById('member-email');
        const authCodeInput = document.getElementById('auth-code');
        const phoneInput = document.getElementById('member-phone');

        if (target.id === 'member-id') {
          if (isIdChecked) {
            pwInput.focus();
          } else {
            checkDuplicateId();
          }
        }
        else if (target.id === 'member-password') {
          if (checkField(pwInput, document.getElementById('err-password'), validatePassword)) {
            nameInput.focus();
          }
        }
        else if (target.id === 'member-name') {
          if (checkField(nameInput, document.getElementById('err-name'), validateName)) {
            emailInput.focus();
          }
        }
        else if (target.id === 'member-email') {
          sendAuthCode(); // 엔터치면 인증번호 발송 요청
        }
        else if (target.id === 'auth-code') {
          verifyAuthCode(); // 엔터치면 인증번호 대조 확인
        }
        else if (target.id === 'member-phone') {
          if (checkField(phoneInput, document.getElementById('err-phone'), validatePhone)) {
            goToNextStep();
          }
        }
      }
              // ----------------------------------------------------
              // [Step 2] 회원설정 단계 (join-step2.jsp 연동)
      // ----------------------------------------------------
      else {
        if (target.id === 'nickname') {
          if (typeof isNicknameChecked !== 'undefined' && isNicknameChecked) {
            submitForm();
          } else {
            checkDuplicateNickname();
          }
        } else {
          submitForm();
        }
      }
    }
  });
</script>

</body>
</html>
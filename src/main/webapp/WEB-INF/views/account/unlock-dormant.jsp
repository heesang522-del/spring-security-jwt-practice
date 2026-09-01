<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!doctype html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="description" content="휴면 계정 해제">
  <title>휴면 계정 해제 | Youwin</title>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/app.css">
  <link rel="stylesheet" href="${pageContext.request.contextPath}/auth.css">
  <link rel="stylesheet" href="${pageContext.request.contextPath}/account.css">
</head>
<body>
<div class="auth-page">
  <aside class="auth-aside" aria-label="Youwin 계정 보호">
    <a class="brand auth-brand" href="${pageContext.request.contextPath}/" aria-label="Youwin 홈"><span class="brand__mark">YW</span><span>Youwin</span></a>
    <div class="auth-aside__copy">
      <p class="auth-aside__eyebrow">Secure your account</p>
      <h2>소중한 계정을<br>안전하게 다시 연결해요</h2>
      <p class="auth-aside__description">등록된 이메일 인증을 통해 본인 확인 후 계정 이용을 이어갈 수 있습니다.</p>
    </div>
    <p class="auth-aside__note">인증번호는 타인에게 공유하지 마세요.</p>
  </aside>
  <main class="auth-main">
    <section class="auth-card recovery-card" aria-labelledby="recovery-title">
      <a class="auth-back" href="${pageContext.request.contextPath}/auth/login">← 로그인으로 돌아가기</a>
      <div class="auth-heading">
        <p class="auth-heading__eyebrow">Dormant account</p>
        <h1 class="auth-title" id="recovery-title">다시 활동을 시작할까요?</h1>
        <p class="auth-description">장기간 로그인하지 않아 계정이 안전하게 휴면 상태로 전환되었습니다.</p>
      </div>

      <div class="recovery-note ">
        <strong>현재 휴면 상태입니다</strong>
        <p>회원님의 계정(<strong>${memberId}</strong>)은 이메일 인증 후 즉시 다시 이용할 수 있습니다.</p>
      </div>

      <form id="unlockForm" class="auth-form" onsubmit="return false;">
        <div class="recovery-email">
          <span>등록된 이메일</span>
          <strong>${memberEmail}</strong>
        </div>
        <button type="button" id="btnSendCode" class="button button--secondary">인증번호 발송</button>
        <div class="input-group">
          <label for="authCode">인증번호</label>
          <input type="text" id="authCode" inputmode="numeric" maxlength="6" autocomplete="one-time-code" placeholder="인증번호 6자리" disabled>
        </div>
        <button type="button" id="btnVerify" class="btn-submit">인증하고 휴면 해제</button>
      </form>
    </section>
  </main>
</div>
<script>
  // 1. 인증번호 발송 요청
  document.getElementById('btnSendCode').addEventListener('click', function() {
    const authInput = document.getElementById('authCode');

    fetch('/api/auth/send-recovery-code', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ memberEmail: '${memberEmail}' })
    })
            .then(res => res.json())
            .then(data => {
              if (data.success) {
                alert(data.message);
                authInput.disabled = false;
                authInput.focus();
              } else {
                alert(data.message);
              }
            })
            .catch(error => {
              console.error('Error:', error);
              alert('인증번호 발송 실패!');
            });
  });

  // 2. 휴면 해제 요청
  document.getElementById('btnVerify').addEventListener('click', function() {
    const authInput = document.getElementById('authCode');
    const code = authInput.value.trim();

    if (!code) {
      alert('인증번호를 입력해 주세요.');
      return;
    }

    fetch('/api/auth/unlock-dormant', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ code: code })
    })
            .then(res => res.text())
            .then(res => {
              if (res === 'SUCCESS') {
                alert('휴면 상태가 정상적으로 해제되었습니다! 다시 로그인해 주세요.');
                location.href = '/auth/login';
              } else if (res === 'FAIL') {
                alert('인증번호가 올바르지 않습니다.');
              } else {
                alert('세션이 만료되었습니다. 다시 로그인 시도해 주세요.');
                location.href = '/auth/login';
              }
            })
            .catch(error => {
              console.error('Error:', error);
              alert('처리 중 오류가 발생했습니다.');
            });
  });
</script>
</body>
</html>
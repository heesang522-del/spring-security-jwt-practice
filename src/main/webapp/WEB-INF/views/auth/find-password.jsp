<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>

<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="sec" uri="http://www.springframework.org/security/tags" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>

<%@ include file="/WEB-INF/views/common/header.jsp" %>

<head>
    <meta name="description" content="Youwin 비밀번호 찾기">
    <title>Youwin | 비밀번호 찾기</title>
</head>

<main class="page-main">
    <div class="site-container account-container">
        <div class="surface account-card">
            <div class="section-head" style="margin-bottom: 24px;">
                <div>
                    <h1 class="section-title" id="pageTitle" style="font-size: 24px;">비밀번호 찾기</h1>
                    <p class="section-copy" id="pageSubTitle">가입하신 아이디와 이메일 정보를 입력해 주세요.</p>
                </div>
            </div>

            <!-- Step 1: 아이디 & 이메일 인증 -->
            <form id="findPwForm" class="account-form" onsubmit="return false;">
                <div>
                    <label for="memberId" style="display: block; font-size: 14px; font-weight: 600; margin-bottom: 8px; color: #ffffff;">아이디</label>
                    <input type="text" id="memberId" name="memberId" placeholder="아이디를 입력하세요"
                           style="width: 100%; padding: 12px; border-radius: 8px; border: 1px solid rgba(255, 255, 255, 0.2); background: #1a1a1a; color: #ffffff; font-size: 15px; box-sizing: border-box; outline: none;">
                    <span class="msg-text msg-error" id="err-id"></span>
                </div>

                <div>
                    <label for="memberEmail" style="display: block; font-size: 14px; font-weight: 600; margin-bottom: 8px; color: #ffffff;">이메일</label>
                    <div class="input-group-btn">
                        <input type="email" id="memberEmail" name="memberEmail" placeholder="example@youwin.com"
                               style="padding: 12px; border-radius: 8px; border: 1px solid rgba(255, 255, 255, 0.2); background: #1a1a1a; color: #ffffff; font-size: 15px; box-sizing: border-box; outline: none;">
                        <button type="button" class="btn-sub" onclick="sendAuthCode()">인증 요청</button>
                    </div>
                    <span class="msg-text" id="err-email"></span>
                </div>

                <div id="authCodeGroup" class="hidden">
                    <label for="authCode" style="display: block; font-size: 14px; font-weight: 600; margin-bottom: 8px; color: #ffffff;">인증번호</label>
                    <div class="input-group-btn" style="position: relative;">
                        <input type="text" id="authCode" maxlength="6" placeholder="인증번호 6자리"
                               style="padding: 12px; border-radius: 8px; border: 1px solid rgba(255, 255, 255, 0.2); background: #1a1a1a; color: #ffffff; font-size: 15px; box-sizing: border-box; outline: none;">
                        <span class="timer-badge" id="timer">05:00</span>
                        <button type="button" class="btn-sub" onclick="verifyAuthCode()">확인</button>
                    </div>
                    <span class="msg-text" id="err-auth-code"></span>
                </div>
            </form>

            <!-- Step 2: 새 비밀번호 설정 -->
            <form id="resetPwForm" class="hidden account-form" onsubmit="return false;">
                <div>
                    <label for="newPassword" style="display: block; font-size: 14px; font-weight: 600; margin-bottom: 8px; color: #ffffff;">새 비밀번호</label>
                    <input type="password" id="newPassword" placeholder="8~20자, 특수문자 포함"
                           style="width: 100%; padding: 12px; border-radius: 8px; border: 1px solid rgba(255, 255, 255, 0.2); background: #1a1a1a; color: #ffffff; font-size: 15px; box-sizing: border-box; outline: none;">
                    <span class="msg-text msg-error" id="err-pw"></span>
                </div>

                <div>
                    <label for="newPasswordConfirm" style="display: block; font-size: 14px; font-weight: 600; margin-bottom: 8px; color: #ffffff;">새 비밀번호 확인</label>
                    <input type="password" id="newPasswordConfirm" placeholder="비밀번호 재입력"
                           style="width: 100%; padding: 12px; border-radius: 8px; border: 1px solid rgba(255, 255, 255, 0.2); background: #1a1a1a; color: #ffffff; font-size: 15px; box-sizing: border-box; outline: none;">
                    <span class="msg-text msg-error" id="err-pw-confirm"></span>
                </div>

                <button type="button" class="button" onclick="resetPasswordSubmit()" style="width: 100%; margin-top: 8px;">비밀번호 변경 완료</button>
            </form>

            <div class="account-links">
                <a class="text-link" href="${ctx}/auth/find-id">아이디 찾기</a>
                <a class="text-link" href="${ctx}/auth/login">로그인으로 돌아가기</a>
            </div>
        </div>
    </div>
</main>

<script>
    const CTX = "${ctx}";
    let isEmailVerified = false;
    let timerInterval = null;

    function showMsg(elemId, msg, isSuccess) {
        const target = document.getElementById(elemId);
        target.innerText = msg;
        target.className = 'msg-text ' + (isSuccess ? 'msg-success' : 'msg-error');
    }

    function clearMsg(elemId) {
        document.getElementById(elemId).innerText = '';
    }

    function sendAuthCode() {
        const memberId = document.getElementById('memberId').value.trim();
        const email = document.getElementById('memberEmail').value.trim();

        clearMsg('err-id');
        clearMsg('err-email');
        clearMsg('err-auth-code');

        if (!memberId) { showMsg('err-id', '아이디를 입력해 주세요.', false); return; }
        if (!email) { showMsg('err-email', '이메일을 입력해 주세요.', false); return; }

        showMsg('err-email', '정보 확인 및 인증번호 발송 중...', true);

        fetch(`${CTX}/api/auth/find-pw/send-code`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ memberId: memberId, memberEmail: email })
        })
            .then(res => res.json())
            .then(data => {
                if (data.success) {
                    showMsg('err-email', '인증번호가 발송되었습니다.', true);
                    document.getElementById('authCodeGroup').classList.remove('hidden');
                    document.getElementById('authCode').focus();
                    startTimer(300);
                } else {
                    showMsg('err-email', data.message || '일치하는 회원 정보가 없습니다.', false);
                }
            })
            .catch(() => showMsg('err-email', '서버 통신 중 오류가 발생했습니다.', false));
    }

    function verifyAuthCode() {
        const email = document.getElementById('memberEmail').value.trim();
        const code = document.getElementById('authCode').value.trim();

        clearMsg('err-auth-code');

        if (!code || code.length !== 6) {
            showMsg('err-auth-code', '6자리 인증번호를 입력해 주세요.', false);
            return;
        }

        fetch(`${CTX}/api/email/verify-code`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ memberEmail: email, code: code })
        })
            .then(res => res.json())
            .then(data => {
                if (data.success) {
                    showMsg('err-auth-code', '이메일 인증이 완료되었습니다.', true);
                    isEmailVerified = true;
                    clearInterval(timerInterval);

                    // 약 0.8초 후 Step 2 폼 전환 (사용자가 성공 메시지를 확인할 수 있도록)
                    setTimeout(() => {
                        document.getElementById('findPwForm').classList.add('hidden');
                        document.getElementById('resetPwForm').classList.remove('hidden');
                        document.getElementById('pageTitle').innerText = '새 비밀번호 설정';
                        document.getElementById('pageSubTitle').innerText = '새롭게 사용할 비밀번호를 입력해 주세요.';
                    }, 800);
                } else {
                    showMsg('err-auth-code', data.message || '인증번호가 일치하지 않습니다.', false);
                    isEmailVerified = false;
                }
            })
            .catch(() => showMsg('err-auth-code', '서버 통신 중 오류가 발생했습니다.', false));
    }

    function resetPasswordSubmit() {
        if (!isEmailVerified) {
            showMsg('err-pw', '이메일 인증이 완료되지 않았습니다.', false);
            return;
        }

        const memberId = document.getElementById('memberId').value.trim();
        const email = document.getElementById('memberEmail').value.trim();
        const newPassword = document.getElementById('newPassword').value;
        const newPasswordConfirm = document.getElementById('newPasswordConfirm').value;

        clearMsg('err-pw');
        clearMsg('err-pw-confirm');

        const pwPattern = /^(?=.*[a-zA-Z])(?=.*\d)(?=.*[!@#$%^&*]).{8,20}$/;
        if (!pwPattern.test(newPassword)) {
            showMsg('err-pw', '8~20자, 영문/숫자/특수문자(!@#$%^&*)를 모두 포함해야 합니다.', false);
            return;
        }

        if (newPassword !== newPasswordConfirm) {
            showMsg('err-pw-confirm', '비밀번호가 일치하지 않습니다.', false);
            return;
        }

        fetch(`${CTX}/api/auth/reset-pw`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                memberId: memberId,
                memberEmail: email,
                newPassword: newPassword
            })
        })
            .then(res => res.json())
            .then(data => {
                if (data.success) {
                    showMsg('err-pw-confirm', '비밀번호가 변경되었습니다. 로그인 페이지로 이동합니다.', true);
                    setTimeout(() => {
                        location.href = `${CTX}/auth/login`;
                    }, 1200);
                } else {
                    showMsg('err-pw-confirm', data.message || '비밀번호 변경에 실패했습니다.', false);
                }
            })
            .catch(() => showMsg('err-pw-confirm', '서버 통신 중 오류가 발생했습니다.', false));
    }

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
                showMsg('err-auth-code', '인증시간이 만료되었습니다. 다시 요청해 주세요.', false);
            }
        }, 1000);
    }
</script>

<%@ include file="/WEB-INF/views/common/footer.jsp" %>
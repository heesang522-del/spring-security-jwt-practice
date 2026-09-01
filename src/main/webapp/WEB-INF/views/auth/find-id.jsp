<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>

<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="sec" uri="http://www.springframework.org/security/tags" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>

<%@ include file="/WEB-INF/views/common/header.jsp" %>

<head>
    <meta name="description" content="Youwin 아이디 찾기">
    <title>Youwin | 아이디 찾기</title>
</head>

<main class="page-main">
    <div class="site-container account-container">
        <div class="surface account-card">
            <div class="section-head" style="margin-bottom: 24px;">
                <div>
                    <h1 class="section-title" style="font-size: 24px;">아이디 찾기</h1>
                    <p class="section-copy">가입 시 등록하신 이름과 이메일로 인증 후 아이디를 확인합니다.</p>
                </div>
            </div>

            <!-- 아이디 찾기 입력 폼 -->
            <form id="findIdForm" class="account-form" onsubmit="return false;">
                <!-- 1. 이름 입력 -->
                <div>
                    <label for="memberName" style="display: block; font-size: 14px; font-weight: 600; margin-bottom: 8px; color: #ffffff;">이름</label>
                    <input type="text" id="memberName" name="memberName" placeholder="이름을 입력하세요"
                           style="width: 100%; padding: 12px; border-radius: 8px; border: 1px solid rgba(255, 255, 255, 0.2); background: #1a1a1a; color: #ffffff; font-size: 15px; box-sizing: border-box; outline: none;">
                    <span class="msg-text msg-error" id="err-name"></span>
                </div>

                <!-- 2. 이메일 입력 및 인증 버튼 -->
                <div>
                    <label for="memberEmail" style="display: block; font-size: 14px; font-weight: 600; margin-bottom: 8px; color: #ffffff;">이메일</label>
                    <div class="input-group-btn">
                        <input type="email" id="memberEmail" name="memberEmail" placeholder="example@youwin.com"
                               style="padding: 12px; border-radius: 8px; border: 1px solid rgba(255, 255, 255, 0.2); background: #1a1a1a; color: #ffffff; font-size: 15px; box-sizing: border-box; outline: none;">
                        <button type="button" class="btn-sub" onclick="sendAuthCode()">인증 요청</button>
                    </div>
                    <span class="msg-text" id="err-email"></span>
                </div>

                <!-- 3. 인증번호 입력 영역 (기본 숨김) -->
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

                <!-- 4. 결과 출력 박스 (기본 숨김) -->
                <div id="resultBox" class="hidden account-result">
                    <p style="margin: 0; font-size: 14px; color: #cbd5e1;">회원님의 아이디는 다음과 같습니다.</p>
                    <p style="margin: 10px 0 0 0; font-size: 20px; font-weight: bold; color: #ffffff;" id="foundMemberId"></p>
                </div>

                <!-- 5. 제출 버튼 -->
                <button type="button" id="btnSubmit" class="button" onclick="findIdSubmit()" style="width: 100%; margin-top: 8px;">아이디 찾기</button>
            </form>

            <div class="account-links">
                <a class="text-link" href="${ctx}/auth/find-password">비밀번호 찾기</a>
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
        const name = document.getElementById('memberName').value.trim();
        const email = document.getElementById('memberEmail').value.trim();

        clearMsg('err-name');
        clearMsg('err-email');

        if (!name) { showMsg('err-name', '이름을 입력해 주세요.', false); return; }
        if (!email) { showMsg('err-email', '이메일을 입력해 주세요.', false); return; }

        showMsg('err-email', '정보 확인 및 인증번호 발송 중...', true);

        fetch(`${CTX}/api/auth/find-id/send-code`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ memberName: name, memberEmail: email })
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
                    document.getElementById('timer').innerText = '';
                    document.getElementById('memberName').readOnly = true;
                    document.getElementById('memberEmail').readOnly = true;
                    document.getElementById('authCode').readOnly = true;
                } else {
                    showMsg('err-auth-code', data.message || '인증번호가 일치하지 않습니다.', false);
                    isEmailVerified = false;
                }
            });
    }

    function findIdSubmit() {
        if (!isEmailVerified) {
            alert('이메일 인증을 먼저 완료해 주세요.');
            return;
        }

        const name = document.getElementById('memberName').value.trim();
        const email = document.getElementById('memberEmail').value.trim();

        fetch(`${CTX}/api/auth/find-id`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ memberName: name, memberEmail: email })
        })
            .then(res => res.json())
            .then(data => {
                if (data.success) {
                    document.getElementById('foundMemberId').innerText = data.memberId;
                    document.getElementById('resultBox').classList.remove('hidden');
                    document.getElementById('btnSubmit').classList.add('hidden');
                } else {
                    alert(data.message);
                }
            });
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
                showMsg('err-auth-code', '인증시간이 만료되었습니다. 다시 요청해주세요.', false);
            }
        }, 1000);
    }
</script>

<%@ include file="/WEB-INF/views/common/footer.jsp" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
    <footer class="site-footer">
        <div class="site-container site-footer__inner">
            <span>© 2026 Youwin. 음악으로 연결되는 커뮤니티.</span>
            <div class="site-footer__links">
                <a href="${ctx}/board">공지사항</a>
                <a href="#">이용약관</a>
                <a href="#">개인정보처리방침</a>
            </div>
        </div>
    </footer>
</div>

<script src="${ctx}/app.js"></script>
<script src="${ctx}/home.js"></script>

<c:if test="${not empty successMessage}">
    <script>alert("${successMessage}");</script>
</c:if>

<c:if test="${not empty errorMessage}">
    <script>alert("${errorMessage}");</script>
</c:if>
</body>
</html>
// API 요청에서도 기존 로그인이 종료됐다는 안내를 표시합니다.
(function () {
    const originalFetch = window.fetch.bind(window);
    let redirecting = false;
    window.fetch = async function (...args) {
        const response = await originalFetch(...args);
        const input = args[0];
        const url = new URL(input instanceof Request ? input.url : input, window.location.href);
        if (url.origin === window.location.origin && response.status === 401 && !redirecting) {
            const result = await response.clone().json().catch(() => null);
            if (result?.code === 'SESSION_REPLACED' || result?.code === 'SESSION_EXPIRED') {
                redirecting = true;
                const loginLink = document.querySelector('a[href$="/auth/login"]');
                const loginUrl = new URL(loginLink?.href || '/auth/login', window.location.origin);
                loginUrl.searchParams.set('reason', result.code);
                window.location.assign(loginUrl.href);
            }
        }
        return response;
    };
})();

(function () {
    const menuButton = document.querySelector('[data-menu-toggle]');
    const menu = document.querySelector('[data-site-nav]');

    if (!menuButton || !menu) {
        return;
    }

    function closeMenu() {
        menu.classList.remove('is-open');
        menuButton.setAttribute('aria-expanded', 'false');
        menuButton.setAttribute('aria-label', '메뉴 열기');
        document.body.classList.remove('is-menu-open');
    }

    menuButton.addEventListener('click', function () {
        const isOpen = menu.classList.toggle('is-open');
        menuButton.setAttribute('aria-expanded', String(isOpen));
        menuButton.setAttribute('aria-label', isOpen ? '메뉴 닫기' : '메뉴 열기');
        document.body.classList.toggle('is-menu-open', isOpen);
    });

    menu.addEventListener('click', function (event) {
        if (event.target.closest('a, button')) {
            closeMenu();
        }
    });

    document.addEventListener('keydown', function (event) {
        if (event.key === 'Escape' && menu.classList.contains('is-open')) {
            closeMenu();
            menuButton.focus();
        }
    });

    document.addEventListener('click', function (event) {
        if (menu.classList.contains('is-open') && !menu.contains(event.target) && !menuButton.contains(event.target)) {
            closeMenu();
        }
    });

    window.addEventListener('resize', function () {
        if (window.innerWidth > 920) {
            closeMenu();
        }
    });
})();

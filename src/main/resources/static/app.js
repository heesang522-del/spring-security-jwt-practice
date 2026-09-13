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

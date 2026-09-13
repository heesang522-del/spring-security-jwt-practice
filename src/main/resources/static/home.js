(function () {
    const searchForm = document.querySelector('[data-home-search]');

    if (!searchForm) {
        return;
    }

    searchForm.addEventListener('submit', function (event) {
        event.preventDefault();
        const query = new FormData(searchForm).get('query');

        if (query && query.trim()) {
            window.location.href = '/board?query=' + encodeURIComponent(query.trim());
        }
    });
})();

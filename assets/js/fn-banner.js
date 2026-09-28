/*
 * Foundation banner dismissal.

 * Contract: docs/CONTRACTS.md §7.2
 * Opt-in persistence: when a banner carries an id, dismissal is remembered for
 * the session so the consumer can choose its own storage lifetime.
 */
(function () {
    'use strict';

    var KEY = 'fn-banner-dismissed';

    function dismissed() {
        try {
            return JSON.parse(sessionStorage.getItem(KEY) || '[]');
        } catch (error) {
            return [];
        }
    }

    function remember(id) {
        try {
            var list = dismissed();
            if (list.indexOf(id) === -1) {
                list.push(id);
                sessionStorage.setItem(KEY, JSON.stringify(list));
            }
        } catch (error) {
            /* storage unavailable: dismissal stays page-scoped */
        }
    }

    function restore() {
        var list = dismissed();
        if (!list.length) {
            return;
        }
        document.querySelectorAll('.fn-banner[id]').forEach(function (banner) {
            if (list.indexOf(banner.id) !== -1) {
                banner.remove();
            }
        });
    }

    document.addEventListener('click', function (event) {
        var button = event.target.closest('[data-fn-banner-dismiss]');
        if (!button) {
            return;
        }
        var banner = button.closest('.fn-banner');
        if (!banner) {
            return;
        }
        if (banner.id) {
            remember(banner.id);
        }
        banner.remove();
    });

    restore();
})();

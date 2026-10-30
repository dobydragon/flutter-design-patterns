(function () {
  var root = document.documentElement;

  // Theme toggle: explicit choice wins over the system preference.
  var themeBtn = document.querySelector('.theme-btn');
  if (themeBtn) {
    themeBtn.addEventListener('click', function () {
      var current = root.getAttribute('data-theme');
      if (!current) {
        current = window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
      }
      var next = current === 'dark' ? 'light' : 'dark';
      root.setAttribute('data-theme', next);
      try { localStorage.setItem('theme', next); } catch (e) {}
    });
  }

  // Mobile nav.
  var menuBtn = document.querySelector('.menu-btn');
  var nav = document.getElementById('nav');
  if (menuBtn && nav) {
    menuBtn.addEventListener('click', function () {
      var open = nav.classList.toggle('open');
      menuBtn.setAttribute('aria-expanded', open ? 'true' : 'false');
    });
  }

  // Collapse the TOC on small screens, and close it after picking a section.
  var tocBox = document.querySelector('.toc-box');
  var small = window.matchMedia('(max-width: 900px)');
  if (tocBox) {
    if (small.matches) tocBox.removeAttribute('open');
    tocBox.addEventListener('click', function (e) {
      if (e.target.closest('a') && small.matches) tocBox.removeAttribute('open');
    });
  }

  // Highlight the TOC entry for the section in view.
  var links = Array.prototype.slice.call(document.querySelectorAll('.toc a[href^="#"]'));
  if (links.length && 'IntersectionObserver' in window) {
    var byId = {};
    links.forEach(function (a) { byId[decodeURIComponent(a.getAttribute('href').slice(1))] = a; });
    var targets = Object.keys(byId).map(function (id) { return document.getElementById(id); }).filter(Boolean);
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (en) {
        if (en.isIntersecting) {
          links.forEach(function (a) { a.classList.remove('active'); });
          var a = byId[en.target.id];
          if (a) a.classList.add('active');
        }
      });
    }, { rootMargin: '-80px 0px -70% 0px' });
    targets.forEach(function (t) { io.observe(t); });
  }

  // Copy buttons on code cards.
  document.querySelectorAll('.copy-btn').forEach(function (btn) {
    btn.addEventListener('click', function () {
      var code = document.getElementById(btn.getAttribute('data-target'));
      if (!code || !navigator.clipboard) return;
      navigator.clipboard.writeText(code.textContent).then(function () {
        btn.textContent = 'Copied';
        setTimeout(function () { btn.textContent = 'Copy'; }, 1500);
      }, function () {});
    });
  });

  // Syntax highlighting (only if the CDN loaded).
  if (window.hljs) {
    document.querySelectorAll('pre code').forEach(function (el) {
      if (!/language-/.test(el.className)) el.classList.add('language-plaintext');
      window.hljs.highlightElement(el);
    });
  }
})();

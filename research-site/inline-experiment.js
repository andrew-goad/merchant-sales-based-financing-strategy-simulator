(() => {
  const player = document.getElementById('gui-player');
  if (!player) return;
  const film = player.closest('figure');
  function followRoute() {
    const article = document.querySelector('article[data-study]:not([hidden])');
    if (!article) return;
    const section = article.querySelector('[data-place="experiment"]');
    const slot = section?.querySelector('[data-gui-film-slot]');
    if (!slot) return;
    if (film.parentElement !== slot) {
      player.pause();
      slot.append(film);
    }
    const [, place, step] = location.hash.slice(1).split('/');
    let detail;
    if (place === 'gui') detail = slot;
    if (place === 'experiment' && step) {
      detail = [...section.querySelectorAll('[data-operator-step]')].find(node => node.dataset.operatorStep === step);
    }
    if (detail) {
      detail.open = true;
      detail.scrollIntoView({block:'start'});
      detail.querySelector('summary').focus({preventScroll:true});
    }
  }
  // The main route handler first switches to the selected study.
  window.addEventListener('hashchange', () => requestAnimationFrame(followRoute));
  followRoute();
})();

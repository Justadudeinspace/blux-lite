/* Daisy field ------------------------------------------------------------ */
(function () {
  const field = document.getElementById('daisyField');
  if (!field) return;

  // Make dimensions mutable for resize handling
  let vw = Math.max(document.documentElement.clientWidth, window.innerWidth || 0);
  let vh = Math.max(document.documentElement.clientHeight, window.innerHeight || 0);
  let density = Math.max(30, Math.min(140, Math.floor((vw * vh) / 36000)));

  // Create an SVG daisy clone with unique defs (avoid ID collisions)
  function makeDaisy(x, y, scale, rot) {
    const uid = Math.random().toString(36).slice(2, 8);
    const svgNS = 'http://www.w3.org/2000/svg';

    const svg = document.createElementNS(svgNS, 'svg');
    svg.setAttribute('viewBox', '0 0 100 100');
    svg.setAttribute('width', (100 * scale).toFixed(1));
    svg.setAttribute('height', (100 * scale).toFixed(1));
    svg.style.left = `${x}px`;
    svg.style.top = `${y}px`;
    svg.style.position = 'absolute';
    svg.style.transform = `rotate(${rot}deg)`;
    svg.style.willChange = 'transform, filter'; // Performance optimization

    const defs = document.createElementNS(svgNS, 'defs');

    const grad = document.createElementNS(svgNS, 'linearGradient');
    grad.setAttribute('id', `dg-${uid}`);
    grad.setAttribute('x1', '0%'); grad.setAttribute('y1', '0%');
    grad.setAttribute('x2', '100%'); grad.setAttribute('y2', '100%');
    const stop1 = document.createElementNS(svgNS, 'stop');
    stop1.setAttribute('offset', '0%');
    stop1.setAttribute('stop-color', '#6ea8ff');
    stop1.setAttribute('stop-opacity', '0.9');
    const stop2 = document.createElementNS(svgNS, 'stop');
    stop2.setAttribute('offset', '100%');
    stop2.setAttribute('stop-color', '#a78bfa');
    stop2.setAttribute('stop-opacity', '1');
    grad.append(stop1, stop2);

    const filt = document.createElementNS(svgNS, 'filter');
    filt.setAttribute('id', `glow-${uid}`);
    filt.setAttribute('x', '-50%'); filt.setAttribute('y', '-50%');
    filt.setAttribute('width', '200%'); filt.setAttribute('height', '200%');
    const blur = document.createElementNS(svgNS, 'feGaussianBlur');
    blur.setAttribute('stdDeviation', '1.5'); blur.setAttribute('result', 'coloredBlur');
    const merge = document.createElementNS(svgNS, 'feMerge');
    const m1 = document.createElementNS(svgNS, 'feMergeNode'); m1.setAttribute('in', 'coloredBlur');
    const m2 = document.createElementNS(svgNS, 'feMergeNode'); m2.setAttribute('in', 'SourceGraphic');
    merge.append(m1, m2);
    filt.append(blur, merge);

    defs.append(grad, filt);
    svg.appendChild(defs);

    // petals
    const g = document.createElementNS(svgNS, 'g');
    g.setAttribute('fill', `url(#dg-${uid})`);
    g.setAttribute('stroke', '#6ea8ff');
    g.setAttribute('stroke-width', '0.5');
    g.setAttribute('stroke-linecap', 'round');
    g.setAttribute('stroke-linejoin', 'round');
    g.setAttribute('filter', `url(#glow-${uid})`);

    const rotations = Array.from({ length: 16 }, (_, i) => i * 22.5);
    const makePath = d => { const p = document.createElementNS(svgNS, 'path'); p.setAttribute('d', d); return p; };
    rotations.forEach(r => {
      const p = makePath('M 50 45 C 40 20, 60 20, 50 45');
      p.setAttribute('transform', `rotate(${r.toFixed(3)}, 50, 50)`);
      g.appendChild(p);
    });
    [22.5, 67.5, 112.5, 157.5, 202.5, 247.5, 292.5, 337.5].forEach(r => {
      const p = makePath('M 50 42 C 45 28, 55 28, 50 42');
      p.setAttribute('transform', `rotate(${r.toFixed(3)}, 50, 50)`);
      g.appendChild(p);
    });

    // center
    const c1 = document.createElementNS(svgNS, 'circle');
    c1.setAttribute('cx', '50'); c1.setAttribute('cy', '50'); c1.setAttribute('r', '12');
    c1.setAttribute('fill', '#e7e7ec'); c1.setAttribute('stroke', '#6ea8ff'); c1.setAttribute('stroke-width', '0.5');
    const c2 = document.createElementNS(svgNS, 'circle');
    c2.setAttribute('cx', '50'); c2.setAttribute('cy', '50'); c2.setAttribute('r', '8');
    c2.setAttribute('fill', `url(#dg-${uid})`); c2.setAttribute('opacity', '0.5');
    svg.append(g, c1, c2);

    return svg;
  }

  // Sprinkle the field
  const pad = 28; // edge breathing room
  for (let i = 0; i < density; i++) {
    const scale = (Math.random() * 0.75 + 0.35); // 0.35–1.10
    const rot = Math.floor(Math.random() * 360);
    const x = Math.floor(pad + Math.random() * (vw - pad * 2));
    const y = Math.floor(pad + Math.random() * (vh - pad * 2));
    field.appendChild(makeDaisy(x, y, scale, rot));
  }

  // Optimized resize handler
  let resizeTimeout;
  window.addEventListener('resize', () => {
    clearTimeout(resizeTimeout);
    resizeTimeout = setTimeout(() => {
      const newVw = Math.max(document.documentElement.clientWidth, window.innerWidth || 0);
      const newVh = Math.max(document.documentElement.clientHeight, window.innerHeight || 0);
      
      // Only recreate if size changed significantly (more than 50px in either dimension)
      if (Math.abs(vw - newVw) > 50 || Math.abs(vh - newVh) > 50) {
        while (field.firstChild) field.removeChild(field.firstChild);
        
        // Update dimensions
        vw = newVw;
        vh = newVh;
        const newDensity = Math.max(30, Math.min(140, Math.floor((vw * vh) / 36000)));
        
        // Recreate daisies
        for (let i = 0; i < newDensity; i++) {
          const scale = (Math.random() * 0.75 + 0.35);
          const rot = Math.floor(Math.random() * 360);
          const x = Math.floor(pad + Math.random() * (vw - pad * 2));
          const y = Math.floor(pad + Math.random() * (vh - pad * 2));
          field.appendChild(makeDaisy(x, y, scale, rot));
        }
      }
    }, 250);
  });
})();

/* Admin 10-minute unlock (client-side) ---------------------------------- */
(() => {
  const BTN = document.getElementById('admin');
  const STATUS = document.getElementById('status');
  const KEY = 'blux.admin.expiresAt';
  const DURATION = 10 * 60;    // seconds
  let timer;

  const fmt = sec => `${String(Math.floor(sec/60)).padStart(2,'0')}:${String(sec%60).padStart(2,'0')}`;

  function setState(unlocked, remainingSec = 0) {
    document.body.classList.toggle('admin-unlocked', unlocked);
    document.body.classList.toggle('admin-locked', !unlocked);
    if (!BTN || !STATUS) return;

    if (unlocked) {
      BTN.setAttribute('disabled', 'true');
      BTN.querySelector('span')?.innerText = 'Admin Active';
      STATUS.textContent = `Admin unlocked ${remainingSec ? `(${fmt(remainingSec)})` : ''}`;
    } else {
      BTN.removeAttribute('disabled');
      BTN.querySelector('span')?.innerText = 'Unlock Admin (10m)';
      STATUS.textContent = '';
    }
  }

  function startCountdown(expMs) {
    clearInterval(timer);
    const tick = () => {
      const now = Date.now();
      const remaining = Math.max(0, Math.floor((expMs - now) / 1000));
      if (remaining <= 0) {
        sessionStorage.removeItem(KEY);
        setState(false);
        clearInterval(timer);
        return;
      }
      setState(true, remaining);
    };
    tick();
    timer = setInterval(tick, 1000);
  }

  function unlock(seconds = DURATION) {
    const exp = Date.now() + seconds * 1000;
    sessionStorage.setItem(KEY, String(exp));
    startCountdown(exp);
  }

  // Clean up timer on page unload
  window.addEventListener('beforeunload', () => {
    clearInterval(timer);
  });

  // Error handling wrapper
  try {
    if (BTN) {
      BTN.setAttribute('aria-describedby', 'status'); // Accessibility improvement
      BTN.addEventListener('click', (e) => { 
        e.preventDefault(); 
        unlock(DURATION); 
      });
    }

    const expStr = sessionStorage.getItem(KEY);
    if (expStr) {
      const exp = Number(expStr);
      if (!Number.isNaN(exp) && exp > Date.now()) startCountdown(exp);
      else { sessionStorage.removeItem(KEY); setState(false); }
    } else {
      setState(false);
    }
  } catch (error) {
    console.error('Admin unlock error:', error);
    setState(false);
    if (STATUS) STATUS.textContent = 'Error loading admin';
  }
})();
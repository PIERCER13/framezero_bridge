/* framezero_bridge - recebe as mensagens do client/core/ui.lua */

const RESOURCE = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'framezero_bridge';
const $ = (id) => document.getElementById(id);

const post = (name, data = {}) =>
  fetch(`https://${RESOURCE}/${name}`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(data) }).catch(() => {});

// Prompt
function openPrompt({ title, placeholder, strings }) {
  $('prompt-title').textContent = title || strings.promptTitle;
  $('prompt-input').value = '';
  $('prompt-input').placeholder = placeholder || '';
  $('prompt-confirm').textContent = strings.confirm;
  $('prompt-cancel').textContent = strings.cancel;
  $('prompt').classList.remove('hidden');
  setTimeout(() => $('prompt-input').focus(), 30);
}
const closePrompt = () => $('prompt').classList.add('hidden');

$('prompt-confirm').onclick = () => post('prompt:submit', { value: $('prompt-input').value });
$('prompt-cancel').onclick = () => post('prompt:cancel');
$('prompt-input').addEventListener('keydown', (e) => {
  if (e.key === 'Enter') post('prompt:submit', { value: $('prompt-input').value });
  if (e.key === 'Escape') post('prompt:cancel');
});

// Solicitação
let requestTimer;
function openRequest({ message, timeout, strings }) {
  $('request-title').textContent = strings.requestTitle;
  $('request-message').textContent = message;
  $('key-accept').textContent = strings.acceptKey;
  $('key-decline').textContent = strings.declineKey;
  $('label-accept').textContent = strings.accept;
  $('label-decline').textContent = strings.decline;
  const bar = $('request-bar');
  bar.style.transition = 'none';
  bar.style.width = '100%';
  $('request').classList.remove('hidden');
  requestAnimationFrame(() => {
    bar.style.transition = `width ${timeout || 30000}ms linear`;
    bar.style.width = '0%';
  });
}
const closeRequest = () => {
  clearTimeout(requestTimer);
  $('request').classList.add('hidden');
};

// Progresso
let progressFrame;
function startProgress({ label, duration }) {
  const box = $('progress');
  box.classList.remove('hidden', 'cancelled');
  $('progress-label').textContent = label;
  const start = performance.now();
  cancelAnimationFrame(progressFrame);
  const tick = (now) => {
    const pct = Math.min(100, ((now - start) / duration) * 100);
    $('progress-bar').style.width = `${pct}%`;
    $('progress-pct').textContent = `${Math.floor(pct)}%`;
    if (pct < 100) progressFrame = requestAnimationFrame(tick);
  };
  progressFrame = requestAnimationFrame(tick);
}
function stopProgress({ cancelled }) {
  cancelAnimationFrame(progressFrame);
  const box = $('progress');
  if (cancelled) box.classList.add('cancelled');
  setTimeout(() => box.classList.add('hidden'), cancelled ? 600 : 150);
}

// Notificação
function notify({ kind, message, duration }) {
  const el = document.createElement('div');
  el.className = `fz-toast ${kind || 'info'}`;
  el.textContent = message;
  $('notify').appendChild(el);
  setTimeout(() => {
    el.classList.add('out');
    setTimeout(() => el.remove(), 260);
  }, duration || 5000);
}

window.addEventListener('message', ({ data }) => {
  switch (data.action) {
    case 'prompt:open': return openPrompt(data);
    case 'prompt:close': return closePrompt();
    case 'request:open': return openRequest(data);
    case 'request:close': return closeRequest();
    case 'progress:start': return startProgress(data);
    case 'progress:stop': return stopProgress(data);
    case 'text:show': $('text').textContent = data.text; return $('text').classList.remove('hidden');
    case 'text:hide': return $('text').classList.add('hidden');
    case 'notify': return notify(data);
  }
});

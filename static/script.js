const roleRow = document.getElementById('roleRow');
const questionText = document.getElementById('questionText');
const questionIndex = document.getElementById('questionIndex');
const newQuestionBtn = document.getElementById('newQuestionBtn');
const answerInput = document.getElementById('answerInput');
const submitBtn = document.getElementById('submitBtn');
const feedbackBlock = document.getElementById('feedbackBlock');
const feedbackText = document.getElementById('feedbackText');
const errorText = document.getElementById('errorText');
const statusEl = document.getElementById('status');

let currentRole = null;
let currentQuestion = null;
let qCount = 0;

async function loadRoles() {
  const res = await fetch('/api/roles');
  const roles = await res.json();
  roleRow.innerHTML = '';
  Object.entries(roles).forEach(([key, label], i) => {
    const btn = document.createElement('button');
    btn.className = 'role-tab';
    btn.type = 'button';
    btn.setAttribute('role', 'tab');
    btn.textContent = label;
    btn.setAttribute('aria-selected', 'false');
    btn.addEventListener('click', () => selectRole(key, btn));
    roleRow.appendChild(btn);
    if (i === 0) selectRole(key, btn);
  });
}

function selectRole(key, btn) {
  currentRole = key;
  document.querySelectorAll('.role-tab').forEach((b) => b.setAttribute('aria-selected', 'false'));
  btn.setAttribute('aria-selected', 'true');
  qCount = 0;
  fetchQuestion();
}

async function fetchQuestion() {
  setLoading(true);
  errorText.hidden = true;
  try {
    const res = await fetch('/api/question', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ role: currentRole }),
    });
    const data = await res.json();
    if (data.error) { showError(data.error); return; }
    currentQuestion = data.question;
    qCount += 1;
    questionIndex.textContent = `Q · ${String(qCount).padStart(2, '0')}`;
    questionText.textContent = currentQuestion;
    answerInput.value = '';
    feedbackBlock.hidden = true;
    submitBtn.disabled = false;
  } catch (err) {
    showError('Could not reach the server. Is it running?');
  } finally {
    setLoading(false);
  }
}

async function submitAnswer() {
  const answer = answerInput.value.trim();
  if (!answer) return;
  setLoading(true);
  submitBtn.disabled = true;
  errorText.hidden = true;
  try {
    const res = await fetch('/api/feedback', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ role: currentRole, question: currentQuestion, answer }),
    });
    const data = await res.json();
    if (data.error) { showError(data.error); return; }
    feedbackText.textContent = data.feedback;
    feedbackBlock.hidden = false;
  } catch (err) {
    showError('Could not reach the server. Is it running?');
  } finally {
    setLoading(false);
    submitBtn.disabled = false;
  }
}

function setLoading(isLoading) {
  statusEl.classList.toggle('loading', isLoading);
  statusEl.querySelector('.status-label').textContent = isLoading ? 'THINKING' : 'READY';
}

function showError(msg) {
  errorText.textContent = msg;
  errorText.hidden = false;
}

newQuestionBtn.addEventListener('click', fetchQuestion);
submitBtn.addEventListener('click', submitAnswer);

loadRoles();

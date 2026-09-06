// AI Interview Coach — frontend logic
// Talks to the same three JSON routes app.py has always exposed:
//   GET  /api/roles
//   POST /api/question   { role }              -> { question }
//   POST /api/feedback   { role, question, answer } -> { feedback }
//
// This file is loaded from CloudFront, but it calls back to whatever origin
// the page itself was loaded from (the ALB), so no CORS setup is needed —
// relative fetch() URLs still resolve against the page's own host.

const roleSelect = document.getElementById("role-select");
const getQuestionBtn = document.getElementById("get-question-btn");
const newQuestionBtn = document.getElementById("new-question-btn");
const tryAgainBtn = document.getElementById("try-again-btn");
const submitAnswerBtn = document.getElementById("submit-answer-btn");

const questionStep = document.getElementById("question-step");
const feedbackStep = document.getElementById("feedback-step");
const questionText = document.getElementById("question-text");
const answerInput = document.getElementById("answer-input");
const feedbackText = document.getElementById("feedback-text");
const feedbackLoading = document.getElementById("feedback-loading");
const errorBanner = document.getElementById("error-banner");

let currentRole = null;
let currentQuestion = null;

function showError(message) {
  errorBanner.textContent = message;
  errorBanner.classList.remove("hidden");
}

function clearError() {
  errorBanner.classList.add("hidden");
  errorBanner.textContent = "";
}

function resetToQuestionStep() {
  feedbackStep.classList.add("hidden");
  questionStep.classList.remove("hidden");
  answerInput.value = "";
  answerInput.focus();
}

async function loadRoles() {
  try {
    const response = await fetch("/api/roles");
    if (!response.ok) throw new Error("Failed to load roles");
    const roles = await response.json();

    roleSelect.innerHTML = "";
    Object.entries(roles).forEach(([value, label]) => {
      const option = document.createElement("option");
      option.value = value;
      option.textContent = label;
      roleSelect.appendChild(option);
    });

    roleSelect.disabled = false;
    getQuestionBtn.disabled = false;
  } catch (exc) {
    showError("Could not load roles. Refresh the page to try again.");
  }
}

async function getQuestion() {
  clearError();
  currentRole = roleSelect.value;
  getQuestionBtn.disabled = true;

  try {
    const response = await fetch("/api/question", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ role: currentRole }),
    });
    const data = await response.json();

    if (!response.ok) {
      showError(data.error || "Could not get a question. Try again.");
      return;
    }

    currentQuestion = data.question;
    questionText.textContent = currentQuestion;
    questionStep.classList.remove("hidden");
    feedbackStep.classList.add("hidden");
    answerInput.value = "";
    answerInput.focus();
  } catch (exc) {
    showError("Could not reach the server. Check your connection and try again.");
  } finally {
    getQuestionBtn.disabled = false;
  }
}

async function submitAnswer() {
  clearError();
  const answer = answerInput.value.trim();

  if (!answer) {
    showError("Type an answer before submitting.");
    return;
  }

  submitAnswerBtn.disabled = true;
  questionStep.classList.add("hidden");
  feedbackStep.classList.remove("hidden");
  feedbackLoading.classList.remove("hidden");
  feedbackText.textContent = "";

  try {
    const response = await fetch("/api/feedback", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        role: currentRole,
        question: currentQuestion,
        answer,
      }),
    });
    const data = await response.json();

    if (!response.ok) {
      showError(data.error || "Could not get feedback. Try again.");
      questionStep.classList.remove("hidden");
      feedbackStep.classList.add("hidden");
      return;
    }

    feedbackText.textContent = data.feedback;
  } catch (exc) {
    showError("Could not reach the server. Check your connection and try again.");
    questionStep.classList.remove("hidden");
    feedbackStep.classList.add("hidden");
  } finally {
    feedbackLoading.classList.add("hidden");
    submitAnswerBtn.disabled = false;
  }
}

getQuestionBtn.addEventListener("click", getQuestion);
newQuestionBtn.addEventListener("click", getQuestion);
tryAgainBtn.addEventListener("click", () => {
  clearError();
  getQuestion();
});
submitAnswerBtn.addEventListener("click", submitAnswer);

loadRoles();

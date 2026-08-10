# AI Interview Coach (v1)

Pick a role, get an interview question, type an answer, get short AI feedback.
This is the "application workload" for the AWS Cloud/DevOps portfolio project —
the point of this repo is not the app itself, it's everything you build *around* it.

## How it's built (know this cold)

- **Frontend:** plain HTML/CSS/JS, no framework, no build step (`templates/index.html`,
  `static/style.css`, `static/script.js`). The browser calls the backend with `fetch()`.
- **Backend:** Python + Flask, one file (`app.py`). Three JSON API routes:
  - `GET /api/roles` — returns the list of roles
  - `POST /api/question` — returns a random question for a role
  - `POST /api/feedback` — sends the question + your answer to the Anthropic API, returns feedback
- **Port:** 5000 by default (set by the `PORT` env var).
- **Secret:** one — `GEMINI_API_KEY`. It's read from an environment variable in `app.py`
  (`genai.Client()` picks it up automatically). It is never written into any file that
  gets committed to Git.
- **Data:** none persisted. No database. Questions live in a Python dict in `app.py`.
- **Cost:** $0. This uses Google's Gemini API free tier, which needs no credit card on
  file. Worst case if you hit the daily/per-minute quota is a rate-limit error in the
  app — not a bill. There's no billing account attached, so there's nothing to charge.

## Run it locally (no Docker yet)

1. Get a free API key at https://aistudio.google.com/app/apikey — sign in with a Google
   account, click "Create API key." No credit card, no billing setup.
2. Copy the env file and add your key:
   ```
   cp .env.example .env
   ```
   Then edit `.env` and paste your key after `ANTHROPIC_API_KEY=`.
3. Create a virtual environment and install dependencies:
   ```
   python3 -m venv venv
   source venv/bin/activate      # Windows: venv\Scripts\activate
   pip install -r requirements.txt
   ```
4. Run it:
   ```
   python app.py
   ```
5. Open http://localhost:5000 in your browser.

## Run it with Docker (once you're on that stage)

```
docker build -t ai-interview-coach .
docker run -p 5000:5000 -e GEMINI_API_KEY=your-key-here ai-interview-coach
```

Same app, same code — now it's a portable container that will run the same way on your
laptop or on an AWS EC2 instance.

## Notes / possible improvements later

- Swap `model="gemini-2.5-flash"` in `app.py` for `"gemini-2.5-pro"` for higher-quality
  feedback — but the free tier only allows ~50 Pro requests/day vs. 1,500 for Flash.
- Free-tier traffic may be used by Google to improve their models. Fine for fake interview
  Q&A; if that ever matters for a different project, a paid tier turns data-sharing off.
- Add a `/health` route once you get to Phase 3 — ALB health checks need something to hit.
- No login, database, or history yet — intentionally, per the blueprint's "don't be a software
  engineer first" rule.

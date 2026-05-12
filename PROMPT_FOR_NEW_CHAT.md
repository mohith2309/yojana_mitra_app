# Prompt for New Chat — 24/7 Autonomous Agent Setup

Copy-paste this entire prompt into a new Claude/ChatGPT chat to set up your 24/7 agent.

---

## PROMPT START HERE ↓↓↓

I'm building **BharatSeva** — a voice-first AI platform that solves 5 real problems for Indian citizens using government free APIs:

1. **YojanaMitra** — Welfare scheme discovery (1000+ schemes from myScheme.gov.in)
2. **AushadhSathi** — Cheap medicine finder (Jan Aushadhi substitutes)
3. **Annapurna** — Mandi price forecasts (Agmarknet)
4. **VayuMitra** — Pollution-aware route planning (CPCB AQI)
5. **PathSetu** — Disaster early warning (CWC flood + IMD weather)

**Tech Stack:**
- Backend: FastAPI + Chroma (vector DB) + Groq LLM + Bhashini (voice ASR/TTS)
- Frontend: Next.js + React + Tailwind + shadcn/ui
- APIs: myScheme, Jan Aushadhi, Agmarknet, CPCB, CWC, IMD, DigiLocker
- Free to run (₹0/month)

**What I need:**

I want to set up a **24/7 autonomous agent** that:
- Runs automatically every 6 hours
- Analyzes project status (what's done, what's not)
- Decides what task to do next (intelligently)
- Executes the task (write code, run tests, deploy, integrate data)
- Commits results to GitHub
- Sends me status updates

**Best tool for this:** GitHub Actions + Claude API (free, reliable, 24/7)

**What I want you to do:**

1. **Create complete, production-ready agent code** that I can copy-paste into my GitHub repo
2. **Provide the GitHub Actions workflow file** (.github/workflows/agent.yml)
3. **Write the agent orchestrator** (Python script that decides what to do next)
4. **Provide clear step-by-step setup instructions** (I'll follow them exactly)
5. **Give me the system prompt** the agent should use
6. **Include examples** of what the agent should do in each phase

**Project files I already have:**

```
bharatseva/
├── UNIFIED_APP_ARCHITECTURE.md
├── unified_backend.py (700 lines, FastAPI with all 5 modules)
├── unified_frontend.tsx (900 lines, React with domain tabs)
├── UNIFIED_SETUP.md (setup guide)
├── README_BHARATSEVA_UNIFIED.md (marketing)
└── .gitignore
```

**API keys I have:**
- GROQ_API_KEY (for LLM inference)
- BHASHINI_API_KEY (for voice)
- API_SETU_CLIENT_ID & SECRET (for DigiLocker)
- CLAUDE_API_KEY (for agent reasoning)
- GITHUB_TOKEN (for commits)

**What the agent should progressively do:**

Phase 1 (Days 1-3): Testing & QA
- [ ] Run pytest on unified_backend.py
- [ ] Run Next.js build check
- [ ] Verify all imports work
- [ ] Test API key setup

Phase 2 (Days 4-6): Data Integration
- [ ] Scrape myScheme.gov.in (1000+ schemes into JSON)
- [ ] Download Jan Aushadhi medicine list + Kendra locations
- [ ] Fetch Agmarknet real-time prices
- [ ] Get CPCB AQI monitoring station list
- [ ] Get CWC flood warning station locations

Phase 3 (Days 7-9): API Integration Testing
- [ ] Test Groq API calls with mock data
- [ ] Test Bhashini ASR (speech-to-text)
- [ ] Test Bhashini TTS (text-to-speech)
- [ ] Test API Setu DigiLocker sandbox
- [ ] Verify Chroma vector DB initialization

Phase 4 (Days 10-12): Deployment
- [ ] Deploy backend to Railway.io free tier
- [ ] Deploy frontend to Vercel free tier
- [ ] Run smoke tests (health checks)
- [ ] Setup CI/CD integration

Phase 5+ (Days 13+): Polish & Testing
- [ ] Write integration tests (E2E scenarios)
- [ ] Create user testing plan
- [ ] Generate demo video script
- [ ] Optimize bundle sizes
- [ ] Performance testing

**Output I need from you:**

1. **agent_orchestrator.py** — Main agent script (decision-making logic)
2. **.github/workflows/agent.yml** — GitHub Actions workflow
3. **notify_status.py** — Status notification script (Discord/Slack)
4. **Step-by-step setup guide** (literally copy-paste commands)
5. **System prompt** (what the agent should "think" like)
6. **Troubleshooting guide** (what to do if agent fails)

**Format your response as:**

```
## File 1: agent_orchestrator.py
[complete, runnable Python code]

## File 2: .github/workflows/agent.yml
[complete YAML workflow]

## File 3: notify_status.py
[complete Python code]

## Setup Instructions
[numbered steps]

## System Prompt
[prompt to use]

## Example Agent Decisions
[3-4 examples of what agent will do]
```

**Important notes:**
- Agent should be **autonomous but cautious** (don't deploy without sanity checks)
- Agent should **log all decisions** (.agent_log.json)
- Agent should **commit to Git** after each step
- Agent should **fail gracefully** (don't crash, just log and skip)
- Agent should **respect API rate limits** (Groq: 30 req/min free)
- Agent should run **without human intervention**

**I'm ready to:**
- Add your files to my GitHub repo
- Add API keys to GitHub Secrets
- Push to GitHub
- Watch it run 24/7
- Monitor progress via Discord notifications
- Deploy to production

Please give me complete, production-ready code I can use immediately.

## PROMPT END ↑↑↑

---

## How to Use This Prompt

1. **Open a new Claude/ChatGPT chat**
2. **Copy the entire section between "PROMPT START HERE" and "PROMPT END"**
3. **Paste it into the chat**
4. **Hit enter and wait for the response**

The AI will give you complete code + setup instructions you can follow step-by-step.

---

## What to Do With the Response

Once you get the response with all the files:

```bash
# 1. Create the files in your repo
mkdir -p .github/workflows
touch agent_orchestrator.py
touch notify_status.py

# 2. Paste the code from the AI response into these files

# 3. Add API secrets to GitHub
# Go to: GitHub → Settings → Secrets and variables → Actions
# Add each secret (CLAUDE_API_KEY, GROQ_API_KEY, etc.)

# 4. Push everything
git add -A
git commit -m "Setup: 24/7 autonomous agent"
git push origin main

# 5. Watch it run
# Go to: GitHub → Actions → BharatSeva Agent
```

---

**You're ready. Go to a new chat and paste the prompt above.** 🚀

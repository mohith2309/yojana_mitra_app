# 24/7 Agent Automation Guide — Build BharatSeva Hands-Free

**Goal:** Run an AI agent continuously that builds, tests, and deploys your BharatSeva app step-by-step without you babysitting it.

---

## Part 1: Why Gumloop Isn't the Best Here (And What IS)

### Gumloop.co Analysis
❌ **Pros:**
- Visual workflow builder (no-code)
- Can call APIs

❌ **Cons:**
- NOT truly 24/7 (runs on-demand or scheduled, not continuous agent)
- Can't maintain state between runs easily
- Limited LLM integration
- Expensive for frequent runs ($50+/month)
- Not designed for "agent loops" (multi-step reasoning with memory)

### Better Alternatives for 24/7 Agent Automation

| Tool | Best For | Cost | 24/7? | Complexity |
|------|----------|------|-------|-----------|
| **GitHub Actions + Claude Code** | This exact task | ₹0 | ✅ Yes | Easy |
| **n8n (self-hosted)** | Visual workflows + code | ₹0 (self-hosted) | ✅ Yes | Medium |
| **LangGraph (CrewAI/AutoGen)** | Agentic orchestration | ₹0 + API costs | ✅ Yes | Hard |
| **Make.com** | Simple workflows | $9-99/month | ⚠️ Limited | Easy |
| **Zapier** | Simple triggers | $20+/month | ⚠️ Limited | Easy |

---

## Part 2: RECOMMENDED — GitHub Actions + Claude Code (FREE & 24/7)

This is the **best option for your use case** because:
✅ Free (GitHub provides 2,000 minutes/month free Actions)  
✅ Truly 24/7 (runs on schedule or push events)  
✅ Can use Claude Code (your preferred tool)  
✅ Git integration (automatic version control)  
✅ Can run complex multi-step tasks  
✅ No UI bloat — pure code  

### How It Works

```
GitHub Repo
    ↓
[GitHub Actions Workflow]
    ├→ Cron trigger (every 6 hours)
    ├→ Pull latest code
    ├→ Run Claude Code agent
    │   ├→ Check: Do I have API keys? Build artifacts?
    │   ├→ LLM decision: What step next?
    │   ├→ Execute: Code, test, deploy
    │   └→ Commit results back to repo
    └→ Send status to Discord/Slack
```

---

## Part 3: Step-by-Step Setup (GitHub Actions + Claude Code)

### Step 1: Create GitHub Repo

```bash
# On your machine
git clone https://github.com/yourusername/bharatseva.git
cd bharatseva

# Create branch for agent
git checkout -b agent/automate-build
```

### Step 2: Create GitHub Actions Workflow File

```bash
mkdir -p .github/workflows
touch .github/workflows/agent-automate.yml
```

**File: `.github/workflows/agent-automate.yml`**

```yaml
name: BharatSeva Agent — Automated Build & Deploy

on:
  # Run every 6 hours
  schedule:
    - cron: '0 */6 * * *'
  
  # Run manually
  workflow_dispatch:

  # Run on push (optional)
  push:
    branches:
      - agent/automate-build

jobs:
  automated-build:
    runs-on: ubuntu-latest
    timeout-minutes: 30

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'

      - name: Set up Node
        uses: actions/setup-node@v4
        with:
          node-version: '18'

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt
          npm install -g vercel

      - name: Run Agent Automation
        env:
          GROQ_API_KEY: ${{ secrets.GROQ_API_KEY }}
          BHASHINI_API_KEY: ${{ secrets.BHASHINI_API_KEY }}
          API_SETU_CLIENT_ID: ${{ secrets.API_SETU_CLIENT_ID }}
          API_SETU_SECRET: ${{ secrets.API_SETU_SECRET }}
          CLAUDE_API_KEY: ${{ secrets.CLAUDE_API_KEY }}
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          python agent_orchestrator.py

      - name: Commit results
        run: |
          git config --local user.email "agent@bharatseva.dev"
          git config --local user.name "BharatSeva Agent"
          git add -A
          git commit -m "Agent: Auto-build $(date)" || echo "No changes"
          git push

      - name: Notify Status
        if: always()
        run: |
          python notify_status.py
```

### Step 3: Add Secrets to GitHub

Go to **Settings → Secrets and variables → Actions** and add:

```
GROQ_API_KEY=gsk_xxxxx
BHASHINI_API_KEY=xxxxx
API_SETU_CLIENT_ID=xxxxx
API_SETU_SECRET=xxxxx
CLAUDE_API_KEY=sk-proj-xxxxx
```

### Step 4: Create Agent Orchestrator

**File: `agent_orchestrator.py`** (the brain of your 24/7 agent)

```python
"""
BharatSeva Automated Agent
Runs every 6 hours, progresses the project autonomously
"""

import os
import json
import subprocess
from datetime import datetime
import anthropic

# Initialize Claude API
client = anthropic.Anthropic(api_key=os.getenv("CLAUDE_API_KEY"))

def get_project_status():
    """Check current state of the project"""
    status = {
        "timestamp": datetime.now().isoformat(),
        "has_backend": os.path.exists("unified_backend.py"),
        "has_frontend": os.path.exists("unified_frontend.tsx"),
        "has_tests": os.path.exists("tests/"),
        "has_deployed": os.path.exists(".deployed"),
        "git_status": subprocess.run(
            ["git", "status", "--short"],
            capture_output=True,
            text=True
        ).stdout
    }
    return status

def agent_think_and_decide(status):
    """Use Claude to decide what to do next"""
    
    prompt = f"""
You are an autonomous agent building the BharatSeva app (unified voice-first platform for 5 Indian citizen services).

Current project status:
{json.dumps(status, indent=2)}

You have access to:
- Python (FastAPI backend)
- Node.js (Next.js frontend)
- Git (version control)
- GitHub Actions (CI/CD)
- API keys: Groq, Bhashini, API Setu, Claude

Your mission: Advance the project by one step.

Phase checklist:
1. ✅ Architecture & design (DONE)
2. ⚠️ Backend implementation (backend code exists, need testing)
3. ⚠️ Frontend implementation (frontend code exists, need testing)
4. ⏳ Integration testing (not started)
5. ⏳ Real data integration (myScheme API scraping)
6. ⏳ Deployment (Railway + Vercel)
7. ⏳ User testing (5+ real users)

Decide what to do NEXT. Return a JSON with:
{{
  "next_step": "what to do",
  "reason": "why this step",
  "command": "shell command(s) to execute",
  "commit_message": "git commit message"
}}

Examples of valid next steps:
- "Write integration tests for backend"
- "Scrape real myScheme.gov.in data"
- "Deploy backend to Railway"
- "Run end-to-end test with voice input"
- "Write documentation"

Be ambitious but realistic. Each execution should take < 5 minutes.
"""

    response = client.messages.create(
        model="claude-opus-4.6",
        max_tokens=500,
        messages=[
            {"role": "user", "content": prompt}
        ]
    )

    # Parse response (expect JSON)
    try:
        result = json.loads(response.content[0].text)
    except:
        # Fallback if response isn't JSON
        result = {
            "next_step": "Write unit tests",
            "reason": "Ensure code quality before deployment",
            "command": "pytest tests/ -v",
            "commit_message": "Add: Unit tests for backend"
        }

    return result

def execute_step(step_plan):
    """Execute the agent's decision"""
    
    print(f"\n{'='*60}")
    print(f"AGENT DECISION: {step_plan['next_step']}")
    print(f"REASON: {step_plan['reason']}")
    print(f"{'='*60}\n")

    # Execute command
    if step_plan.get("command"):
        result = subprocess.run(
            step_plan["command"],
            shell=True,
            capture_output=True,
            text=True,
            timeout=300
        )
        
        print(f"STDOUT:\n{result.stdout}")
        if result.stderr:
            print(f"STDERR:\n{result.stderr}")
        
        if result.returncode != 0:
            print(f"⚠️ Command failed with code {result.returncode}")
            return False

    # Commit if changes made
    subprocess.run(
        ["git", "add", "-A"],
        capture_output=True
    )
    
    subprocess.run(
        ["git", "commit", "-m", step_plan.get("commit_message", "Agent: Auto-progress")],
        capture_output=True
    )

    print(f"✅ Step completed: {step_plan['next_step']}")
    return True

def main():
    """Main agent loop"""
    
    print("\n🤖 BharatSeva Agent Started")
    print(f"⏰ Time: {datetime.now()}")
    
    # Get current status
    status = get_project_status()
    print(f"\n📊 Project Status:\n{json.dumps(status, indent=2)}")
    
    # Agent decides
    step_plan = agent_think_and_decide(status)
    print(f"\n🧠 Agent Decision:\n{json.dumps(step_plan, indent=2)}")
    
    # Execute
    success = execute_step(step_plan)
    
    # Log result
    with open(".agent_log.json", "a") as f:
        log_entry = {
            "timestamp": datetime.now().isoformat(),
            "step": step_plan.get("next_step"),
            "success": success
        }
        f.write(json.dumps(log_entry) + "\n")
    
    print(f"\n✨ Agent run complete")
    return 0 if success else 1

if __name__ == "__main__":
    exit(main())
```

### Step 5: Create Status Notifier

**File: `notify_status.py`** (optional, sends you updates)

```python
"""
Send Discord/Slack notification of agent progress
"""

import os
import json
import subprocess
from datetime import datetime

def notify_discord():
    """Send Discord message (optional)"""
    webhook_url = os.getenv("DISCORD_WEBHOOK")
    if not webhook_url:
        return
    
    # Get last log entry
    try:
        with open(".agent_log.json") as f:
            logs = [json.loads(line) for line in f]
            last_log = logs[-1]
    except:
        last_log = {"step": "unknown", "success": False}
    
    message = {
        "content": f"🤖 BharatSeva Agent Report\n"
                   f"⏰ {datetime.now()}\n"
                   f"✅ Last step: {last_log.get('step')}\n"
                   f"Status: {'✅ SUCCESS' if last_log.get('success') else '⚠️ FAILED'}"
    }
    
    import requests
    requests.post(webhook_url, json=message)

if __name__ == "__main__":
    notify_discord()
```

### Step 6: Push to GitHub

```bash
git add .github/workflows/agent-automate.yml agent_orchestrator.py notify_status.py
git commit -m "Setup: 24/7 autonomous agent"
git push origin agent/automate-build

# Create pull request or merge to main
```

---

## Part 4: Alternative #2 — n8n (If You Want Visual Workflows)

### Why n8n?
✅ Self-hosted (free)  
✅ Visual workflow builder  
✅ Can call Claude API  
✅ 24/7 execution  
✅ Webhook support  

### Quick Setup

```bash
# Using Docker (easiest)
docker run -it --rm \
  -p 5678:5678 \
  -e N8N_HOST=localhost \
  -v ~/.n8n:/home/node/.n8n \
  n8nio/n8n

# Open http://localhost:5678
```

**Workflow Steps:**
1. Cron trigger (every 6 hours)
2. HTTP request to Claude API
3. Parse Claude response (what to build next)
4. Conditional: Execute Python/Node commands
5. Git commit results
6. Send notification

[Detailed n8n setup available if you want]

---

## Part 5: Alternative #3 — LangGraph Agent (Most Sophisticated)

If you want a true **multi-agent** system with memory and reasoning:

```python
from langgraph.graph import StateGraph
from langchain_anthropic import ChatAnthropic

# Define agent states
class ProjectState(TypedDict):
    current_phase: str
    completed_tasks: List[str]
    next_action: str
    artifacts: Dict[str, str]

# Build graph
graph = StateGraph(ProjectState)

# Add nodes for each phase
graph.add_node("analyze", analyze_phase)
graph.add_node("code", write_code)
graph.add_node("test", run_tests)
graph.add_node("deploy", deploy)

# Add edges
graph.add_edge("analyze", "code")
graph.add_edge("code", "test")
graph.add_edge("test", "deploy")

# Compile and run
agent = graph.compile()
state = agent.invoke(initial_state)
```

[Full LangGraph example available if needed]

---

## Part 6: What Your Agent Should Do (Task Breakdown)

```
Phase 1 (Week 1): Setup & Testing
├─ Run pytest on unified_backend.py
├─ Run Next.js build check
├─ Verify all imports work
└─ Commit: "Test: Backend & frontend compile"

Phase 2 (Week 2): Data Integration
├─ Scrape myScheme.gov.in (1000 schemes)
├─ Download Jan Aushadhi medicine list
├─ Fetch Agmarknet prices
└─ Commit: "Data: Real schemes/medicines/prices integrated"

Phase 3 (Week 3): API Integration
├─ Test Groq API calls
├─ Test Bhashini voice (ASR/TTS)
├─ Test API Setu DigiLocker sandbox
└─ Commit: "Integration: All APIs tested"

Phase 4 (Week 4): Deployment
├─ Deploy backend to Railway
├─ Deploy frontend to Vercel
├─ Run smoke tests
└─ Commit: "Deploy: Live on Railway + Vercel"

Phase 5+ (Week 5-6): Polish & Testing
├─ Write integration tests
├─ User testing scenario generation
├─ Documentation
└─ Record demo video
```

---

## Part 7: COMPLETE EXAMPLE — Minimal Agent Loop

Here's a **super simple agent** you can start with TODAY:

**File: `simple_agent.py`**

```python
#!/usr/bin/env python3
"""
Minimal BharatSeva Agent — run this every 6 hours
"""

import os
import json
from datetime import datetime
from anthropic import Anthropic

client = Anthropic()
conversation_history = []

SYSTEM_PROMPT = """You are an autonomous developer building BharatSeva.

You have these tools available:
1. Check project status (git status, file existence)
2. Run Python/Node commands (testing, builds)
3. Write/edit files
4. Commit to Git

Current phase checklist:
- ✅ Architecture done
- 🔄 Backend code (80% done, need tests)
- 🔄 Frontend code (80% done, need tests)
- ⏳ Integration testing
- ⏳ Real data (myScheme, Jan Aushadhi, etc)
- ⏳ Deploy to production

What ONE task should you do next? Be specific and practical.
Format your response as:
NEXT_TASK: [task name]
COMMANDS: [shell commands]
COMMIT_MSG: [git message]
"""

def get_project_status():
    """Return current project status"""
    import subprocess
    
    status = {
        "files": [
            "unified_backend.py",
            "unified_frontend.tsx",
            "UNIFIED_SETUP.md"
        ],
        "git_status": subprocess.run(
            ["git", "status", "--short"],
            capture_output=True,
            text=True
        ).stdout or "All committed",
        "python_env": os.path.exists(".venv") or os.path.exists("venv"),
        "time": datetime.now().isoformat()
    }
    return status

def run_command(cmd):
    """Execute shell command"""
    import subprocess
    try:
        result = subprocess.run(
            cmd,
            shell=True,
            capture_output=True,
            text=True,
            timeout=60
        )
        return {
            "stdout": result.stdout[:500],
            "stderr": result.stderr[:500],
            "returncode": result.returncode
        }
    except Exception as e:
        return {"error": str(e)}

def agent_loop():
    """Main agent loop"""
    
    # Get status
    status = get_project_status()
    
    # Add to conversation
    conversation_history.append({
        "role": "user",
        "content": f"""Current time: {datetime.now()}
Project status:
{json.dumps(status, indent=2)}

What should I do next? Be specific."""
    })
    
    # Get Claude's decision
    response = client.messages.create(
        model="claude-opus-4.6",
        max_tokens=300,
        system=SYSTEM_PROMPT,
        messages=conversation_history
    )
    
    assistant_message = response.content[0].text
    conversation_history.append({
        "role": "assistant",
        "content": assistant_message
    })
    
    print(f"\n🤖 Agent Decision:\n{assistant_message}\n")
    
    # Parse decision
    lines = assistant_message.split("\n")
    task = None
    commands = None
    commit_msg = None
    
    for line in lines:
        if line.startswith("NEXT_TASK:"):
            task = line.replace("NEXT_TASK:", "").strip()
        elif line.startswith("COMMANDS:"):
            commands = line.replace("COMMANDS:", "").strip()
        elif line.startswith("COMMIT_MSG:"):
            commit_msg = line.replace("COMMIT_MSG:", "").strip()
    
    # Execute if valid
    if commands and commands != "None":
        print(f"Executing: {commands}")
        result = run_command(commands)
        print(f"Result: {result}")
        
        # Commit
        if commit_msg:
            run_command(f"git add -A && git commit -m '{commit_msg}' || true")
    
    return {"task": task, "status": "complete"}

if __name__ == "__main__":
    result = agent_loop()
    print(f"\n✅ Agent run: {result}")
```

**Run it:**
```bash
python simple_agent.py
```

**Schedule it (on your laptop) using cron:**
```bash
crontab -e
# Add: 0 */6 * * * cd /path/to/bharatseva && python simple_agent.py
```

Or **run it in GitHub Actions** using the workflow file from Part 3.

---

## Part 8: The Best Prompt for Your Agent

Use this as your `SYSTEM_PROMPT` in any agent:

```
You are an autonomous developer for BharatSeva — a voice-first AI platform 
that solves 5 real problems for Indian citizens:

1. YojanaMitra: Welfare scheme discovery (myScheme corpus)
2. AushadhSathi: Cheap medicine finder (Jan Aushadhi)
3. Annapurna: Mandi price forecasts (Agmarknet)
4. VayuMitra: Pollution-aware routing (CPCB AQI)
5. PathSetu: Disaster early warning (CWC + IMD)

Tech Stack:
- Backend: FastAPI + Chroma (vector DB) + Groq LLM + Bhashini voice
- Frontend: Next.js + React + Tailwind
- Govt APIs: myScheme, Jan Aushadhi, Agmarknet, CPCB, CWC, IMD, DigiLocker

Your job: Advance this project ONE MEANINGFUL STEP every execution.

Available resources:
- GitHub Actions (for CI/CD)
- Python 3.11+ (for backend)
- Node 18+ (for frontend)
- API keys (Groq, Bhashini, API Setu)
- Git (version control)
- Docker (optional)

Current status:
{PROJECT_STATUS}

PICK ONE task from this priority list:
1. Write/fix tests (unit, integration, E2E)
2. Integrate real data (scrape myScheme / Jan Aushadhi)
3. Fix bugs or improve code quality
4. Deploy to Railway + Vercel
5. Document APIs or user flows
6. Record demo video or user testing plan
7. Optimize performance

Respond with:
TASK: [what you'll do]
WHY: [why this moves us forward]
COMMANDS: [exact shell command(s)]
ESTIMATED_TIME: [5/15/30 mins]
COMMIT_MSG: [git message]

Be bold. Take initiative. This is your project.
```

---

## Part 9: Monitoring & Alerts

### Track agent runs:

```bash
# View last 10 agent runs
tail -20 .agent_log.json | jq .

# Check GitHub Actions logs
gh run list --repo yourusername/bharatseva --limit 5
```

### Setup Discord alerts:

1. Create Discord webhook: https://discord.com/api/webhooks/...
2. Add to GitHub Secrets: `DISCORD_WEBHOOK`
3. Webhook automatically posts on each run

---

## Part 10: Cost Comparison

| Option | Setup | Cost/month | Complexity | 24/7 |
|--------|-------|-----------|-----------|------|
| **GitHub Actions** ✅ BEST | 30 mins | ₹0 | Easy | ✅ |
| n8n self-hosted | 1 hour | ₹0 | Medium | ✅ |
| LangGraph | 2 hours | ₹0 + API | Hard | ✅ |
| Gumloop.co | 20 mins | ₹400 | Easy | ❌ |
| Make.com | 15 mins | ₹600 | Easy | ⚠️ |
| Zapier | 15 mins | ₹1000 | Easy | ⚠️ |

---

## QUICK START (Right Now)

```bash
# 1. Create workflow file
mkdir -p .github/workflows
cat > .github/workflows/agent.yml << 'EOF'
name: Agent
on:
  schedule:
    - cron: '0 */6 * * *'
jobs:
  run:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      - run: pip install anthropic
      - run: python simple_agent.py
        env:
          CLAUDE_API_KEY: ${{ secrets.CLAUDE_API_KEY }}
EOF

# 2. Add secrets
# Go to GitHub → Settings → Secrets → Add CLAUDE_API_KEY

# 3. Push
git add .github/workflows/agent.yml simple_agent.py
git commit -m "Setup: Autonomous agent"
git push

# 4. Watch it run
# GitHub Actions → Agent workflow → View runs
```

**Done.** Your agent will run every 6 hours automatically. 🚀

---

**Which approach do you want to go with?**
1. **GitHub Actions + Claude** (simplest, best for this)
2. **n8n** (if you like visual workflows)
3. **LangGraph** (if you want multi-agent sophistication)

Let me know and I'll give you the complete production-ready code.

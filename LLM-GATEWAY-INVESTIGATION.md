# LLM Gateway Investigation for Multi-Model Claude Code Support

**Created:** 2026-01-08
**Status:** Investigation Phase
**Goal:** Enable seamless model switching in Claude Code between GLM-4.7 (Z.ai) and Claude models

---

## Problem Statement

Claude Code does not support adding custom models to the startup model selection menu. Current solutions:

**Current State (Working):**
- Wrapper scripts (`claude-glm`, `claude-opus`) provide model switching
- Clean, no auth conflicts
- Requires knowing command upfront

**Desired State:**
- Use Claude Code's built-in `/model` command to switch between all models
- Model names appear as options in Claude Code
- Seamless switching without restarting sessions

---

## Solution Architecture: LLM Gateway

An LLM gateway sits between Claude Code and model providers, routing requests based on model name:

```
┌─────────────┐
│ Claude Code │ --model=glm-4.7--> ┌─────────────┐
│             │                      │ LLM Gateway │ ──> Z.ai (GLM-4.7)
│             │ --model=opus----> │             │ ──> Anthropic (Claude)
└─────────────┘                      └─────────────┘
```

**Configuration:**
```bash
export ANTHROPIC_BASE_URL=http://localhost:4000  # Gateway endpoint
claude --model glm-4.7    # Gateway routes to Z.ai
claude --model opus       # Gateway routes to Anthropic
```

---

## Option 1: LiteLLM Proxy (Recommended)

**Website:** https://docs.litellm.ai/docs/proxy/quick_start
**License:** MIT (Open Source)
**RAM Usage:** ~100-200MB
**Deployment:** Local Python process

### Features

- Multi-provider routing (100+ LLM providers)
- Anthropic-compatible API
- Cost tracking and usage logs
- Caching (reduce API calls)
- Fallback logic (if one provider fails, try another)
- Load balancing across multiple keys
- Budget limits per user/model

### Installation

```bash
# Install LiteLLM
pip install 'litellm[proxy]'

# Verify installation
litellm --version
```

### Configuration

Create `~/dev/infrastructure/goose-integration/litellm_config.yaml`:

```yaml
model_list:
  # Claude models via Anthropic
  - model_name: opus
    litellm_params:
      model: claude-opus-4-5-20251101
      api_key: os.environ/ANTHROPIC_API_KEY

  - model_name: sonnet
    litellm_params:
      model: claude-sonnet-4-5-20250929
      api_key: os.environ/ANTHROPIC_API_KEY

  # GLM models via Z.ai
  - model_name: glm-4.7
    litellm_params:
      model: glm-4.7
      api_base: https://api.z.ai/api/anthropic
      api_key: os.environ/ZAI_API_KEY

  - model_name: glm-4.5
    litellm_params:
      model: GLM-4.5-Air
      api_base: https://api.z.ai/api/anthropic
      api_key: os.environ/ZAI_API_KEY

# Optional: Cost tracking
general_settings:
  database_url: "sqlite:///litellm_usage.db"
  master_key: "sk-1234"  # For admin API access
```

### Starting the Proxy

```bash
# Start LiteLLM proxy
litellm --config ~/dev/infrastructure/goose-integration/litellm_config.yaml \
        --port 4000 \
        --detailed_debug

# Or create a systemd service for auto-start
```

### Claude Code Configuration

**Option A: Global configuration** (~/.bashrc_claude):
```bash
export ANTHROPIC_BASE_URL=http://localhost:4000
```

**Option B: Wrapper script** (~/bin/claude-multi):
```bash
#!/bin/bash
source ~/.bashrc_claude 2>/dev/null
export ANTHROPIC_BASE_URL=http://localhost:4000
exec claude "$@"
```

### Usage

```bash
# Start Claude Code with gateway
claude-multi

# In session, switch models
/model glm-4.7    # Routes to Z.ai
/model opus       # Routes to Anthropic
/model sonnet     # Routes to Anthropic

# Or at startup
claude-multi --model glm-4.7 "Write a function..."
```

### Pros

✅ True multi-model support
✅ Model switching via `/model` command
✅ Cost tracking and analytics
✅ Open source, auditable
✅ Caching reduces API costs
✅ Fallback logic for reliability
✅ Single point for all LLM configuration

### Cons

❌ Requires running local proxy (adds ~100MB RAM)
❌ Additional dependency to maintain
❌ Must start proxy before Claude Code
❌ Latency: +10-50ms per request (localhost routing)
❌ Learning curve for configuration

### Cost Impact

**Baseline (Direct API):**
- GLM-4.7: $0.16/1M input
- Claude Opus: $15/1M input

**With LiteLLM Caching (5% cache hit rate):**
- Effective cost: 95% of baseline
- Savings: ~$0.008/1M for GLM, $0.75/1M for Opus

**With LiteLLM Caching (20% cache hit rate):**
- Effective cost: 80% of baseline
- Savings: ~$0.032/1M for GLM, $3/1M for Opus

---

## Option 2: OpenRouter (Cloud Gateway)

**Website:** https://openrouter.ai/
**License:** Proprietary (Free tier available)
**RAM Usage:** 0 (cloud-hosted)
**Deployment:** No deployment needed

### Features

- 200+ models from 50+ providers
- Anthropic-compatible API
- No infrastructure to manage
- Automatic fallback
- Cost tracking dashboard

### Configuration

**Existing:**
- Already configured in `use-deepseek()` and `use-gemini()` functions
- Z.ai models NOT available via OpenRouter

**Limitation:** Cannot route to Z.ai native endpoint through OpenRouter.

**Workaround:** Use OpenRouter for non-Z.ai models:
```bash
export ANTHROPIC_BASE_URL=https://openrouter.ai/api/v1
export ANTHROPIC_API_KEY=$OPENROUTER_API_KEY

claude --model deepseek/deepseek-reasoner    # Works
claude --model google/gemini-2.0-flash-exp   # Works
claude --model glm-4.7                       # NOT AVAILABLE
```

### Pros

✅ Zero infrastructure
✅ No local resources
✅ Automatic updates
✅ 200+ models available

### Cons

❌ Cannot access Z.ai native endpoint
❌ Adds cost markup (typically 10-20%)
❌ Requires internet for localhost requests
❌ Privacy: requests go through third party

---

## Option 3: Custom Proxy (DIY)

Write a lightweight proxy in Python/Node.js that:
1. Accepts Anthropic-compatible requests
2. Routes based on model name
3. Forwards to appropriate provider

**Minimal Implementation (Python + Flask):**

```python
# ~/dev/infrastructure/goose-integration/simple_proxy.py
from flask import Flask, request, Response
import requests
import os

app = Flask(__name__)

ROUTES = {
    "glm-4.7": {
        "url": "https://api.z.ai/api/anthropic",
        "headers": {"Authorization": f"Bearer {os.getenv('ZAI_API_KEY')}"}
    },
    "opus": {
        "url": "https://api.anthropic.com",
        "headers": {"x-api-key": os.getenv('ANTHROPIC_API_KEY')}
    }
}

@app.route('/v1/messages', methods=['POST'])
def proxy():
    data = request.json
    model = data.get("model")

    if model not in ROUTES:
        return {"error": f"Unknown model: {model}"}, 400

    route = ROUTES[model]
    response = requests.post(
        f"{route['url']}/v1/messages",
        json=data,
        headers=route['headers']
    )
    return Response(response.content, response.status_code)

if __name__ == '__main__':
    app.run(port=4000)
```

**Usage:**
```bash
python simple_proxy.py &
export ANTHROPIC_BASE_URL=http://localhost:4000
claude --model glm-4.7
```

### Pros

✅ Minimal dependencies
✅ Full control over routing logic
✅ Educational value

### Cons

❌ No cost tracking
❌ No caching
❌ No fallback logic
❌ Requires maintenance

---

## Recommendation Matrix

| Criterion | LiteLLM | OpenRouter | Custom | Wrapper Scripts (Current) |
|-----------|---------|------------|--------|----------------------------|
| **Ease of Use** | Medium | High | Low | High |
| **Z.ai Support** | ✅ Yes | ❌ No | ✅ Yes | ✅ Yes |
| **Cost** | Free | +10-20% | Free | Free |
| **RAM** | 100-200MB | 0MB | 50-100MB | 0MB |
| **Features** | Rich | Rich | Minimal | None |
| **Maintenance** | Low | None | High | None |
| **Model Switching** | `/model` | `/model` | `/model` | CLI flag |

---

## Decision Framework

**Choose Wrapper Scripts (Current) if:**
- You rarely switch models mid-session
- You want zero infrastructure overhead
- You're comfortable with CLI flags

**Choose LiteLLM if:**
- You frequently switch models
- You want cost tracking and analytics
- You're okay with 100MB RAM overhead
- You want caching and fallback

**Choose OpenRouter if:**
- You don't need Z.ai native endpoint
- You want zero maintenance
- Privacy is not a concern

**Choose Custom Proxy if:**
- You have specific routing requirements
- You want to learn gateway patterns
- You're willing to maintain code

---

## Deployment Guide: LiteLLM (If Selected)

### Step 1: Install Dependencies

```bash
pip install 'litellm[proxy]'
```

### Step 2: Create Configuration

Save to `~/dev/infrastructure/goose-integration/litellm_config.yaml` (see configuration section above).

### Step 3: Create Startup Script

```bash
cat > ~/bin/litellm-start <<'EOF'
#!/bin/bash
# Start LiteLLM proxy for Claude Code multi-model support
source ~/.bashrc_claude 2>/dev/null
cd ~/dev/infrastructure/goose-integration
litellm --config litellm_config.yaml --port 4000 --detailed_debug
EOF
chmod +x ~/bin/litellm-start
```

### Step 4: Create Wrapper Script

```bash
cat > ~/bin/claude-multi <<'EOF'
#!/bin/bash
# Claude Code with LiteLLM gateway
source ~/.bashrc_claude 2>/dev/null

# Check if LiteLLM is running
if ! curl -s http://localhost:4000/health >/dev/null 2>&1; then
  echo "⚠️  LiteLLM proxy not running. Start with: litellm-start"
  exit 1
fi

export ANTHROPIC_BASE_URL=http://localhost:4000
exec claude "$@"
EOF
chmod +x ~/bin/claude-multi
```

### Step 5: Test

```bash
# Terminal 1: Start proxy
litellm-start

# Terminal 2: Test Claude Code
claude-multi --print "Test message" --model glm-4.7
```

---

## Governance Updates Needed (If Deployed)

1. **AUTHORITATIVE.yaml** - Add litellm entry under `ai_agents` or `infrastructure`
2. **DECISIONS-LOG.md** - Log decision to use gateway (DEC-###)
3. **goose-integration/README.md** - Document gateway setup
4. **goose-integration/CHANGE-LOG.md** - Record gateway deployment

---

## Next Steps

**User Decision Required:**

1. **Stick with wrapper scripts?**
   - Pros: Zero overhead, working solution
   - Cons: No `/model` switching

2. **Deploy LiteLLM gateway?**
   - Pros: True multi-model support, rich features
   - Cons: 100MB RAM, added complexity

3. **Try LiteLLM experimentally?**
   - Deploy to `~/dev/sandbox/litellm-test/`
   - Test for 1-2 weeks
   - Evaluate convenience vs overhead
   - Decide: keep, remove, or promote to production

**Recommendation:** Try experimentally first. Wrapper scripts already solve 90% of the problem.

---

## References

- LiteLLM Documentation: https://docs.litellm.ai/
- LiteLLM Proxy: https://docs.litellm.ai/docs/proxy/quick_start
- OpenRouter: https://openrouter.ai/docs
- Z.ai Claude Docs: https://docs.z.ai/scenario-example/develop-tools/claude
- Session Handoff: `~/.claude/SESSION-HANDOFF-2026-01-08-Z-AI-INTEGRATION.md`

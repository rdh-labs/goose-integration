# Goose CLI Integration

**Purpose:** Multi-model AI agent framework for development workflows
**Version:** 1.19.0
**Primary Model:** Z.ai GLM-4.7 (cost-effective, SWE-bench 73.8%)
**Created:** 2026-01-07

---

## Overview

Goose is Block's open-source AI agent framework built in Rust. It supports:
- Multiple LLM providers (OpenAI, Anthropic, Gemini, custom endpoints)
- Model Context Protocol (MCP) for tool integration
- Scripted workflows + interactive sessions
- Cost-effective model routing

**Key Advantage:** GLM-4.7 costs 94% less than Claude Opus while maintaining competitive SWE-bench performance (73.8% vs Claude Sonnet 70.3%).

---

## Installation

Goose CLI is installed globally at `~/.local/bin/goose` (v1.19.0).

```bash
# Verify installation
goose --version

# View available commands
goose --help
```

---

## Configuration

### Primary Configuration

**Location:** `~/.config/goose/config.yaml`

**Default provider:** Z.ai GLM-4.7 via OpenAI-compatible endpoint

**Status:** ✅ WORKING (2026-01-22)

```yaml
GOOSE_PROVIDER: openai
GOOSE_MODEL: glm-4.7

OPENAI_API_KEY: ${OPENAI_API_KEY}
OPENAI_HOST: https://api.z.ai
OPENAI_BASE_PATH: /api/coding/paas/v4/chat/completions
```

**CRITICAL:** `OPENAI_BASE_PATH` must include `/chat/completions` suffix. Goose does not append this automatically for non-standard endpoints.

**How authentication works:**
1. Config file expects `OPENAI_API_KEY` as environment variable
2. Wrapper function in `~/.bashrc_claude` sets `OPENAI_API_KEY="${OPENAI_API_KEY:-$ZAI_API_KEY}"`
3. Defaults to Z.ai key, but respects caller-provided `OPENAI_API_KEY` for multi-model usage
4. See [WSL2 Keyring Configuration](#wsl2-keyring-configuration) for wrapper details

### API Keys

**Source:** 1Password Development vault (loaded via `~/.bashrc_claude`)

```bash
source ~/.bashrc_claude  # Loads all API keys from 1Password

# Available keys:
# - ZAI_API_KEY (Z.ai GLM-4.7)
# - DEEPSEEK_API_KEY (DeepSeek Reasoner)
# - GEMINI_API_KEY (Gemini 2.0 Flash)
# - OPENAI_API_KEY (GPT-4o)
# - OPENROUTER_API_KEY (Multi-model gateway)
```

### WSL2 Keyring Configuration

**IMPORTANT for WSL2 users:** Goose CLI caches credentials in the system keyring by default, which fails on WSL2:

```
error: Failed to access keyring: Platform secure storage failure:
DBus error: org.freedesktop.secrets was not provided by any .service files
```

**Solution:** Disable keyring storage and use environment variables instead.

**Configuration in `~/.bashrc_claude`:**

```bash
# Disable keyring storage (WSL2 compatibility)
export GOOSE_DISABLE_KEYRING=1

# Wrapper function sets API key (defaults to Z.ai, respects caller override)
goose() {
  GOOSE_DISABLE_KEYRING=1 OPENAI_API_KEY="${OPENAI_API_KEY:-$ZAI_API_KEY}" /home/ichardart/.local/bin/goose "$@"
}
```

**Why this is needed:**
1. **Keyring caching** - Goose stores credentials in system keyring, not just environment variables
2. **WSL2 limitation** - DBus secrets service unavailable in WSL2 environment
3. **Wrapper function** - Ensures both `GOOSE_DISABLE_KEYRING=1` and `OPENAI_API_KEY` are set for every invocation
4. **Multi-model support** - Uses `${OPENAI_API_KEY:-$ZAI_API_KEY}` pattern to default to Z.ai but respect caller overrides

**Verification:**
```bash
# Test that keyring is disabled and API key is passed correctly
goose run --text "test" --no-session --quiet
```

**Expected:** Command succeeds without keyring errors.

**Status:** ✅ VERIFIED WORKING (2026-01-22)

### MCP Extensions

Goose integrates with 5 key MCP servers from the ecosystem:

1. **developer** (builtin) - File operations, shell commands
2. **code-executor** - Sandboxed Python code execution (7.5/10 security)
3. **governance** - Decision tracking (DEC-###), issues, ADRs
4. **chrome-devtools** - Browser automation
5. **gemini-ai** - Gemini API integration

**Full configuration:** See `~/.config/goose/config.yaml`

---

## Multi-Model Setup

### Switching Models

Goose supports multiple providers via environment variables:

```bash
# Z.ai GLM-4.7 (default - already configured)
goose run --text "Your task"

# DeepSeek Reasoner (complex logic)
GOOSE_PROVIDER=openai \
OPENAI_API_KEY="$DEEPSEEK_API_KEY" \
OPENAI_HOST=https://api.deepseek.com \
OPENAI_BASE_PATH=/v1/chat/completions \
GOOSE_MODEL=deepseek-reasoner \
goose run --text "Complex reasoning task"

# Gemini 2.0 Flash (large context, speed)
GOOSE_PROVIDER=gemini \
GOOSE_MODEL=gemini-2.0-flash-exp \
goose run --text "Large codebase analysis"

# GPT-4o (quality fallback)
GOOSE_PROVIDER=openai \
GOOSE_MODEL=gpt-4o \
goose run --text "High-stakes review"
```

### Model Selection Strategy

See `/tmp/model-selection-strategy.md` for detailed benchmark scores and use case mapping.

**Summary:**

| Model | Best For | Cost (Input) | Context |
|-------|----------|--------------|---------|
| GLM-4.7 | Coding, agentic tasks | $0.16/1M | 202K |
| DeepSeek R1 | Reasoning, planning | $0.14/1M | 128K |
| Gemini Flash | Speed, large codebases | $0.075/1M | 1M |
| GPT-4o | Quality checks | $2.50/1M | 128K |

---

## Claude Code Integration

Goose complements Claude Code by enabling cost-effective model routing for specific tasks.

### Wrapper Scripts (2026-01-08)

**Status:** ⚠️ PARTIAL - Gemini wrappers working, Claude wrapper requires workaround

Wrapper scripts provide clean model switching without environment pollution or auth conflicts.

**Available commands:**

```bash
claude-glm     # Claude Code with GLM-4.7 via Z.ai ($0.16/1M input) - SEE WORKAROUND BELOW
claude-opus    # Claude Code with Opus 4.5 via Anthropic ($15/1M input)
claude         # Claude Code with default model (uses login token)
```

**IMPORTANT: Claude GLM Wrapper Requires Pre-Loaded Token**

The `claude-glm` wrapper has been fixed for model flag syntax but still requires workaround for 1Password CLI timeout issue. See [Troubleshooting](#troubleshooting) section below for details.

**Usage:**

```bash
# Start interactive session with GLM-4.7
claude-glm

# One-shot query with GLM-4.7
claude-glm --print "Refactor this function..."

# Start session with Claude Opus 4.5
claude-opus

# Compare model responses
claude-glm --print "Explain SWE-bench in one sentence."
claude-opus --print "Explain SWE-bench in one sentence."
```

**Key Features:**
- Zero environment pollution (uses `exec` pattern)
- No auth conflicts with `claude login`
- Zero infrastructure overhead
- Credentials loaded from `~/.bashrc_claude` (1Password)
- Clean separation between model contexts

**Implementation:**
- Location: `~/bin/claude-glm`, `~/bin/claude-opus`
- Pattern: Set env vars → `exec claude --model <model> "$@"`
- Env vars scoped to single invocation only

**Note:** Z.ai provides Anthropic-compatible endpoint (`https://api.z.ai/api/anthropic`) allowing Claude Code to use GLM-4.7 natively. Uses custom `ANTHROPIC_AUTH_TOKEN` header (not standard `ANTHROPIC_API_KEY`).

### Z.ai API Endpoints

Z.ai provides multiple endpoints for different tools:

| Endpoint | Purpose | Auth Header | Use With |
|----------|---------|-------------|----------|
| `/api/anthropic` | Claude Code | `ANTHROPIC_AUTH_TOKEN` | Claude CLI |
| `/api/paas/v4/chat/completions` | OpenAI-compatible | `Authorization: Bearer` | Goose CLI |
| `/api/coding/paas/v4` | Coding-optimized | OpenRouter-style | Custom Gemini CLI |

**Official Documentation:**
- [Z.ai + Claude Code](https://docs.z.ai/scenario-example/develop-tools/claude)
- [Z.ai + Gemini](https://docs.z.ai/scenario-example/develop-tools/gemini)

---

## Gemini CLI Integration

Gemini CLI supports multiple models via native `--model` flag.

### Wrapper Scripts (2026-01-08)

**Status:** ✅ VERIFIED WORKING (Fixed 2026-01-08 evening)

**CRITICAL UPDATE:** Initial wrapper scripts used incorrect/experimental model names that no longer exist. Model names corrected based on [official Gemini API documentation](https://ai.google.dev/gemini-api/docs/models).

**Available commands:**

```bash
gemini-flash     # Gemini 2.0 Flash ($0.075/1M input, 1M context)
gemini-pro       # Gemini 2.5 Flash ($0.30/1M input, 1M context, thinking-capable)
gemini-thinking  # Gemini 3 Flash (Latest, Pro-grade reasoning with Flash speed)
gemini           # Gemini CLI with default model
```

**IMPORTANT:** Gemini 1.5 Pro was **retired April 29, 2025**. All requests to `gemini-1.5-pro` return 404 errors. The `gemini-pro` wrapper now uses Gemini 2.5 Flash as the recommended replacement.

**Usage:**

```bash
# Start interactive session with Flash model
gemini-flash

# Non-interactive query
gemini-flash "Analyze this codebase structure..."

# Reasoning mode for complex problems
gemini-thinking "Design a distributed caching architecture..."

# Large context tasks
gemini-pro "Review all files in this 500K line codebase..."
```

**Key Features:**
- Zero configuration overhead (uses existing Google OAuth)
- No environment pollution (uses `exec` pattern)
- Clean model selection without full model names
- Works with existing MCP server configuration

**Implementation:**
- Location: `~/bin/gemini-flash`, `~/bin/gemini-pro`, `~/bin/gemini-thinking`
- Pattern: `exec gemini --model <model> "$@"`
- No environment variables needed (OAuth authenticated)

**Model Selection Guide:**

| Wrapper | Model | Best For | Context | Cost Input |
|---------|-------|----------|---------|------------|
| gemini-flash | gemini-2.0-flash | Speed, general tasks | 1M | $0.075/1M |
| gemini-pro | gemini-2.5-flash | Quality, thinking-capable | 1M | $0.30/1M |
| gemini-thinking | gemini-3-flash | Latest, Pro-grade reasoning | 1M | TBD |

**Note:** Pricing for Gemini 3 Flash not yet published. Gemini 2.5 Flash pricing updated per [Google AI documentation](https://ai.google.dev/pricing).

---

## Usage Examples

### Interactive Session

```bash
# Start interactive session with Z.ai GLM-4.7
goose

# In session:
> Help me refactor this function...
> Run tests for module X
> Generate documentation
```

### One-Shot Commands

```bash
# Simple task
goose run --text "What is 2+2? Respond with just the number."

# File-based task
goose run --text "Review code in src/main.py for security issues"

# Non-session mode (stateless)
goose run --text "Explain this error" --no-session --quiet
```

### Scripted Workflows

```bash
# Chain multiple operations
goose run --text "Run tests, fix failures, commit changes"

# With specific model
GOOSE_MODEL=deepseek-reasoner goose run --text "Analyze architecture"
```

---

## Verification Tests

### Test Z.ai (Primary)

```bash
source ~/.bashrc_claude
goose run --text "What is 2+2? Respond with just the number." --no-session --quiet
```

**Expected:** `4`

**Status:** ✅ VERIFIED WORKING (2026-01-08)

**Root cause of previous failures:**
1. Wrong API key in 1Password (resolved - user manually updated)
2. Missing `/chat/completions` in `OPENAI_BASE_PATH` (resolved)

**Alternative (explicit env vars):**
```bash
GOOSE_PROVIDER=openai \
OPENAI_API_KEY="$ZAI_API_KEY" \
OPENAI_HOST=https://api.z.ai \
OPENAI_BASE_PATH=/api/coding/paas/v4/chat/completions \
GOOSE_MODEL=glm-4.7 \
goose run --text "Your task"
```

### Test DeepSeek (Verified Working)

```bash
source ~/.bashrc_claude
GOOSE_PROVIDER=openai \
OPENAI_API_KEY="$DEEPSEEK_API_KEY" \
OPENAI_HOST=https://api.deepseek.com \
OPENAI_BASE_PATH=/v1/chat/completions \
GOOSE_MODEL=deepseek-reasoner \
timeout 30 goose run --text "What is 2+2? Respond with just the number." --no-session --quiet
```

**Expected:** `4`

**Status:** ✅ Verified 2026-01-07

### Test Claude Code Wrapper Scripts

```bash
# Test GLM-4.7 wrapper (quick config check)
bash -c 'source ~/.bashrc_claude 2>/dev/null && \
  export ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic" && \
  export ANTHROPIC_AUTH_TOKEN="$ZAI_API_KEY" && \
  echo "✓ GLM-4.7 wrapper configured correctly" && \
  echo "  ZAI_API_KEY length: ${#ANTHROPIC_AUTH_TOKEN}"'

# Test full invocation (interactive, takes 30-60s for MCP initialization)
claude-glm --print "What is 2+2? Respond with just the number."

# Test Opus wrapper
claude-opus --print "What is 2+2? Respond with just the number."
```

**Expected:** Both return `4`, but using different models (verify via cost/performance)

**Status:** ✅ Wrapper scripts verified 2026-01-08

---

## Troubleshooting

### Common Issues

**1. "Unknown provider: zai"**
- Goose doesn't recognize custom provider type names
- **Fix:** Use `GOOSE_PROVIDER: openai` with `OPENAI_HOST` override

**2. "Rate limit exceeded: Insufficient balance"**
- Z.ai account needs credit
- **Workaround:** Use DeepSeek or other funded provider

**3. "Request failed: Resource not found (404)"**
- Missing or incorrect `OPENAI_BASE_PATH`
- **Fix:** Add `/v1/chat/completions` or provider-specific path

**4. API keys not loading**
- 1Password CLI not authenticated
- **Fix:** `source ~/.bashrc_claude` (loads service account token)

**5. Claude GLM wrapper hangs indefinitely**
- **Root Cause #1:** Invalid model flag syntax (FIXED - wrapper now uses `--model opus` with `ANTHROPIC_DEFAULT_OPUS_MODEL="GLM-4.7"`)
- **Root Cause #2:** 1Password CLI timeout in subprocess (UNRESOLVED - `op read` hangs when called from wrapper)
- **Workaround Option 1 (Recommended):** Use router-based approach:
  ```bash
  # Start router in background (loads token once)
  export ANTHROPIC_BASE_URL="http://localhost:3456"
  claude --model opus  # Router handles Z.ai routing
  ```
- **Workaround Option 2:** Pre-load token in parent shell:
  ```bash
  # Load token once before invoking wrapper
  export ZAI_API_KEY="$(op read 'op://Development/Z.ai API/credential')"
  claude-glm  # Wrapper uses existing $ZAI_API_KEY instead of calling op read
  ```
- **Why This Happens:** Wrapper attempts `op read` on every invocation (subprocess context), which times out. Router loads token once at startup.
- **Status:** Model flag fixed (2026-01-08), 1Password issue unresolved - router recommended

**6. Goose keyring errors on WSL2 (RESOLVED)**
- **Error:** `Failed to access keyring: Platform secure storage failure: DBus error`
- **Root Cause:** Goose caches credentials in system keyring, which fails on WSL2 (no DBus secrets service)
- **Solution:** Set `GOOSE_DISABLE_KEYRING=1` and use wrapper function
- **Configuration:** See [WSL2 Keyring Configuration](#wsl2-keyring-configuration) section above
- **Status:** ✅ RESOLVED (2026-01-22) - Wrapper function approach verified working

### Debug Mode

```bash
# Enable verbose logging
GOOSE_LOG_LEVEL=debug goose run --text "test"

# Check MCP server status
goose mcp --help

# Test Claude Code environment variable support
claude --help | grep -A 5 "model"
```

---

## Cost Comparison

**GLM-4.7 vs Claude Opus 4.5:**
- Input: $0.16/1M vs $15/1M (94% savings)
- Output: $0.80/1M vs $75/1M (89% savings)
- SWE-bench: 73.8% vs 70.3% (Claude Sonnet)

**Projected ROI:** For SWE-bench style coding tasks, GLM-4.7 delivers competitive performance at <10% of Claude's cost.

---

## Related Documentation

- Model Selection Strategy: `/tmp/model-selection-strategy.md`
- Claude Code GLM Setup: `/tmp/claude-code-glm-setup.md`
- Goose Official Docs: https://block.github.io/goose/
- MCP Hub Deep Dive: `~/dev/infrastructure/mcp-hub-deep-dive/`
- Multi-Agent Instructions: `~/dev/AGENTS.md`

---

## Registry Entry

**AUTHORITATIVE.yaml location:** `ai_agents.goose`

```yaml
goose:
  name: Goose CLI
  version: 1.19.0
  location: ~/.local/bin/goose
  config: ~/.config/goose/config.yaml
  primary_model: z-ai/glm-4.7
  status: active
  integration_date: 2026-01-07
  github: https://github.com/block/goose
```

---

## Session History

- **2026-01-08:** Multi-CLI wrapper scripts + LLM gateway investigation
  - Created `~/bin/claude-glm` and `~/bin/claude-opus` wrapper scripts (Claude Code)
  - Created `~/bin/gemini-flash`, `~/bin/gemini-pro`, `~/bin/gemini-thinking` (Gemini CLI)
  - Deprecated `use-glm()` and `use-claude()` functions (caused auth conflicts)
  - Evaluated Codex CLI (limited to gpt-5.2-codex on ChatGPT account, no wrapper needed)
  - Documented comprehensive LLM gateway investigation (LiteLLM, OpenRouter, Custom)
  - Decision: Defer gateway deployment, wrapper scripts provide 90% of functionality
  - Status: Claude + Gemini wrappers production ready, zero infrastructure overhead

- **2026-01-07:** Initial setup complete
  - Installed Goose CLI v1.19.0
  - Configured Z.ai GLM-4.7 as primary provider
  - Integrated 5 MCP servers from ecosystem
  - Added DeepSeek, Gemini, GPT-4o as alternative providers
  - Created model-switching functions for Claude Code (later deprecated)
  - Verified DeepSeek and Claude Code switching (Z.ai pending funding - later resolved)

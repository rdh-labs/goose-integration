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

```yaml
GOOSE_PROVIDER: openai
GOOSE_MODEL: glm-4.7

OPENAI_API_KEY: ${ZAI_API_KEY}
OPENAI_HOST: https://api.z.ai
OPENAI_BASE_PATH: /api/paas/v4/chat/completions
```

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

### Model Switching Functions

Added to `~/.bashrc_claude`:

```bash
use-glm        # Switch Claude Code to GLM-4.7 via OpenRouter
use-claude     # Switch back to Claude Opus 4.5
use-deepseek   # Use DeepSeek Reasoner
use-gemini     # Use Gemini 2.0 Flash
show-model     # Display current configuration
```

**Usage:**
```bash
source ~/.bashrc_claude
use-glm        # Switch to GLM-4.7
claude         # Start Claude Code with GLM-4.7

use-claude     # Switch back to Claude
claude         # Start with Opus 4.5
```

**Note:** This routes Claude Code CLI through OpenRouter, not Goose. Use Goose directly for its native features.

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

**Expected:** Rate limit error (insufficient balance) - confirms config works, needs credit

**Status:** ⚠️ Z.ai account needs funding

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

### Test Claude Code Model Switching (Verified Working)

```bash
source ~/.bashrc_claude

# Test switch to GLM-4.7
use-glm && show-model
# Expected: Model: z-ai/glm-4.7, Base URL: https://openrouter.ai/api/v1

# Test switch back to Claude
use-claude && show-model
# Expected: Model: claude-opus-4-5-20251101, Base URL: default
```

**Status:** ✅ All functions verified 2026-01-07

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

### Debug Mode

```bash
# Enable verbose logging
GOOSE_LOG_LEVEL=debug goose run --text "test"

# Check MCP server status
goose mcp --help
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

- **2026-01-07:** Initial setup complete
  - Installed Goose CLI v1.19.0
  - Configured Z.ai GLM-4.7 as primary provider
  - Integrated 5 MCP servers from ecosystem
  - Added DeepSeek, Gemini, GPT-4o as alternative providers
  - Created model-switching functions for Claude Code
  - Verified DeepSeek and Claude Code switching (Z.ai pending funding)

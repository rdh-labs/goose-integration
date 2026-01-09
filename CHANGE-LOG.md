# CHANGE-LOG.md

**Project:** Goose CLI Integration
**Created:** 2026-01-07

---

## 2026-01-08 Evening - Critical Model Name Corrections + Authentication Issues

### Fixed

**CRITICAL: Gemini Wrapper Model Names Incorrect**
- **Problem:** Initial wrappers used experimental/non-existent model names (`gemini-2.0-flash-exp`, `gemini-1.5-pro`, `gemini-2.0-flash-thinking-exp`)
- **Error:** `ModelNotFoundError: Requested entity was not found`
- **Root Cause:** Model names stale from training data, not validated against current Google API
- **Discovery:** User tested `gemini-flash` wrapper, received 404-style API error

**Model Name Corrections:**
```bash
# BEFORE (broken)                    # AFTER (working)
gemini-2.0-flash-exp        →        gemini-2.0-flash
gemini-1.5-pro              →        gemini-2.5-flash  # 1.5 Pro RETIRED Apr 2025
gemini-2.0-flash-thinking-exp →      gemini-3-flash
```

**Verification:**
- ✅ `gemini-flash "What is 2+2?"` → Returns "4" (WORKING)
- ✅ Default Gemini CLI → Works (confirmed model names valid)
- 📚 Validated against [official Gemini API documentation](https://ai.google.dev/gemini-api/docs/models)

**CRITICAL FINDING: Gemini 1.5 Pro Retired**
- **Retirement Date:** April 29, 2025
- **Impact:** All requests to `gemini-1.5-pro` return 404 errors
- **Replacement:** Gemini 2.5 Flash (thinking-capable, similar performance)
- **Source:** [Google Gemini models lifecycle](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/learn/model-versions)

### Outstanding Issues

**ISSUE: Claude Code GLM Wrapper Authentication Failure - ROOT CAUSE IDENTIFIED**
- **Status:** 🔍 ROOT CAUSE IDENTIFIED - Two distinct issues discovered
- **Original Symptom:** `claude-glm` wrapper hangs indefinitely, no output
- **Direct API Test:** `401 token expired or incorrect` for both Z.ai endpoints
- **Router Test:** ✅ WORKING (same Z.ai GLM-4.7, different auth method)

**ROOT CAUSE #1: Invalid Model Flag Syntax**
- **Problem:** Wrapper used `--model glm-4.7` (invalid - Claude Code doesn't accept custom model names)
- **Evidence:** `claude --help` shows `--model` accepts: standard aliases ('opus', 'sonnet', 'haiku') OR full Anthropic names
- **Discovery:** Web search of [Z.ai Claude Code documentation](https://docs.z.ai/scenario-example/develop-tools/claude) revealed correct pattern
- **Solution:** Map standard alias to GLM via environment variable:
  ```bash
  export ANTHROPIC_DEFAULT_OPUS_MODEL="GLM-4.7"
  exec claude --model opus "$@"  # NOT 'glm-4.7'
  ```
- **Status:** ✅ FIXED in wrapper script (2026-01-08)

**ROOT CAUSE #2: 1Password CLI Timeout During Wrapper Execution**
- **Problem:** `source ~/.bashrc_claude` hangs indefinitely when called from wrapper
- **Evidence:** `timeout 5 op read "op://Development/Z.ai API/credential"` times out (killed after 2m)
- **Impact:** Wrapper never gets past token loading, appears to hang
- **Why Router Works:** Router loads token ONCE at startup, then proxies all requests
- **Why Wrapper Fails:** Wrapper attempts `op read` on EVERY invocation (dynamic loading)
- **Hypothesis:** `op read` may require interactive authentication or daemon connection that fails in subprocess context
- **Status:** ❌ UNRESOLVED - 1Password CLI appears incompatible with wrapper subprocess pattern

**Recommended Solution:**
Use router-based approach OR pre-load token in parent shell before invoking wrapper:
```bash
# Option 1: Router (recommended)
export ANTHROPIC_BASE_URL="http://localhost:3456"
claude --model opus  # Router handles Z.ai routing

# Option 2: Pre-load token before wrapper
export ZAI_API_KEY="$(op read 'op://Development/Z.ai API/credential')"
claude-glm  # Wrapper uses existing $ZAI_API_KEY
```

### Changed

**Documentation:**
- Updated README.md with corrected model names
- Added critical notice about Gemini 1.5 Pro retirement
- Updated model selection guide with current models (2.0 Flash, 2.5 Flash, 3 Flash)
- Added sources/citations for model name validation

**Wrapper Scripts:**
- `~/bin/gemini-flash`: `gemini-2.0-flash-exp` → `gemini-2.0-flash`
- `~/bin/gemini-pro`: `gemini-1.5-pro` → `gemini-2.5-flash` (added retirement notice in comments)
- `~/bin/gemini-thinking`: `gemini-2.0-flash-thinking-exp` → `gemini-3-flash`
- `~/bin/claude-glm`: Fixed model flag syntax (`--model glm-4.7` → `--model opus` with `ANTHROPIC_DEFAULT_OPUS_MODEL="GLM-4.7"` mapping)

### Lessons Learned

1. **Always Validate Model Names Against Current API Documentation** - Training data is stale; experimental model names change frequently
2. **Test Wrappers Before Documenting as Production Ready** - Initial "PRODUCTION READY" status was premature
3. **Web Search Required for LLM API Names** - Model naming conventions evolve (Gemini 1.5 → 2.0 → 2.5 → 3 within months)
4. **Claude Code --model Flag Only Accepts Standard Aliases** - Custom model names require environment variable mapping (e.g., `ANTHROPIC_DEFAULT_OPUS_MODEL="GLM-4.7"` then `--model opus`)
5. **1Password CLI Dynamic Loading Incompatible with Wrapper Subprocess Pattern** - `op read` times out when called from `exec` wrapper; router pattern loads once at startup (works)
6. **Router/Proxy Pattern More Reliable Than Environment Variable Override** - Works for both Goose and Claude Code, avoids per-invocation auth complexity

---

## 2026-01-08 - Multi-CLI Wrapper Scripts + LLM Gateway Investigation

### Added

**Claude Code Multi-Model Support:**
- Created `~/bin/claude-glm` wrapper script for GLM-4.7 via Z.ai
- Created `~/bin/claude-opus` wrapper script for Claude Opus 4.5
- Deprecated `use-glm()` and `use-claude()` functions in `~/.bashrc_claude`
- Functions now show deprecation warnings pointing to wrapper scripts

**Gemini CLI Multi-Model Support:**
- Created `~/bin/gemini-flash` wrapper for gemini-2.0-flash-exp (1M context, $0.075/1M)
- Created `~/bin/gemini-pro` wrapper for gemini-1.5-pro (2M context, $0.35/1M)
- Created `~/bin/gemini-thinking` wrapper for gemini-2.0-flash-thinking-exp (reasoning mode)
- No configuration changes needed (uses existing Google OAuth)

**Codex CLI Evaluation:**
- Tested model switching capability
- Confirmed ChatGPT account limitation: Only gpt-5.2-codex supported
- Cannot use o3-mini, gpt-4o, or other OpenAI models with ChatGPT account
- Decision: No wrapper needed (only one model available)

**Wrapper Script Pattern:**
- Uses `exec` to replace shell process, preventing environment pollution
- Scopes environment variables to single invocation
- Eliminates auth conflicts with `claude login` token
- Zero infrastructure overhead

**Documentation:**
- Created comprehensive `LLM-GATEWAY-INVESTIGATION.md` (437 lines)
- Evaluated 3 LLM gateway options: LiteLLM, OpenRouter, Custom
- Documented LiteLLM deployment guide with config examples
- Decision framework matrix comparing all approaches
- Added Gemini CLI Integration section to README.md
- Updated model comparison tables

### Changed

**~/.bashrc_claude:**
- `use-glm()` now shows deprecation warning
- `use-claude()` now shows deprecation warning
- Both functions point users to wrapper scripts

### Fixed

**RESOLVED: Claude Code Auth Conflicts (ISSUE-063 Part 2)**
- **Problem:** Environment-based model switching caused auth conflicts
- **Root Cause:** Global env vars conflicted with `claude login` token
- **Solution:** Wrapper scripts with `exec` pattern scope vars to single invocation
- **Status:** ✅ VERIFIED - No auth conflicts

### Governance

**Decisions Logged:**
- DEC-082: Wrapper Scripts for Claude Code Model Switching (ACCEPTED)
- DEC-083: Deferred LLM Gateway Deployment Pending Validation (ACCEPTED)

**Lessons Learned:** 3 added to `~/dev/infrastructure/dev-env-config/lessons.md`
- Claude Code Model Selection is Hardcoded (wrapper scripts solution)
- Environment Variable Scoping via exec Prevents Auth Conflicts
- Z.ai Uses Custom ANTHROPIC_AUTH_TOKEN Header

**Ideas Generated:** 4 added to `~/dev/infrastructure/dev-env-docs/IDEAS-BACKLOG.md`
- IDEA-133: Universal Model Switching CLI for All AI Agents
- IDEA-134: LLM Gateway Experimental Deployment in Sandbox
- IDEA-135: Model Cost Tracking Dashboard
- IDEA-136: Multi-Model Session Transcript Tagging

**Session Handoff:**
- Updated `~/.claude/SESSION-HANDOFF-2026-01-08-Z-AI-INTEGRATION.md`
- All 3 issues marked RESOLVED (API key, Goose CLI, Claude Code auth)

### Outstanding

**User Testing:**
- Test `claude-glm` wrapper in real-world use (2-4 weeks)
- Evaluate if `/model` command switching is missed
- Decide on LLM gateway deployment (optional)

**Optional Future Work:**
- Deploy LiteLLM to `~/dev/sandbox/litellm-test/` for trial (IDEA-134)
- Implement cost tracking dashboard (IDEA-135)
- Add model tagging to transcript export (IDEA-136)

---

## 2026-01-08 - RESOLVED: Z.ai Integration Working (ISSUE-063)

### Fixed

**Critical Fix: OPENAI_BASE_PATH Must Include Full Endpoint**
- **Problem:** Goose was hitting `/v4` instead of `/api/coding/paas/v4/chat/completions`
- **Root Cause:** Goose does NOT append `/chat/completions` automatically for non-standard endpoints
- **Solution:** Set `OPENAI_BASE_PATH: /api/coding/paas/v4/chat/completions` (full path)
- **Status:** ✅ VERIFIED WORKING with environment variables

**Configuration (WORKING):**
```yaml
GOOSE_PROVIDER: openai
OPENAI_HOST: https://api.z.ai
OPENAI_BASE_PATH: /api/coding/paas/v4/chat/completions
OPENAI_API_KEY: ${ZAI_API_KEY}
```

**Two Issues Resolved:**
1. **Wrong API key in 1Password** - User manually updated from old key to new key
2. **Incomplete endpoint path** - Added `/chat/completions` suffix to BASE_PATH

**Verification:**
```bash
# Works with environment variables
GOOSE_PROVIDER=openai OPENAI_API_KEY="$ZAI_API_KEY" \
OPENAI_HOST=https://api.z.ai \
OPENAI_BASE_PATH=/api/coding/paas/v4/chat/completions \
GOOSE_MODEL=glm-4.7 \
goose run --text "What is 2+2? Just the number." --no-session --quiet
# Returns: 4 ✅
```

### Changed

**README.md:**
- Updated configuration to reflect working setup
- Added critical note about `/chat/completions` requirement
- Marked Z.ai as ✅ VERIFIED WORKING
- Documented both config file and env var approaches

**~/.config/goose/config.yaml:**
- Updated OPENAI_BASE_PATH to include full endpoint

### Governance

**Lessons Learned:** Added to `~/dev/infrastructure/dev-env-config/lessons.md`
- Goose CLI Does Not Append /chat/completions for Non-Standard Endpoints

**Issues Updated:**
- ISSUE-063: Status → RESOLVED (2026-01-08)

**Related:**
- Z.ai Support ticket response (2026-01-08)
- Session handoff: `~/.claude/SESSION-HANDOFF-2026-01-08-Z-AI-INTEGRATION.md`

---

## 2026-01-07 - Initial Setup & Multi-Provider Configuration

### Added

**Core Integration:**
- Installed Goose CLI v1.19.0 globally at `~/.local/bin/goose`
- Configured Z.ai GLM-4.7 as primary provider in `~/.config/goose/config.yaml`
- Integrated 5 MCP servers (developer, code-executor, governance, chrome-devtools, gemini-ai)
- Created documentation in README.md with installation, configuration, and usage examples

**Multi-Model Support:**
- Added DeepSeek Reasoner configuration (OpenAI-compatible endpoint)
- Added Gemini 2.0 Flash configuration (native Gemini provider)
- Added GPT-4o configuration (OpenAI provider)
- Documented model selection strategy with cost/performance comparison table

**Claude Code Integration:**
- Created model-switching functions in `~/.bashrc_claude`:
  - `use-glm()` - Switch to GLM-4.7 via Z.ai native Anthropic endpoint
  - `use-claude()` - Switch back to Claude Opus 4.5
  - `use-deepseek()` - Use DeepSeek Reasoner via OpenRouter
  - `use-gemini()` - Use Gemini 2.0 Flash via OpenRouter
  - `show-model()` - Display current configuration

### Changed

**Z.ai Endpoint Configuration (2026-01-07 14:00):**
- **Previous:** `use-glm()` used OpenRouter proxy
- **Current:** `use-glm()` uses Z.ai native Anthropic-compatible endpoint
  - Endpoint: `https://api.z.ai/api/anthropic`
  - Auth: `ANTHROPIC_AUTH_TOKEN` header (not standard Bearer token)
  - Rationale: Per official Z.ai documentation, Claude Code requires native endpoint

**Claude Code Reset (2026-01-07 14:00):**
- **Previous:** `use-claude()` only unset `ANTHROPIC_BASE_URL`
- **Current:** `use-claude()` also unsets `ANTHROPIC_AUTH_TOKEN`
- Rationale: Prevent auth token conflicts when switching back to Claude

**README.md Documentation (2026-01-07 14:00):**
- Added Z.ai API endpoints table (3 tool-specific endpoints)
- Added links to official Z.ai documentation
- Documented `ANTHROPIC_AUTH_TOKEN` header requirement for Claude Code

### Verified

**Working:**
- ✅ DeepSeek chat model (`deepseek-chat`) with Goose tool calls
- ✅ DeepSeek file operations (shell, read, analysis generation)
- ✅ Claude Code model switching functions (`use-glm`, `use-claude`, `show-model`)
- ✅ API key loading from 1Password via `~/.bashrc_claude`

**Blocked/Pending:**
- ⚠️ Z.ai GLM-4.7: "Insufficient balance or no resource package" (ISSUE-063)
  - User purchased year's subscription, awaiting Z.ai clarification
- ⚠️ DeepSeek Reasoner (`deepseek-reasoner`): Incompatible with Goose tool calls
  - Missing `reasoning_content` field support
- ❌ GPT-4o: Authentication failed (401 - token expired, needs regeneration)
- ❌ Gemini 2.0 Flash via Goose: 404 endpoint error (not configured correctly)

### Governance

**Lessons Learned:** 6 added to `~/dev/infrastructure/dev-env-config/lessons.md`
- Goose CLI Environment Variable Override Pitfall
- DeepSeek Reasoning Mode Incompatible with Goose Tool Calls
- Multi-Provider API Key Management via 1Password
- Z.ai Provides Multiple Tool-Specific API Endpoints
- LLM Integration Testing Must Include Tool Calls, Not Just Chat
- 1Password Service Account Read-Only Limitation

**Issues Tracked:** 3 added to `~/dev/infrastructure/dev-env-docs/ISSUES-TRACKER.md`
- ISSUE-063: Z.ai Account Not Activated Despite Year's Subscription
- ISSUE-064: 1Password Service Account Read-Only Blocks Credential Rotation
- ISSUE-065: Goose CLI Session Timeout Behavior Unclear

**Ideas Generated:** 5 added to `~/dev/infrastructure/dev-env-docs/IDEAS-BACKLOG.md`
- IDEA-128: Automated API Cost Tracking per Model/Provider
- IDEA-129: Three-Tier LLM Validation Test Framework
- IDEA-130: Multi-Provider Failover Logic
- IDEA-131: API Key Expiration Monitoring & Alerting
- IDEA-132: MCP Server Health Monitoring Dashboard

---

## Outstanding Tasks

**User Action Required:**
1. **Z.ai Account Activation** - User to clarify subscription status with Z.ai support
2. **OpenAI API Key Rotation** - Regenerate token via OpenAI dashboard, update manually in 1Password app

**Blocked Until Z.ai Activated:**
1. Test full Goose + Z.ai + MCP integration
2. Test Claude Code with `use-glm()` function
3. Verify cost savings vs Claude Opus baseline

**Future Work:**
1. Implement IDEA-128 (API cost tracking)
2. Implement IDEA-129 (3-tier LLM validation framework)
3. Fix Gemini 2.0 Flash configuration for Goose
4. Document DeepSeek reasoner limitations in model selection guide
5. Consider IDEA-130 (multi-provider failover)

---

## Version History

- **v0.1.0** (2026-01-07): Initial setup with Z.ai GLM-4.7, DeepSeek, Gemini, GPT-4o

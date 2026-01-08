# CHANGE-LOG.md

**Project:** Goose CLI Integration
**Created:** 2026-01-07

---

## 2026-01-08 - Claude Code Wrapper Scripts + LLM Gateway Investigation

### Added

**Claude Code Multi-Model Support:**
- Created `~/bin/claude-glm` wrapper script for GLM-4.7 via Z.ai
- Created `~/bin/claude-opus` wrapper script for Claude Opus 4.5
- Deprecated `use-glm()` and `use-claude()` functions in `~/.bashrc_claude`
- Functions now show deprecation warnings pointing to wrapper scripts

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

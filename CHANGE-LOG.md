# CHANGE-LOG.md

**Project:** Goose CLI Integration
**Created:** 2026-01-07

---

## 2026-01-08 - Fixed Z.ai Endpoint Configuration (ISSUE-063 Resolution)

### Changed

**Goose Config Endpoint Fix (2026-01-08):**
- **Previous:** `GOOSE_PROVIDER: openai` with `/api/paas/v4/chat/completions` endpoint
- **Current:** `GOOSE_PROVIDER: anthropic` with `/api/anthropic` endpoint
- **Rationale:** Z.ai Coding Plan requires tool-specific Anthropic endpoints (per https://docs.z.ai/devpack/tool/goose)
- **Impact:** Resolves 1113 "Insufficient balance" error - wrong endpoint required separate API Plan

**README.md Updates:**
- Updated primary configuration example to use Anthropic provider
- Added note about Coding Plan vs API Plan endpoint requirements
- Updated verification test status to "awaiting user testing"
- Added reference to official Z.ai Goose documentation

**ISSUE-063 Resolution:**
- Identified root cause: Used `/api/paas/v4` (requires API Plan) instead of `/api/anthropic` (covered by Coding Plan)
- Updated issue with detailed resolution steps and testing commands
- Status changed to: Awaiting user testing

### Governance

**Lessons Learned:** 1 added to `~/dev/infrastructure/dev-env-config/lessons.md`
- Z.ai Coding Plan Requires Tool-Specific API Endpoints

**Related:**
- ISSUE-063: Z.ai Account Not Activated Despite Year's Subscription (RESOLVED)
- Z.ai Support ticket response (2026-01-08)
- Z.ai Goose docs: https://docs.z.ai/devpack/tool/goose

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

# Goose Integration - Agent Instructions

**Project:** goose-integration
**Purpose:** Multi-model AI agent framework for cost-effective development workflows
**Primary Model:** Z.ai GLM-4.7
**Created:** 2026-01-07

---

## Quick Reference

**What is this?** Goose CLI installation, configuration, and multi-model routing strategy for AI agent workflows in this ecosystem.

**Who uses this?** All AI agents (Claude, Gemini, Codex, Copilot) can benefit from understanding multi-model cost optimization.

**Key files:**
- `README.md` - Main documentation (installation, configuration, usage)
- `~/.config/goose/config.yaml` - Goose configuration
- `~/.bashrc_claude` - Environment variables and model-switching functions
- `/tmp/model-selection-strategy.md` - Benchmark scores and use case mapping

---

## For AI Agents Working in This Area

### Before Modifying Configuration

1. **Read README.md first** - Understand current setup
2. **Check verification tests** - Know what's working
3. **Preserve API key security** - Never commit credentials
4. **Test before committing** - Run verification tests after changes

### Common Tasks

**Update model configuration:**
- Edit `~/.config/goose/config.yaml`
- Update environment variable references in `~/.bashrc_claude`
- Document changes in README.md

**Add new model provider:**
1. Add API key to 1Password Development vault
2. Update `~/.bashrc_claude` to load key
3. Document endpoint configuration in README.md
4. Add verification test to README.md
5. Update model selection strategy if needed

**Troubleshoot connectivity:**
- Check API key loading: `echo $ZAI_API_KEY` (should show partial key)
- Verify endpoint: Test with curl first
- Check Goose logs: `GOOSE_LOG_LEVEL=debug goose ...`

### Integration Points

**MCP Servers (5 configured):**
- developer (builtin)
- code-executor (~/. local/share/mcp-servers/code-executor/)
- governance (~/. local/share/mcp-servers/mcp-governance-server/)
- chrome-devtools (~/. local/share/mcp-servers/chrome-devtools-mcp/)
- gemini-ai (~/. local/share/mcp-servers/mcp-gemini-integration/)

**Claude Code:**
- Model-switching functions in `~/.bashrc_claude`
- Enables GLM-4.7 routing via OpenRouter

**Multi-Check:**
- Goose doesn't replace multi-check validation
- Multi-check is for decision validation (uses DeepSeek + Gemini)
- Goose is for coding tasks (uses GLM-4.7 or other models)

---

## Governance

**Decisions:** Track significant configuration changes in `~/dev/infrastructure/dev-env-docs/DECISIONS-LOG.md`

**Issues:** Report integration problems in `~/dev/infrastructure/dev-env-docs/ISSUES-TRACKER.md`

**Related Decisions:**
- DEC-038: Assumption Validation Gate (applies to all agents)
- DEC-052: No self-validation in multi-check (applies to Goose if used for validation)
- DEC-055: Agent-specific model exclusion (applies if Goose used for validation)

---

## Cost Awareness

**Why GLM-4.7?**
- 94% cheaper than Claude Opus on input ($0.16 vs $15 per 1M tokens)
- Competitive SWE-bench performance (73.8% vs Claude Sonnet 70.3%)
- 202K context window (sufficient for most coding tasks)

**When to use Claude instead:**
- Critical architecture decisions
- Security-critical changes
- High-stakes production deployments
- Complex reasoning beyond code generation

**Cost comparison table:** See `README.md` or `/tmp/model-selection-strategy.md`

---

## Session History

- 2026-01-07: Initial setup complete, all verification tests passing (except Z.ai funding)

# When to Create Files in goose-integration/

**Philosophy:** Minimal core + on-demand expansion

**Current structure (2026-01-07):**
```
goose-integration/
├── README.md         # Main documentation (exists)
├── AGENTS.md         # AI agent instructions (exists)
├── WHEN-TO-CREATE.md # This file (exists)
└── .git/             # Version control (exists)
```

---

## When to Create Additional Files

### Configuration Files

**Create when:** Need to version-control additional Goose configurations

Examples:
- `profiles/` - Alternative config profiles (dev, prod, different model setups)
- `templates/` - Goose session templates or prompts

**Don't create:** Duplicate `~/.config/goose/config.yaml` here - that's the canonical config location

---

### Scripts

**Create when:** Building Goose workflow automation

Examples:
- `scripts/model-benchmark.sh` - Test multiple models on same task
- `scripts/health-check.sh` - Verify Goose + MCP connectivity
- `scripts/cost-report.sh` - Generate usage cost reports

**Don't create:** One-off commands - use README.md examples instead

---

### Documentation

**Create when:** Need detailed guides beyond README.md

Examples:
- `docs/MCP-INTEGRATION.md` - Deep dive on MCP server configuration
- `docs/TROUBLESHOOTING.md` - Extended troubleshooting guide (if README.md section grows >500 lines)
- `docs/MODEL-BENCHMARKS.md` - Detailed benchmark results (if you run custom tests)

**Don't create:** `INSTALL.md`, `SETUP.md`, `USAGE.md` - README.md covers this

---

### Test Files

**Create when:** Building automated verification suite

Examples:
- `tests/verify-models.sh` - Test all configured models
- `tests/mcp-connectivity.sh` - Verify MCP servers are reachable
- `tests/api-keys.sh` - Validate 1Password integration

---

### Examples

**Create when:** Building reusable Goose workflow examples

Examples:
- `examples/code-review.md` - Goose-based code review workflow
- `examples/multi-file-refactor.md` - Complex refactoring with Goose
- `examples/testing-pipeline.md` - Automated testing workflow

**Don't create:** Simple examples - use README.md "Usage Examples" section

---

## Before Creating ANY File

Ask:
1. **Does this belong in README.md instead?** (< 100 lines → yes)
2. **Is this configuration?** (→ Belongs in `~/.config/goose/`)
3. **Is this temporary?** (→ Use `/tmp/` or don't create)
4. **Does a similar file exist elsewhere?** (→ Consolidate or link)

---

## Update This File

When you create new files, add them to this guide with rationale.

**Last updated:** 2026-01-07

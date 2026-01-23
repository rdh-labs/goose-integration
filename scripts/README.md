# Goose Integration Scripts

This directory contains validation and maintenance scripts for the Goose CLI integration.

## validate-examples.sh

**Purpose:** Validates all documented multi-model examples to ensure they work correctly.

**What it tests:**
1. Z.ai GLM-4.7 via wrapper function (default usage)
2. DeepSeek Reasoner via direct binary call
3. GPT-4o via direct binary call
4. Gemini 2.0 Flash via direct binary call (optional)

**Prerequisites:**
```bash
# Load API keys from 1Password
source ~/.bashrc_claude

# Ensure you have valid, funded API keys for providers you want to test
```

**Usage:**

```bash
# Test all providers (costs money - makes real API calls)
./validate-examples.sh

# Test only Z.ai (cheapest, validates core functionality)
./validate-examples.sh --zai-only

# Test all except Gemini
./validate-examples.sh --skip-gemini
```

**Output:**
- Color-coded test results (✓ passed, ✗ failed, ⚠ warnings)
- Detailed log file: `validation-YYYYMMDD-HHMMSS.log`
- Exit code 0 if all tests pass, 1 if any fail

**Cost estimate per run:**
- Z.ai only: ~$0.0001 (recommended for frequent testing)
- All providers: ~$0.01-0.05 (depending on models used)

**When to run:**

| Scenario | Recommended |
|----------|-------------|
| After documentation changes | `--zai-only` |
| Before recommending setup to others | Full test (all providers) |
| Periodic regression check | `--zai-only` (weekly) |
| After Goose CLI updates | Full test (all providers) |
| Debugging multi-model issues | Specific provider only (edit script) |

**Exit codes:**
- `0` - All tests passed
- `1` - One or more tests failed
- Script exits early if prerequisites missing

**Log files:**
Located in this directory with timestamp naming:
- `validation-20260122-153045.log`
- Contains full command output, exit codes, and timing

**Troubleshooting:**

If tests fail:
1. Check log file for detailed error messages
2. Verify API keys are loaded: `echo ${#ZAI_API_KEY}`
3. Verify binary exists: `ls -la /home/ichardart/.local/bin/goose`
4. Verify wrapper function: `declare -f goose`
5. Test manually with the command from the log

**Common failures:**

| Error | Cause | Fix |
|-------|-------|-----|
| `goose wrapper not found` | bashrc_claude not sourced | `source ~/.bashrc_claude` |
| `API key not set` | 1Password not loaded | `source ~/.bashrc_claude` |
| `timeout` | Provider API slow/down | Retry or check provider status |
| `401 unauthorized` | Wrong key sent to endpoint | Verify OPENAI_API_KEY matches provider (see note below) |
| `404 not found` | Wrong endpoint configuration | Check OPENAI_HOST/BASE_PATH |

**Note on 401 errors:** If Z.ai test gets 401 but curl works, check environment variables:
```bash
echo "OPENAI_API_KEY: ${#OPENAI_API_KEY} chars"
echo "ZAI_API_KEY: ${#ZAI_API_KEY} chars"
```
If they're different, the global OPENAI_API_KEY export (line 229 in bashrc_claude) may be pointing to the wrong provider. The validation script explicitly sets `OPENAI_API_KEY="$ZAI_API_KEY"` to avoid this issue.

**Why tests call binary directly (not wrapper):**

The validation script runs tests via `bash -c` (for timeout handling), which creates subshells that don't inherit bash functions. This means:
- Wrapper function: Only available in interactive shells
- Binary calls: Work in all contexts (subshells, scripts, CI/CD)

The script validates the binary calling pattern with explicit environment variables:
```bash
GOOSE_DISABLE_KEYRING=1 OPENAI_API_KEY="$ZAI_API_KEY" /path/to/goose run ...
```

This is the same pattern users should employ in:
- Non-interactive scripts
- Automation/CI pipelines
- Any context where bash functions aren't available

**Integration with CI/CD:**

For automated testing:
```bash
# In CI pipeline
source ~/.bashrc_claude
./validate-examples.sh --zai-only || exit 1
```

**Maintenance:**

Update this script when:
- New providers added to documentation
- Provider endpoints change
- Test prompt needs updating
- Timeout values need adjustment

**Related:**
- Main README: `../README.md`
- Config file: `~/.config/goose/config.yaml`
- Wrapper function: `~/.bashrc_claude`
- Issue tracker: `~/dev/infrastructure/dev-env-docs/ISSUES-TRACKER.md` (ISSUE-063)

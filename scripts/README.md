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
| `401 unauthorized` | Invalid/expired API key | Update key in 1Password |
| `404 not found` | Wrong endpoint configuration | Check OPENAI_HOST/BASE_PATH |

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

#!/bin/bash
# Goose CLI Example Validation Script
# Tests all documented multi-model examples to ensure they work correctly
#
# Usage:
#   ./validate-examples.sh              # Test all providers
#   ./validate-examples.sh --zai-only   # Test only Z.ai (default)
#   ./validate-examples.sh --skip-gemini # Skip Gemini tests
#
# Prerequisites:
#   - source ~/.bashrc_claude (loads API keys from 1Password)
#   - Valid API keys for providers you want to test
#   - Funded accounts (tests make real API calls)
#
# Note: Tests call binary directly (not wrapper function) because bash -c
#       subshells don't inherit functions. This validates the same pattern
#       users would employ in scripts or automation.

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
TEST_PROMPT="What is 2+2? Respond with just the number."
EXPECTED_ANSWER="4"
LOG_FILE="$HOME/dev/infrastructure/goose-integration/scripts/validation-$(date +%Y%m%d-%H%M%S).log"

# Parse arguments
ZAI_ONLY=false
SKIP_GEMINI=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --zai-only)
            ZAI_ONLY=true
            shift
            ;;
        --skip-gemini)
            SKIP_GEMINI=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--zai-only] [--skip-gemini]"
            exit 1
            ;;
    esac
done

# Initialize log
echo "Goose CLI Validation - $(date)" | tee "$LOG_FILE"
echo "Log file: $LOG_FILE" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Check prerequisites
echo -e "${BLUE}Checking prerequisites...${NC}" | tee -a "$LOG_FILE"

# Check if binary exists
if [[ ! -f /home/ichardart/.local/bin/goose ]]; then
    echo -e "${RED}✗ Goose binary not found at /home/ichardart/.local/bin/goose${NC}" | tee -a "$LOG_FILE"
    exit 1
fi
echo -e "${GREEN}✓ Goose binary found${NC}" | tee -a "$LOG_FILE"

# Check if bashrc_claude was sourced (needed for API keys)
if ! declare -F goose &>/dev/null; then
    echo -e "${YELLOW}⚠ goose wrapper function not found (not critical)${NC}" | tee -a "$LOG_FILE"
    echo "  Tests call binary directly, but you should source ~/.bashrc_claude for API keys" | tee -a "$LOG_FILE"
fi

# Check API keys
echo "" | tee -a "$LOG_FILE"
echo -e "${BLUE}Checking API keys...${NC}" | tee -a "$LOG_FILE"

if [[ -z "$ZAI_API_KEY" ]]; then
    echo -e "${RED}✗ ZAI_API_KEY not set${NC}" | tee -a "$LOG_FILE"
    echo "  Run: source ~/.bashrc_claude" | tee -a "$LOG_FILE"
    exit 1
fi
echo -e "${GREEN}✓ ZAI_API_KEY set (${#ZAI_API_KEY} chars)${NC}" | tee -a "$LOG_FILE"

if [[ "$ZAI_ONLY" == "false" ]]; then
    if [[ -z "$DEEPSEEK_API_KEY" ]]; then
        echo -e "${YELLOW}⚠ DEEPSEEK_API_KEY not set (skipping DeepSeek tests)${NC}" | tee -a "$LOG_FILE"
    else
        echo -e "${GREEN}✓ DEEPSEEK_API_KEY set (${#DEEPSEEK_API_KEY} chars)${NC}" | tee -a "$LOG_FILE"
    fi

    if [[ -z "$OPENAI_API_KEY" ]]; then
        echo -e "${YELLOW}⚠ OPENAI_API_KEY not set (skipping GPT-4o tests)${NC}" | tee -a "$LOG_FILE"
    else
        echo -e "${GREEN}✓ OPENAI_API_KEY set (${#OPENAI_API_KEY} chars)${NC}" | tee -a "$LOG_FILE"
    fi
fi

echo "" | tee -a "$LOG_FILE"

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Helper function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected="$3"

    TESTS_RUN=$((TESTS_RUN + 1))

    echo -e "${BLUE}Testing: $test_name${NC}" | tee -a "$LOG_FILE"
    echo "Command: $test_command" >> "$LOG_FILE"

    # Run the test with timeout
    local output
    local exit_code

    if output=$(timeout 30s bash -c "$test_command" 2>&1); then
        exit_code=0
    else
        exit_code=$?
    fi

    echo "Exit code: $exit_code" >> "$LOG_FILE"
    echo "Output: $output" >> "$LOG_FILE"

    # Check for authentication or API errors first
    if echo "$output" | grep -qi "authentication\|unauthorized\|401\|403\|expired\|invalid.*key"; then
        echo -e "${RED}✗ FAILED (Authentication Error)${NC}" | tee -a "$LOG_FILE"
        echo "  Error: $output" | tee -a "$LOG_FILE"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi

    # Check for other errors
    if echo "$output" | grep -qi "error\|failed\|timeout"; then
        echo -e "${RED}✗ FAILED (API Error)${NC}" | tee -a "$LOG_FILE"
        echo "  Error: $output" | tee -a "$LOG_FILE"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi

    # Check if output contains expected answer (exact match)
    if echo "$output" | grep -qw "$expected"; then
        echo -e "${GREEN}✓ PASSED${NC}" | tee -a "$LOG_FILE"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗ FAILED (Unexpected Output)${NC}" | tee -a "$LOG_FILE"
        echo "  Expected: $expected" | tee -a "$LOG_FILE"
        echo "  Got: $output" | tee -a "$LOG_FILE"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Test 1: Z.ai via direct call (validates wrapper pattern)
echo -e "\n${BLUE}═══ Test 1: Z.ai GLM-4.7 (direct) ═══${NC}" | tee -a "$LOG_FILE"
run_test \
    "Z.ai direct call" \
    "GOOSE_DISABLE_KEYRING=1 OPENAI_API_KEY=\"\$ZAI_API_KEY\" /home/ichardart/.local/bin/goose run --text '$TEST_PROMPT' --no-session --quiet" \
    "$EXPECTED_ANSWER"

if [[ "$ZAI_ONLY" == "true" ]]; then
    echo "" | tee -a "$LOG_FILE"
    echo -e "${YELLOW}Skipping additional provider tests (--zai-only flag)${NC}" | tee -a "$LOG_FILE"
else
    # Test 2: DeepSeek via binary (if available)
    if [[ -n "$DEEPSEEK_API_KEY" ]]; then
        echo -e "\n${BLUE}═══ Test 2: DeepSeek Reasoner (binary) ═══${NC}" | tee -a "$LOG_FILE"
        run_test \
            "DeepSeek via binary" \
            "GOOSE_DISABLE_KEYRING=1 GOOSE_PROVIDER=openai OPENAI_API_KEY=\"\$DEEPSEEK_API_KEY\" OPENAI_HOST=https://api.deepseek.com OPENAI_BASE_PATH=/v1/chat/completions GOOSE_MODEL=deepseek-reasoner /home/ichardart/.local/bin/goose run --text '$TEST_PROMPT' --no-session --quiet" \
            "$EXPECTED_ANSWER"
    fi

    # Test 3: GPT-4o via binary (if available)
    if [[ -n "$OPENAI_API_KEY" ]]; then
        echo -e "\n${BLUE}═══ Test 3: GPT-4o (binary) ═══${NC}" | tee -a "$LOG_FILE"
        run_test \
            "GPT-4o via binary" \
            "GOOSE_DISABLE_KEYRING=1 GOOSE_PROVIDER=openai OPENAI_API_KEY=\"\$OPENAI_API_KEY\" OPENAI_HOST=https://api.openai.com OPENAI_BASE_PATH=/v1/chat/completions GOOSE_MODEL=gpt-4o /home/ichardart/.local/bin/goose run --text '$TEST_PROMPT' --no-session --quiet" \
            "$EXPECTED_ANSWER"
    fi

    # Test 4: Gemini via binary (if available and not skipped)
    if [[ "$SKIP_GEMINI" == "false" ]]; then
        echo -e "\n${BLUE}═══ Test 4: Gemini 2.0 Flash (binary) ═══${NC}" | tee -a "$LOG_FILE"
        echo -e "${YELLOW}Note: Requires Gemini provider to be configured in Goose${NC}" | tee -a "$LOG_FILE"
        run_test \
            "Gemini via binary" \
            "GOOSE_DISABLE_KEYRING=1 GOOSE_PROVIDER=gemini GOOSE_MODEL=gemini-2.0-flash-exp /home/ichardart/.local/bin/goose run --text '$TEST_PROMPT' --no-session --quiet" \
            "$EXPECTED_ANSWER" || echo -e "${YELLOW}  (Gemini test failure is acceptable if provider not configured)${NC}" | tee -a "$LOG_FILE"
    fi
fi

# Summary
echo "" | tee -a "$LOG_FILE"
echo -e "${BLUE}═══════════════════════════════════${NC}" | tee -a "$LOG_FILE"
echo -e "${BLUE}      Validation Summary${NC}" | tee -a "$LOG_FILE"
echo -e "${BLUE}═══════════════════════════════════${NC}" | tee -a "$LOG_FILE"
echo "Tests run:    $TESTS_RUN" | tee -a "$LOG_FILE"
echo -e "${GREEN}Tests passed: $TESTS_PASSED${NC}" | tee -a "$LOG_FILE"
echo -e "${RED}Tests failed: $TESTS_FAILED${NC}" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}✓ All tests passed!${NC}" | tee -a "$LOG_FILE"
    echo "  Goose CLI multi-model setup is working correctly." | tee -a "$LOG_FILE"
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}" | tee -a "$LOG_FILE"
    echo "  Review log file: $LOG_FILE" | tee -a "$LOG_FILE"
    exit 1
fi

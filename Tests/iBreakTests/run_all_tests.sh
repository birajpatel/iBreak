#!/bin/bash

# Master test runner for iBreak integration tests
# Runs all available tests and reports results

set -e

echo "=========================================="
echo "  🧪 iBreak Integration Test Suite"
echo "=========================================="
echo ""

# SCRIPT_DIR is already Tests/iBreakTests (where this script lives)
TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"

# Track test results
PASSED=0
FAILED=0

run_test() {
    local test_name="$1"
    local test_script="$2"

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Running: $test_name"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if bash "$test_script"; then
        ((PASSED++))
        echo ""
        echo "✅ $test_name PASSED"
    else
        ((FAILED++))
        echo ""
        echo "❌ $test_name FAILED"
    fi
    echo ""
}

# Make all test scripts executable
chmod +x "$TESTS_DIR"/test_*.sh 2>/dev/null || true

# Run each test script in sequence
for test_script in "$TESTS_DIR"/test_*.sh; do
    if [ -f "$test_script" ]; then
        test_name=$(basename "$test_script" .sh | sed 's/test_/Test: /I' | tr '_' ' ')
        run_test "$test_name" "$test_script"
    fi
done

# Final summary
echo "=========================================="
echo "  📊 Test Summary"
echo "=========================================="
echo "✅ Passed: $PASSED"
echo "❌ Failed: $FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
    echo "🎉 All tests passed!"
    exit 0
else
    echo "⚠️  Some tests failed. Please review output above."
    exit 1
fi

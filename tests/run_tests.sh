#!/bin/bash
#
# Test runner for showlinenum.awk
#
# Usage: ./run_tests.sh [test_number]
#   test_number: optional, runs only that specific test (e.g., 01, 02)
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
AWK_SCRIPT="$PROJECT_DIR/showlinenum.awk"

INPUTS_DIR="$SCRIPT_DIR/inputs"
OUTPUTS_DIR="$SCRIPT_DIR/outputs"

# Verify the AWK script exists
if [ ! -f "$AWK_SCRIPT" ]; then
  echo -e "${RED}ERROR: Cannot find $AWK_SCRIPT${NC}"
  exit 1
fi

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
FAILED_TESTS=()

# Function to run a single test
run_test() {
  local test_file="$1"
  local test_name=$(basename "$test_file" .diff)
  local args_file="$INPUTS_DIR/${test_name}.args"
  local expected_file="$OUTPUTS_DIR/${test_name}.out"
  local error_file="$OUTPUTS_DIR/${test_name}.error"

  TESTS_RUN=$((TESTS_RUN + 1))

  # Read args if they exist
  local args=""
  if [ -f "$args_file" ]; then
    args=$(cat "$args_file")
  fi

  # Run the test
  local actual
  local exit_code=0
  if [ -f "$error_file" ]; then
    # This is an error test - expect it to fail
    actual=$(cat "$test_file" | gawk -f "$AWK_SCRIPT" $args 2>&1) || exit_code=$?
    local expected_error=$(cat "$error_file")

    if [ $exit_code -ne 0 ] && echo "$actual" | grep -q "FATAL:" && echo "$actual" | grep -q "$expected_error"; then
      echo -e "${GREEN}✓${NC} $test_name (correctly failed)"
      TESTS_PASSED=$((TESTS_PASSED + 1))
      return 0
    else
      echo -e "${RED}✗${NC} $test_name (should have failed with: $expected_error)"
      echo "  Actual output:"
      echo "$actual" | sed 's/^/    /'
      TESTS_FAILED=$((TESTS_FAILED + 1))
      FAILED_TESTS+=("$test_name")
      return 1
    fi
  else
    # Normal test - expect success
    actual=$(cat "$test_file" | gawk -f "$AWK_SCRIPT" $args 2>&1) || exit_code=$?

    if [ $exit_code -ne 0 ]; then
      echo -e "${RED}✗${NC} $test_name (script failed unexpectedly)"
      echo "  Output:"
      echo "$actual" | sed 's/^/    /'
      TESTS_FAILED=$((TESTS_FAILED + 1))
      FAILED_TESTS+=("$test_name")
      return 1
    fi

    local expected=$(cat "$expected_file")

    if [ "$actual" = "$expected" ]; then
      echo -e "${GREEN}✓${NC} $test_name"
      TESTS_PASSED=$((TESTS_PASSED + 1))
      return 0
    else
      echo -e "${RED}✗${NC} $test_name"
      echo "  Expected:"
      echo "$expected" | sed 's/^/    /'
      echo "  Actual:"
      echo "$actual" | sed 's/^/    /'
      echo ""
      echo "  Diff:"
      diff -u <(echo "$expected") <(echo "$actual") | sed 's/^/    /' || true
      TESTS_FAILED=$((TESTS_FAILED + 1))
      FAILED_TESTS+=("$test_name")
      return 1
    fi
  fi
}

# Main test execution
echo -e "${BLUE}Running showlinenum.awk tests...${NC}"
echo ""

# Check if a specific test was requested
if [ $# -eq 1 ]; then
  test_pattern="$1"
  test_files=$(find "$INPUTS_DIR" -name "${test_pattern}_*.diff" -o -name "${test_pattern}.diff" | sort)
  if [ -z "$test_files" ]; then
    echo -e "${RED}No tests found matching: $test_pattern${NC}"
    exit 1
  fi
else
  test_files=$(find "$INPUTS_DIR" -name "*.diff" | sort)
fi

# Run all tests
for test_file in $test_files; do
  run_test "$test_file"
done

# Print summary
echo ""
echo "========================================="
echo "Test Results:"
echo "  Total:  $TESTS_RUN"
echo -e "  Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "  Failed: ${RED}$TESTS_FAILED${NC}"
echo "========================================="

if [ $TESTS_FAILED -eq 0 ]; then
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}Failed tests:${NC}"
  for test in "${FAILED_TESTS[@]}"; do
    echo "  - $test"
  done
  exit 1
fi

#!/bin/bash
# Test runner for showlinenum.awk
# Usage: ./run_tests.sh [test_pattern]

RED='\033[0;31m' GREEN='\033[0;32m' BLUE='\033[0;34m' NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AWK_SCRIPT="$(dirname "$SCRIPT_DIR")/showlinenum.awk"
INPUTS_DIR="$SCRIPT_DIR/inputs"
OUTPUTS_DIR="$SCRIPT_DIR/outputs"

[ ! -f "$AWK_SCRIPT" ] && { echo -e "${RED}ERROR: Cannot find $AWK_SCRIPT${NC}"; exit 1; }

TESTS_RUN=0 TESTS_PASSED=0 FAILED_TESTS=()

run_test() {
  local test_name=$(basename "$1" .diff)
  local args_file="$INPUTS_DIR/${test_name}.args"
  local error_file="$OUTPUTS_DIR/${test_name}.error"

  TESTS_RUN=$((TESTS_RUN + 1))

  local args="" actual exit_code
  [ -f "$args_file" ] && args=$(<"$args_file")
  actual=$(gawk -f "$AWK_SCRIPT" $args < "$1" 2>&1)
  exit_code=$?

  if [ -f "$error_file" ]; then
    # Error test - should fail with expected message
    local expected_error=$(<"$error_file")
    if [ $exit_code -ne 0 ] && echo "$actual" | grep -qF "$expected_error"; then
      echo -e "${GREEN}✓${NC} $test_name (correctly failed)"
      TESTS_PASSED=$((TESTS_PASSED + 1))
    else
      echo -e "${RED}✗${NC} $test_name (should have failed with: $expected_error)"
      echo "$actual" | sed 's/^/    /'
      FAILED_TESTS+=("$test_name")
    fi
  else
    # Normal test - should succeed and match expected output
    if [ $exit_code -ne 0 ]; then
      echo -e "${RED}✗${NC} $test_name (unexpected failure)"
      echo "$actual" | sed 's/^/    /'
      FAILED_TESTS+=("$test_name")
    else
      local expected=$(<"$OUTPUTS_DIR/${test_name}.out")
      if [ "$actual" = "$expected" ]; then
        echo -e "${GREEN}✓${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
      else
        echo -e "${RED}✗${NC} $test_name"
        echo "  Expected:" && echo "$expected" | sed 's/^/    /'
        echo "  Actual:" && echo "$actual" | sed 's/^/    /'
        echo "  Diff:" && diff -u <(echo "$expected") <(echo "$actual") | sed 's/^/    /' || true
        FAILED_TESTS+=("$test_name")
      fi
    fi
  fi
}

echo -e "${BLUE}Running showlinenum.awk tests...${NC}\n"

# Find tests matching pattern (if provided) or all tests
pattern="${1:-*}"
test_files=$(find "$INPUTS_DIR" -name "${pattern}*.diff" -o -name "${pattern}_*.diff" 2>/dev/null | sort)
[ -z "$test_files" ] && { echo -e "${RED}No tests found${NC}"; exit 1; }

for test_file in $test_files; do run_test "$test_file"; done

# Summary
TESTS_FAILED=${#FAILED_TESTS[@]}
echo -e "\n========================================="
echo -e "Total: $TESTS_RUN | Passed: ${GREEN}$TESTS_PASSED${NC} | Failed: ${RED}$TESTS_FAILED${NC}"
echo "========================================="

if [ $TESTS_FAILED -eq 0 ]; then
  echo -e "${GREEN}All tests passed!${NC}"
else
  echo -e "${RED}Failed tests:${NC}"
  printf '  - %s\n' "${FAILED_TESTS[@]}"
  exit 1
fi

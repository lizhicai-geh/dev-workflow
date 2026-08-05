#!/usr/bin/env bash
set -uo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
QUALITY_SCRIPT="$SKILL_DIR/scripts/collect-quality-results.sh"
PROJECT_SCRIPT="$SKILL_DIR/scripts/check-project.sh"
MIGRATION_SCRIPT="$SKILL_DIR/scripts/check-migrations.sh"
AUTONOMY_SCRIPT="$SKILL_DIR/scripts/check-ai-autonomy.sh"
TEST_TMP="$(mktemp -d "${TMPDIR:-/tmp}/dev-workflow-tests.XXXXXX")"
OUTPUT_FILE="$TEST_TMP/output.log"
PASSED=0
FAILED=0

cleanup() {
  rm -rf -- "$TEST_TMP"
}
trap cleanup EXIT

record_pass() {
  printf 'PASS  %s\n' "$1"
  PASSED=$((PASSED + 1))
}

record_fail() {
  printf 'FAIL  %s\n' "$1" >&2
  FAILED=$((FAILED + 1))
}

assert_exit() {
  local expected="$1"
  local label="$2"
  shift 2

  "$@" >"$OUTPUT_FILE" 2>&1
  local actual=$?
  if [[ "$actual" -eq "$expected" ]]; then
    record_pass "$label"
  else
    record_fail "$label (expected exit $expected, got $actual)"
    sed 's/^/      /' "$OUTPUT_FILE" >&2
  fi
}

assert_output() {
  local pattern="$1"
  local label="$2"
  if grep -Fq "$pattern" "$OUTPUT_FILE"; then
    record_pass "$label"
  else
    record_fail "$label (missing output: $pattern)"
    sed 's/^/      /' "$OUTPUT_FILE" >&2
  fi
}

assert_exit 2 "unknown required quality check is rejected" \
  env REQUIRED_QUALITY_CHECKS='lint,typo' LINT_CMD='true' "$QUALITY_SCRIPT" "$TEST_TMP"
assert_output "Unsupported required quality check: typo" "unknown quality check explains the error"

assert_exit 1 "missing known required quality check fails" \
  env REQUIRED_QUALITY_CHECKS='lint,typecheck' LINT_CMD='true' TYPECHECK_CMD='' "$QUALITY_SCRIPT" "$TEST_TMP"
assert_output "MISS: typecheck" "missing required quality check is reported"

assert_exit 0 "configured quality check passes" \
  env REQUIRED_QUALITY_CHECKS='lint' LINT_CMD='true' "$QUALITY_SCRIPT" "$TEST_TMP"
assert_output "COMMAND: true" "quality command is included in evidence"

assert_exit 1 "failing quality command preserves failure" \
  env REQUIRED_QUALITY_CHECKS='lint' LINT_CMD='exit 7' "$QUALITY_SCRIPT" "$TEST_TMP"
assert_output "FAIL: lint (exit=7)" "quality failure includes exit code"

assert_exit 2 "no configured quality commands is configuration error" \
  env REQUIRED_QUALITY_CHECKS='' LINT_CMD='' TYPECHECK_CMD='' TEST_CMD='' BUILD_CMD='' MIGRATION_CMD='' SECURITY_CMD='' \
  "$QUALITY_SCRIPT" "$TEST_TMP"

PROJECT_PARENT="$TEST_TMP/project-parent"
PROJECT_ROOT="$PROJECT_PARENT/project"
mkdir -p "$PROJECT_ROOT/tests" "$PROJECT_ROOT/.github/workflows"
printf '# inherited instructions\n' >"$PROJECT_PARENT/AGENTS.md"
printf '# ignore\n' >"$PROJECT_ROOT/.gitignore"

assert_exit 1 "empty test and CI directories do not pass" \
  env REQUIRED_FILES='AGENTS.md:.gitignore' REQUIRE_TESTS=1 REQUIRE_CI=1 "$PROJECT_SCRIPT" "$PROJECT_ROOT"
assert_output "PASS  AGENTS.md (" "parent AGENTS.md is discovered"
assert_output "MISS  tests" "empty test directory is rejected"
assert_output "MISS  CI configuration" "empty CI directory is rejected"

printf 'test("works", () => {});\n' >"$PROJECT_ROOT/tests/example.test.js"
printf 'name: deploy-only\n' >"$PROJECT_ROOT/.github/workflows/deploy.yml"
assert_exit 1 "CI file without quality signal does not pass" \
  env REQUIRED_FILES='AGENTS.md:.gitignore' REQUIRE_TESTS=1 REQUIRE_CI=1 "$PROJECT_SCRIPT" "$PROJECT_ROOT"
assert_output "MISS  CI configuration" "deploy-only workflow is not treated as quality CI"

printf 'name: quality\njobs:\n  test:\n    steps:\n      - run: npm test\n' >"$PROJECT_ROOT/.github/workflows/quality.yml"
assert_exit 0 "real test and CI files pass structural check" \
  env REQUIRED_FILES='AGENTS.md:.gitignore' REQUIRE_TESTS=1 REQUIRE_CI=1 "$PROJECT_SCRIPT" "$PROJECT_ROOT"
assert_output "SCOPE: structural evidence only" "project check declares evidence scope"

assert_exit 2 "invalid project-check boolean is rejected" \
  env REQUIRED_FILES='' REQUIRE_TESTS=maybe REQUIRE_CI=0 "$PROJECT_SCRIPT" "$PROJECT_ROOT"

assert_exit 0 "empty required files and disabled gates are supported" \
  env REQUIRED_FILES='' REQUIRE_TESTS=0 REQUIRE_CI=0 "$PROJECT_SCRIPT" "$PROJECT_ROOT"
assert_output "SKIP  tests" "disabled test gate skips discovery"
assert_output "SKIP  CI configuration" "disabled CI gate skips discovery"

MIGRATION_ROOT="$TEST_TMP/migrations"
mkdir -p "$MIGRATION_ROOT"
printf 'select 1;\n' >"$MIGRATION_ROOT/001_init.sql"
assert_exit 0 "valid migration structure passes" "$MIGRATION_SCRIPT" "$MIGRATION_ROOT"

printf 'select 2;\n' >"$MIGRATION_ROOT/01_duplicate.sql"
assert_exit 1 "normalized duplicate migration prefix fails" "$MIGRATION_SCRIPT" "$MIGRATION_ROOT"
assert_output "Duplicate migration prefixes found" "duplicate migration prefix is reported"

AUTONOMY_ROOT="$TEST_TMP/autonomy-project"
mkdir -p "$AUTONOMY_ROOT/.ai" "$AUTONOMY_ROOT/.github/workflows"
printf '# AI 自主开发\n' >"$AUTONOMY_ROOT/AGENTS.md"
printf '%s\n' \
  'version: 1' \
  'execution_mode: autonomous_ai' \
  'manual_development_allowed: false' \
  'manual_validation_allowed: false' \
  'evidence_required: true' \
  'independent_ai_verification_required: true' \
  'external_authorization_mode: boundary_only' \
  >"$AUTONOMY_ROOT/.ai/workflow-policy.yml"
printf 'name: autonomy\njobs:\n  audit:\n    steps:\n      - run: bash scripts/check-ai-autonomy.sh .\n' \
  >"$AUTONOMY_ROOT/.github/workflows/quality.yml"

assert_exit 0 "autonomous AI project passes policy audit" "$AUTONOMY_SCRIPT" "$AUTONOMY_ROOT"
assert_output "PASS  CI autonomy gate" "autonomy audit verifies the CI gate"

NON_AI_MARKER="$(printf '人%s' '工验收')"
printf '%s\n' "$NON_AI_MARKER" >"$AUTONOMY_ROOT/process.md"
assert_exit 1 "non-AI execution marker fails policy audit" "$AUTONOMY_SCRIPT" "$AUTONOMY_ROOT"
assert_output "BLOCK autonomous AI policy violations" "autonomy audit reports policy violations"

rm -f "$AUTONOMY_ROOT/process.md"
printf '%s\n' '- [ ] verify' >"$AUTONOMY_ROOT/process.md"
assert_exit 1 "blank checklist gate fails policy audit" "$AUTONOMY_SCRIPT" "$AUTONOMY_ROOT"
assert_output "process.md:1:- [ ] verify" "blank checklist evidence includes file and line"

echo
printf 'RESULT: %s passed, %s failed\n' "$PASSED" "$FAILED"
[[ "$FAILED" -eq 0 ]]

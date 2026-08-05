#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-.}"
REQUIRED_FILES_VALUE="${REQUIRED_FILES-AGENTS.md:.gitignore}"
REQUIRE_TESTS_VALUE="${REQUIRE_TESTS:-1}"
REQUIRE_CI_VALUE="${REQUIRE_CI:-1}"
CHECK_PROJECT_DOCS_VALUE="${CHECK_PROJECT_DOCS:-0}"
CI_QUALITY_REGEX_VALUE="${CI_QUALITY_REGEX:-lint|typecheck|test|build|check|verify|quality|make[[:space:]]+ci}"
FAILED=0

if [[ ! -d "$ROOT" ]]; then
  echo "Project root not found: $ROOT" >&2
  exit 2
fi

ROOT="$(cd "$ROOT" && pwd -P)" || exit 2

for boolean_setting in \
  "REQUIRE_TESTS:$REQUIRE_TESTS_VALUE" \
  "REQUIRE_CI:$REQUIRE_CI_VALUE" \
  "CHECK_PROJECT_DOCS:$CHECK_PROJECT_DOCS_VALUE"; do
  setting_name="${boolean_setting%%:*}"
  setting_value="${boolean_setting##*:}"
  if [[ "$setting_value" != "0" && "$setting_value" != "1" ]]; then
    printf 'Invalid %s value: %s (expected 0 or 1)\n' "$setting_name" "$setting_value" >&2
    exit 2
  fi
done

find_up_file() {
  local path="$1"
  local current="$ROOT"

  while :; do
    if [[ -f "$current/$path" ]]; then
      printf '%s\n' "$current/$path"
      return 0
    fi
    [[ "$current" == "/" ]] && break
    current="$(dirname "$current")"
  done
  return 1
}

check_file() {
  local path="$1"
  local resolved

  if [[ "$path" == "AGENTS.md" ]]; then
    if resolved="$(find_up_file "$path")"; then
      printf 'PASS  %s (%s)\n' "$path" "$resolved"
    else
      printf 'MISS  %s (project root or parent directories)\n' "$path"
      FAILED=1
    fi
    return
  fi

  if [[ -f "$ROOT/$path" ]]; then
    printf 'PASS  %s\n' "$path"
  else
    printf 'MISS  %s\n' "$path"
    FAILED=1
  fi
}

has_test_files() {
  find "$ROOT" \
    \( -name .git -o -name node_modules -o -name vendor -o -name dist -o -name build \) -prune -o \
    -type f \( \
      -name '*.test.*' -o -name '*.spec.*' -o -name 'test_*.py' -o -name '*_test.go' -o \
      -name '*_test.rs' -o -name '*Test.java' -o -path '*/tests/test*' -o -path '*/src/test/*' \
    \) \
    -print -quit | grep -q .
}

has_ci_config() {
  local candidate
  local workflow

  if [[ -d "$ROOT/.github/workflows" ]]; then
    while IFS= read -r -d '' workflow; do
      if grep -Eiq "$CI_QUALITY_REGEX_VALUE" "$workflow"; then
        return 0
      fi
    done < <(find "$ROOT/.github/workflows" -maxdepth 1 -type f \
      \( -name '*.yml' -o -name '*.yaml' \) -size +0c -print0)
  fi

  for candidate in \
    .gitlab-ci.yml \
    Jenkinsfile \
    azure-pipelines.yml \
    .circleci/config.yml; do
    if [[ -s "$ROOT/$candidate" ]] && grep -Eiq "$CI_QUALITY_REGEX_VALUE" "$ROOT/$candidate"; then
      return 0
    fi
  done
  return 1
}

echo "Development workflow project check"
echo "Root: $ROOT"
echo

if [[ -n "$REQUIRED_FILES_VALUE" ]]; then
  IFS=':' read -r -a required_files <<< "$REQUIRED_FILES_VALUE"
  for required_file in "${required_files[@]}"; do
    [[ -n "$required_file" ]] && check_file "$required_file"
  done
fi

if [[ "$CHECK_PROJECT_DOCS_VALUE" == "1" ]]; then
  if [[ -f "$ROOT/README.md" || -f "$ROOT/README" ]]; then
    echo "PASS  project documentation"
  else
    echo "WARN  project documentation not found"
  fi

  if [[ -f "$ROOT/CHANGELOG.md" || -f "$ROOT/CHANGELOG" ]]; then
    echo "PASS  changelog"
  else
    echo "WARN  changelog not found"
  fi
fi

if [[ "$REQUIRE_TESTS_VALUE" == "0" ]]; then
  echo "SKIP  tests"
elif has_test_files; then
  echo "PASS  tests"
else
  echo "MISS  tests"
  FAILED=1
fi

if [[ "$REQUIRE_CI_VALUE" == "0" ]]; then
  echo "SKIP  CI configuration"
elif has_ci_config; then
  echo "PASS  CI configuration"
else
  echo "MISS  CI configuration"
  FAILED=1
fi

if [[ -d "$ROOT/migrations" || -d "$ROOT/db/migrations" ]]; then
  echo "PASS  migration directory"
else
  echo "WARN  migration directory not found"
fi

echo
if [[ "$FAILED" -eq 0 ]]; then
  echo "RESULT: PASS"
else
  echo "RESULT: INCOMPLETE"
fi
echo "SCOPE: structural evidence only; no test or CI command was executed."

exit "$FAILED"

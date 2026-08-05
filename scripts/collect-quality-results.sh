#!/usr/bin/env bash
set -uo pipefail

ROOT="${1:-.}"
REQUIRED_CHECKS="${REQUIRED_QUALITY_CHECKS:-}"
SUPPORTED_CHECKS=(lint typecheck test build migration security)
REQUIRED_ITEMS_CSV=","

if [[ ! -d "$ROOT" ]]; then
  echo "Project root not found: $ROOT" >&2
  exit 2
fi

validate_required_checks() {
  local item
  local normalized="${REQUIRED_CHECKS//:/,}"
  local raw_required_items=()

  [[ -z "$normalized" ]] && return 0
  IFS=',' read -r -a raw_required_items <<< "$normalized"
  for item in "${raw_required_items[@]}"; do
    item="${item//[[:space:]]/}"
    [[ -z "$item" ]] && continue
    case "$item" in
      lint|typecheck|test|build|migration|security)
        REQUIRED_ITEMS_CSV="${REQUIRED_ITEMS_CSV}${item},"
        ;;
      *)
        printf 'Unsupported required quality check: %s\n' "$item" >&2
        printf 'Allowed checks: %s\n' "${SUPPORTED_CHECKS[*]}" >&2
        return 2
        ;;
    esac
  done
}

is_required() {
  local target="$1"
  [[ "$REQUIRED_ITEMS_CSV" == *",$target,"* ]]
}

run_check() {
  local name="$1"
  local command="$2"
  local status

  echo "== $name =="
  printf 'COMMAND: %s\n' "$command"
  (cd "$ROOT" && bash -c "$command")
  status=$?
  if [[ "$status" -eq 0 ]]; then
    echo "PASS: $name"
    echo
    return 0
  fi
  printf 'FAIL: %s (exit=%s)\n' "$name" "$status"
  echo
  return 1
}

validate_required_checks || exit $?

FAILED=0
CONFIGURED=0

for item in \
  "lint:LINT_CMD" \
  "typecheck:TYPECHECK_CMD" \
  "test:TEST_CMD" \
  "build:BUILD_CMD" \
  "migration:MIGRATION_CMD" \
  "security:SECURITY_CMD"; do
  name="${item%%:*}"
  variable="${item##*:}"
  command="${!variable:-}"

  if [[ -n "$command" ]]; then
    CONFIGURED=$((CONFIGURED + 1))
    run_check "$name" "$command" || FAILED=1
  elif is_required "$name"; then
    echo "MISS: $name ($variable is required but not configured)"
    FAILED=1
  else
    echo "SKIP: $name ($variable is not configured)"
  fi
done

echo
if [[ "$CONFIGURED" -eq 0 ]]; then
  if [[ "$FAILED" -ne 0 ]]; then
    echo "Required quality commands were not configured." >&2
    exit 1
  fi
  echo "No quality commands were configured." >&2
  exit 2
fi

if [[ "$FAILED" -eq 0 ]]; then
  echo "All configured quality checks passed."
else
  echo "One or more quality checks failed."
fi

exit "$FAILED"

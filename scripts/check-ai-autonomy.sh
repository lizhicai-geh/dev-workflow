#!/usr/bin/env bash
set -uo pipefail

ROOT="${1:-.}"
FAILED=0

if [[ ! -d "$ROOT" ]]; then
  echo "Project root not found: $ROOT" >&2
  exit 2
fi

ROOT="$(cd "$ROOT" && pwd -P)" || exit 2
POLICY_FILE="$ROOT/.ai/workflow-policy.yml"
AGENTS_FILE="$ROOT/AGENTS.md"
HITS_FILE="$(mktemp "${TMPDIR:-/tmp}/ai-autonomy-hits.XXXXXX")"
trap 'rm -f "$HITS_FILE"' EXIT

pass() {
  printf 'PASS  %s\n' "$1"
}

miss() {
  printf 'MISS  %s\n' "$1"
  FAILED=1
}

has_autonomy_ci() {
  local candidate
  local workflow

  if [[ -d "$ROOT/.github/workflows" ]]; then
    while IFS= read -r -d '' workflow; do
      if grep -Fq 'check-ai-autonomy.sh' "$workflow"; then
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
    if [[ -s "$ROOT/$candidate" ]] && grep -Fq 'check-ai-autonomy.sh' "$ROOT/$candidate"; then
      return 0
    fi
  done
  return 1
}

echo "AI autonomy audit"
echo "Root: $ROOT"
echo

if [[ -f "$POLICY_FILE" ]]; then
  pass ".ai/workflow-policy.yml"
  for marker in \
    'execution_mode: autonomous_ai' \
    'manual_development_allowed: false' \
    'manual_validation_allowed: false' \
    'evidence_required: true' \
    'independent_ai_verification_required: true' \
    'external_authorization_mode: boundary_only'; do
    if grep -Fqx "$marker" "$POLICY_FILE"; then
      pass "policy marker: $marker"
    else
      miss "policy marker: $marker"
    fi
  done
else
  miss ".ai/workflow-policy.yml"
fi

if [[ -f "$AGENTS_FILE" ]] && grep -Fq 'AI 自主开发' "$AGENTS_FILE"; then
  pass "AGENTS.md autonomous AI rules"
else
  miss "AGENTS.md autonomous AI rules"
fi

if has_autonomy_ci; then
  pass "CI autonomy gate"
else
  miss "CI autonomy gate"
fi

FORBIDDEN_REGEX='AI[[:space:]]*辅助开发|人工|手动|用户(测试|验收|审查|执行|填写|勾选)|负责人|责任人|待指定|AI[[:space:]-]*assisted[[:space:]]+development|human[[:space:]-]+(development|coding|test|testing|validation|acceptance|review|approval|operation)|manual[[:space:]-]+(development|coding|test|testing|validation|acceptance|review|approval|operation)|^[[:space:]]*-[[:space:]]*\[[[:space:]]\]'
SCAN_ERROR=0

while IFS= read -r -d '' file; do
  grep -IHniE "$FORBIDDEN_REGEX" "$file" >>"$HITS_FILE"
  grep_status=$?
  if [[ "$grep_status" -gt 1 ]]; then
    printf 'SCAN_ERROR %s (grep exit=%s)\n' "$file" "$grep_status" >&2
    SCAN_ERROR=1
  fi
done < <(find "$ROOT" \
  \( -name .git -o -name node_modules -o -name vendor -o -name dist -o -name build -o -name coverage \) -prune -o \
  -type f ! -name 'check-ai-autonomy.sh' \
  -print0)

if [[ "$SCAN_ERROR" -ne 0 ]]; then
  miss "complete repository text scan"
fi

if [[ -s "$HITS_FILE" ]]; then
  echo "BLOCK autonomous AI policy violations:"
  sed 's/^/  /' "$HITS_FILE"
  FAILED=1
else
  pass "no non-AI execution markers or blank checklist gates"
fi

echo
if [[ "$FAILED" -eq 0 ]]; then
  echo "RESULT: PASS"
else
  echo "RESULT: INCOMPLETE"
fi

exit "$FAILED"

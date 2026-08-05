#!/usr/bin/env bash
set -euo pipefail

DIR="${1:-migrations}"
NAME_REGEX="${MIGRATION_NAME_REGEX:-^([0-9]+)[_-].+}"

if [[ ! -d "$DIR" ]]; then
  echo "Migration directory not found: $DIR" >&2
  exit 2
fi

TMP_PREFIXES="$(mktemp)"
trap 'rm -f "$TMP_PREFIXES"' EXIT

FILE_COUNT=0
FAILED=0

while IFS= read -r -d '' file; do
  FILE_COUNT=$((FILE_COUNT + 1))
  name="$(basename "$file")"

  if [[ ! -s "$file" ]]; then
    printf 'EMPTY %s\n' "$file" >&2
    FAILED=1
  fi

  if [[ "$name" =~ $NAME_REGEX ]]; then
    prefix="${BASH_REMATCH[1]:-}"
    if [[ ! "$prefix" =~ ^[0-9]+$ ]]; then
      printf 'INVALID_PREFIX %s (first regex capture must be numeric)\n' "$name" >&2
      FAILED=1
      continue
    fi
    normalized_prefix="$((10#$prefix))"
    printf '%s\t%s\n' "$normalized_prefix" "$name" >> "$TMP_PREFIXES"
  else
    printf 'INVALID_NAME %s\n' "$name" >&2
    FAILED=1
  fi
done < <(find "$DIR" -maxdepth 1 -type f ! -name '.*' -print0)

if [[ "$FILE_COUNT" -eq 0 ]]; then
  echo "No migration files found: $DIR" >&2
  exit 1
fi

DUPLICATES="$(cut -f1 "$TMP_PREFIXES" | sort -n | uniq -d)"
if [[ -n "$DUPLICATES" ]]; then
  echo "Duplicate migration prefixes found:" >&2
  while IFS= read -r duplicate; do
    awk -F '\t' -v prefix="$duplicate" '$1 == prefix { print "  " $2 }' "$TMP_PREFIXES" >&2
  done <<< "$DUPLICATES"
  FAILED=1
fi

if [[ "$FAILED" -ne 0 ]]; then
  echo "Migration structure check failed: $DIR" >&2
  exit 1
fi

echo "Migration structure check passed: $DIR ($FILE_COUNT files)"

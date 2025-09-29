#!/usr/bin/env bash
set -euo pipefail

# --- run model & helpers ---
log() { printf "[%s] %s\n" "$(date +%T)" "$*"; }
die() { printf "[ERROR] %s\n" "$*" >&2; exit 1; }

# --- arguments and defaults ---
# usage: ./day1_basics.sh input_file [max_lines]
INPUT_FILE="${1:-/etc/hosts}"
MAX_LINES="${2:-3}"

# --- preconditions ---
[[ -r "$INPUT_FILE" ]] || die "cannot read $INPUT_FILE"
[[ "$MAX_LINES" =~ ^[0-9]+$ ]] || die "max_lines must be integer"

# --- variables, command substitution, arithmetic ---
FILE_BASENAME="$(basename "$INPUT_FILE")"
LINE_COUNT="$(wc -l < "$INPUT_FILE")"
SHOW_LINES=$(( MAX_LINES < LINE_COUNT ? MAX_LINES : LINE_COUNT ))

log "file: $FILE_BASENAME, total_lines: $LINE_COUNT, show_first: $SHOW_LINES"

# --- functions, conditionals, loops ---
print_head() {
  local n="$1" f="$2" i=1
  while IFS= read -r line; do
    printf "%2d| %s\n" "$i" "$line"
    (( i++ >= n )) && break
  done < "$f"
}

if [[ "$SHOW_LINES" -eq 0 ]]; then
  log "nothing to show"
else
  log "head of file:"
  print_head "$SHOW_LINES" "$INPUT_FILE"
fi

# --- text processing mini-tour ---
log "grep example: lines containing '127.0.0.1' (if any)"
grep -n "127\.0\.0\.1" "$INPUT_FILE" || true

log "awk example: print line number and first column"
awk '{print NR ":" $1}' "$INPUT_FILE" | head -n "$SHOW_LINES"

log "sed example: replace tabs with 4 spaces (preview only)"
sed $'s/\t/    /g' "$INPUT_FILE" | head -n "$SHOW_LINES"

# --- exit codes demo ---
log "demonstrate pipeline safety with set -euo pipefail"
echo "OK" | grep O >/dev/null
log "done"

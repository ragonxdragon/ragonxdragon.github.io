#!/bin/sh
# Pre-publish check for the case studies.
#   sh scripts/prepublish-check.sh          report problems, exit 1 if any
#   sh scripts/prepublish-check.sh --strip  remove <!-- src: ... --> comments in place, then check
# Confidential terms are read from .confidential-terms (one per line, gitignored, never committed).
set -u
cd "$(dirname "$0")/.." || exit 2
files=$(find . -name '*.html' -not -path './.git/*')
status=0

if [ "${1:-}" = "--strip" ]; then
  for f in $files; do
    sed -i 's/<!-- src:[^>]*-->//g' "$f"
  done
fi

if grep -q '<!-- src:' $files; then
  grep -c '<!-- src:' $files | grep -v ':0$'
  echo "FAIL: source comments remain (run with --strip before publishing)"
  status=1
fi

if grep -l 'name="robots" content="noindex"' $files; then
  echo "NOTE: noindex is still set on the pages above"
fi

if [ -f .confidential-terms ]; then
  while IFS= read -r term; do
    [ -z "$term" ] && continue
    if grep -n -i -F -- "$term" $files; then
      echo "FAIL: confidential term found: $term"
      status=1
    fi
  done < .confidential-terms
else
  echo "WARN: .confidential-terms missing, term scan skipped"
fi

# Twelve-hex-digit strings look like device IDs (MAC-derived).
if grep -n -E '\b[0-9A-Fa-f]{12}\b' $files; then
  echo "FAIL: possible device ID"
  status=1
fi

[ "$status" -eq 0 ] && echo "OK: no findings"
exit "$status"

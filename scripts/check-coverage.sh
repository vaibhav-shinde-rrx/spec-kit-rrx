#!/usr/bin/env bash
# RRX: deterministic AC vs TC coverage check.
# Ensures every AC found in spec.md has at least one TC in rrx/test-cases.md
# and that trace-ac.md lists the same TC ids (when present).
#
# Usage:
#   check-coverage.sh --feature-dir /path/to/specs/001-feature [--strict-trace]
#
# Exit codes: 0 = OK, 1 = gap found

set -euo pipefail

FEATURE_DIR=""
STRICT_TRACE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --feature-dir) FEATURE_DIR="$2"; shift 2 ;;
    --strict-trace) STRICT_TRACE=true; shift ;;
    -h|--help)
      sed -n '1,20p' "$0"
      exit 0
      ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$FEATURE_DIR" || ! -d "$FEATURE_DIR" ]]; then
  echo "ERROR: --feature-dir must point to an existing feature directory" >&2
  exit 1
fi

SPEC="$FEATURE_DIR/spec.md"
TCASES="$FEATURE_DIR/rrx/test-cases.md"
TRACE="$FEATURE_DIR/rrx/trace-ac.md"

if [[ ! -f "$SPEC" ]]; then
  echo "ERROR: missing spec: $SPEC" >&2
  exit 1
fi

if [[ ! -f "$TCASES" ]]; then
  echo "ERROR: missing $TCASES (run /speckit.rrx.spec first)" >&2
  exit 1
fi

# Collect AC ids (AC-01, AC-12, ...)
mapfile -t ACS < <(grep -oE '\bAC-[0-9]+\b' "$SPEC" | sort -u || true)
if [[ ${#ACS[@]} -eq 0 ]]; then
  echo "WARN: no AC-NN tokens found in spec.md — nothing to cover" >&2
  exit 1
fi

missing=()
for ac in "${ACS[@]}"; do
  stem="${ac#AC-}"
  # TC ids use zero-padded 3-digit stem (TC-003-A for AC-03); allow 1–3 digit forms
  if ! grep -qE "(^## ${ac}\b|\bTC-0*${stem}-[A-Z]+\b)" "$TCASES"; then
    missing+=("$ac")
  fi
done

if [[ ${#missing[@]} -gt 0 ]]; then
  echo "RRX coverage gate: FAIL"
  echo "Acceptance criteria in spec.md without TC coverage in test-cases.md:"
  printf '  - %s\n' "${missing[@]}"
  exit 1
fi

if $STRICT_TRACE && [[ -f "$TRACE" ]]; then
  for ac in "${ACS[@]}"; do
    if ! grep -qF "$ac" "$TRACE"; then
      echo "RRX coverage gate: FAIL (trace-ac.md missing row for $ac)" >&2
      exit 1
    fi
  done
fi

echo "RRX coverage gate: OK (${#ACS[@]} acceptance criteria have TC stubs in test-cases.md)"
exit 0

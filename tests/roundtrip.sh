#!/usr/bin/env bash
# Cross-language round-trip test for h5cohort.
#   A: R writes  -> Python reads & asserts
#   B: Python writes -> R reads & asserts
# Uses the source trees directly (no install needed): R files are sourced,
# Python package is put on PYTHONPATH.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
RPKG="$ROOT/r"
PYPKG="$ROOT/python"
PY="${PYTHON:-/opt/conda/bin/python3}"
TMP="$(mktemp -d)"
export PYTHONPATH="$PYPKG:${PYTHONPATH:-}"

echo "=== Direction A: R -> Python ==="
Rscript "$HERE/step1_r_write.R" "$RPKG" "$TMP/fromR.h5"
"$PY" "$HERE/step2_py_read.py" "$TMP/fromR.h5"

echo
echo "=== Direction B: Python -> R ==="
"$PY" "$HERE/step3_py_write.py" "$TMP/fromPy.h5"
Rscript "$HERE/step4_r_read.R" "$RPKG" "$TMP/fromPy.h5"

echo
echo "=== ALL ROUND-TRIP TESTS PASSED ==="
rm -rf "$TMP"

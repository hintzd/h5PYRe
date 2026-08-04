#!/usr/bin/env bash
# Cross-language round-trip test for h5PYRe.
#   A: R writes  -> Python reads & asserts
#   B: Python writes -> R reads & asserts
#   C: Python writes an image -> R reads/exports -> Python checks pixels
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
echo "=== Direction C: images (Python -> R -> disk) ==="
"$PY" "$HERE/step5_py_write_img.py" "$TMP"
Rscript "$HERE/step6_r_read_img.R" "$RPKG" "$TMP"
"$PY" "$HERE/step7_py_check_img.py" "$TMP"

echo
echo "=== Direction D: params YAML (Python <-> R) ==="
"$PY" "$HERE/step8_py_params_yaml.py" "$TMP/paramsPy.h5" "$TMP"
Rscript "$HERE/step9_r_params_yaml.R" "$RPKG" "$TMP"
"$PY" "$HERE/step10_py_check_params.py" "$TMP"

echo
echo "=== ALL ROUND-TRIP TESTS PASSED ==="
rm -rf "$TMP"

#!/usr/bin/env bash
# run_tests.sh — Run the ToyFactory02 automated test suite.
#
# Usage:
#   ./run_tests.sh          # auto-detect Godot
#   GODOT=/path/to/godot ./run_tests.sh
#
# Exit code mirrors the test runner: 0 = all pass, 1 = any failure.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Locate Godot binary ───────────────────────────────────────────────
if [[ -n "${GODOT:-}" ]]; then
	GODOT_BIN="$GODOT"
elif command -v godot4 &>/dev/null; then
	GODOT_BIN="godot4"
elif command -v godot &>/dev/null; then
	GODOT_BIN="godot"
elif [[ -x "/Applications/Godot.app/Contents/MacOS/Godot" ]]; then
	GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"
elif [[ -x "/Applications/Godot_v4.6-stable_macos.universal.app/Contents/MacOS/Godot" ]]; then
	GODOT_BIN="/Applications/Godot_v4.6-stable_macos.universal.app/Contents/MacOS/Godot"
else
	echo "❌  Godot binary not found."
	echo "    Set the GODOT env variable or add godot/godot4 to your PATH."
	exit 1
fi

echo "🔍  Using Godot: $GODOT_BIN"
echo "📁  Project:     $SCRIPT_DIR"
echo ""

# ── Run tests ─────────────────────────────────────────────────────────
"$GODOT_BIN" \
	--headless \
	--path "$SCRIPT_DIR" \
	--script tests/run_tests.gd \
	"$@"

#!/usr/bin/env bash
set -euo pipefail

APP="${1:-chatbot}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
VENV_DIR="$PROJECT_DIR/venv"

echo "=== Demo Reset ==="
echo ""

if [[ -d "$VENV_DIR" ]]; then
    echo "  \$ rm -rf venv"
    rm -rf "$VENV_DIR"
fi

echo "Recreating environment with unpatched dependencies..."
"$SCRIPT_DIR/setup.sh" "$APP"

echo ""
echo "Reset complete. Ready for next demo run."

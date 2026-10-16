#!/usr/bin/env bash
set -euo pipefail

APP="${1:-chatbot}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
REQ_FILE="$PROJECT_DIR/$APP/requirements.txt"
VENV_DIR="$PROJECT_DIR/venv"

if [[ ! -f "$REQ_FILE" ]]; then
    echo "ERROR: $REQ_FILE not found. Choose 'minimal' or 'chatbot'."
    exit 1
fi

echo "=== Lightwell Demo Setup ==="
echo "App: $APP"
echo ""

if [[ -d "$VENV_DIR" ]]; then
    echo "Removing existing venv..."
    rm -rf "$VENV_DIR"
fi

echo "Creating virtual environment..."
echo "  \$ python3 -m venv venv"
python3 -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"

echo ""
echo "Installing dependencies from PyPI (unpatched versions)..."
echo "  \$ pip install -r $APP/requirements.txt"
pip install --quiet -r "$REQ_FILE"

echo ""
echo "Installing scanner..."
echo "  \$ pip install pip-audit"
pip install --quiet pip-audit

echo ""
echo "Setup complete. Dependencies installed from PyPI (unpatched)."
echo "Run 'make scan' to check for vulnerabilities."

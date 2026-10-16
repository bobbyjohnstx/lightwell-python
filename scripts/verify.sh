#!/usr/bin/env bash
set -euo pipefail

APP="${1:-chatbot}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
REQ_FILE="$PROJECT_DIR/$APP/requirements.txt"
VENV_DIR="$PROJECT_DIR/venv"

echo "=== Version Verification ==="
echo ""

if [[ ! -d "$VENV_DIR" ]]; then
    echo "ERROR: No venv found. Run 'make setup' first."
    exit 1
fi

source "$VENV_DIR/bin/activate"

FOUND_RHLW=false

while IFS= read -r line; do
    pkg=$(echo "$line" | sed 's/[=<>!].*//' | tr -d '[:space:]')
    [[ -z "$pkg" || "$pkg" == \#* ]] && continue

    version=$(pip show "$pkg" 2>/dev/null | grep "^Version:" | awk '{print $2}')
    if [[ -z "$version" ]]; then
        echo "  $pkg: NOT INSTALLED"
        continue
    fi

    if [[ "$version" == *"+rhlw"* ]]; then
        echo "  ✓ $pkg==$version  [PATCHED by Lightwell]"
        FOUND_RHLW=true
    else
        echo "  ✗ $pkg==$version  [unpatched]"
    fi
done < "$REQ_FILE"

echo ""
if $FOUND_RHLW; then
    echo "Lightwell remediation confirmed — patched versions detected."
else
    echo "WARNING: No +rhlw versions found."
    echo "Check that 'make remediate' was run and ~/.netrc is configured."
fi

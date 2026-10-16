#!/usr/bin/env bash
set -euo pipefail

APP="${1:-chatbot}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
REQ_FILE="$PROJECT_DIR/$APP/requirements.txt"
VENV_DIR="$PROJECT_DIR/venv"
LIGHTWELL_URL="https://packages.redhat.com/lightwell/python/remediated/simple/"

if [[ ! -f "$REQ_FILE" ]]; then
    echo "ERROR: $REQ_FILE not found."
    exit 1
fi

if [[ ! -d "$VENV_DIR" ]]; then
    echo "ERROR: No venv found. Run 'make setup' first."
    exit 1
fi

if ! grep -q "packages.redhat.com" ~/.netrc 2>/dev/null; then
    echo "ERROR: No Lightwell credentials found in ~/.netrc"
    echo ""
    echo "Add the following to ~/.netrc:"
    echo "  machine packages.redhat.com login <username> password <token>"
    echo ""
    echo "See: https://docs.redhat.com/en/documentation/red_hat_lightwell_network/current/configure-configure_python_build_tool"
    exit 1
fi

echo "=== Lightwell Remediation ==="
echo ""
echo "Installing patched packages from Red Hat Lightwell Network (Remediated)..."
echo "URL: $LIGHTWELL_URL"
echo ""

source "$VENV_DIR/bin/activate"

# Extract package names from requirements.txt (strip version pins)
# Skip infrastructure packages not targeted for remediation
SKIP_PACKAGES="Flask flask Werkzeug werkzeug Jinja2 jinja2 itsdangerous click MarkupSafe blinker"

PACKAGES=""
while IFS= read -r line; do
    pkg=$(echo "$line" | sed 's/[=<>!].*//' | tr -d '[:space:]')
    [[ -z "$pkg" || "$pkg" == \#* ]] && continue
    if echo " $SKIP_PACKAGES " | grep -qi " $pkg "; then
        continue
    fi
    PACKAGES="$PACKAGES $pkg"
done < "$REQ_FILE"

echo "Packages to remediate:$PACKAGES"
echo ""

# Install from Lightwell — packages not in the catalog will fail gracefully
for pkg in $PACKAGES; do
    echo "  \$ pip install --index-url $LIGHTWELL_URL $pkg"
    OUTPUT=$(pip install --force-reinstall --no-deps --index-url "$LIGHTWELL_URL" "$pkg" --quiet 2>&1) || true
    if [[ "$OUTPUT" != *"ERROR"* ]] && [[ "$OUTPUT" != *"No matching distribution"* ]]; then
        version=$(pip show "$pkg" 2>/dev/null | grep "^Version:" | awk '{print $2}')
        echo "  ✓ $pkg==$version  [remediated]"
    else
        if echo "$OUTPUT" | grep -qi "401\|403\|unauthorized\|forbidden"; then
            echo "  ERROR: Authentication failed for $pkg. Check ~/.netrc credentials."
            echo "  $OUTPUT" | tail -2
        elif echo "$OUTPUT" | grep -qi "No matching distribution"; then
            echo "  - $pkg: not in Lightwell catalog (keeping PyPI version)"
        else
            echo "  ERROR: Failed to install $pkg from Lightwell:"
            echo "  $OUTPUT" | tail -3
        fi
    fi
    echo ""
done

echo "Remediation complete."
echo "Run 'make verify' to confirm patched versions."

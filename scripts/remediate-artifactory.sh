#!/usr/bin/env bash
set -euo pipefail

APP="${1:-chatbot}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
REQ_FILE="$PROJECT_DIR/$APP/requirements.txt"
VENV_DIR="$PROJECT_DIR/venv"

# JFrog Cloud free tier (jfrog.com/start-free) — has Pro features including PyPI repos.
# Set JFROG_INSTANCE to your instance name.
JFROG_INSTANCE="${JFROG_INSTANCE:-your-instance}"
JFROG_REPO="${JFROG_REPO:-lightwell-python-local}"
JFROG_URL="https://${JFROG_INSTANCE}.jfrog.io/artifactory/api/pypi/${JFROG_REPO}/simple/"

if [[ ! -f "$REQ_FILE" ]]; then
    echo "ERROR: $REQ_FILE not found."
    exit 1
fi

if [[ ! -d "$VENV_DIR" ]]; then
    echo "ERROR: No venv found. Run 'make setup' first."
    exit 1
fi

if ! grep -q "${JFROG_INSTANCE}.jfrog.io" ~/.netrc 2>/dev/null; then
    echo "ERROR: No JFrog credentials found in ~/.netrc"
    echo ""
    echo "Add the following to ~/.netrc:"
    echo "  machine ${JFROG_INSTANCE}.jfrog.io login <email> password <identity-token>"
    exit 1
fi

echo "=== Lightwell Remediation (via Artifactory) ==="
echo ""
echo "Artifactory: https://${JFROG_INSTANCE}.jfrog.io"
echo "Repository:  ${JFROG_REPO}"
echo "Proxying:    Red Hat Lightwell Network (Remediated)"
echo ""

source "$VENV_DIR/bin/activate"

PACKAGES=""
while IFS= read -r line; do
    pkg=$(echo "$line" | sed 's/[=<>!].*//' | tr -d '[:space:]')
    [[ -z "$pkg" || "$pkg" == \#* ]] && continue
    PACKAGES="$PACKAGES $pkg"
done < "$REQ_FILE"

echo "Packages to remediate:$PACKAGES"
echo ""

for pkg in $PACKAGES; do
    echo "  Checking $pkg in Lightwell catalog (via Artifactory)..."
    OUTPUT=$(pip install --force-reinstall --no-deps --index-url "$JFROG_URL" "$pkg" --quiet 2>&1) || true
    if [[ "$OUTPUT" != *"ERROR"* ]] && [[ "$OUTPUT" != *"No matching distribution"* ]]; then
        version=$(pip show "$pkg" 2>/dev/null | grep "^Version:" | awk '{print $2}')
        echo "  ✓ $pkg==$version  [remediated via Artifactory]"
    else
        if echo "$OUTPUT" | grep -qi "401\|403\|unauthorized\|forbidden"; then
            echo "  ERROR: Authentication failed. Check ~/.netrc credentials for ${JFROG_INSTANCE}.jfrog.io"
            echo "  $OUTPUT" | tail -2
        elif echo "$OUTPUT" | grep -qi "No matching distribution"; then
            echo "  - $pkg: not in Lightwell catalog (keeping PyPI version)"
        else
            echo "  ERROR: Failed to install $pkg:"
            echo "  $OUTPUT" | tail -3
        fi
    fi
done

echo ""
echo "Remediation complete (via Artifactory)."
echo "Run 'make verify' to confirm patched versions."
echo ""
echo "In production, this Artifactory remote repo caches Lightwell packages"
echo "locally — subsequent installs are served from cache, not the internet."

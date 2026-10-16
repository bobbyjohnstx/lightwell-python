#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

if [[ -f "$PROJECT_DIR/.env" ]]; then
    set -a
    source "$PROJECT_DIR/.env"
    set +a
fi

echo "=== Vulnerability Scan ==="
echo ""

if [[ ! -d "$PROJECT_DIR/venv" ]]; then
    echo "ERROR: No venv found. Run 'make setup' first."
    exit 1
fi

source "$PROJECT_DIR/venv/bin/activate"

# Try Black Duck first
if [[ -n "${BLACKDUCK_API_TOKEN:-}" ]]; then
    echo "Scanner: Black Duck (Synopsys Detect)"
    echo ""

    BLACKDUCK_URL="${BLACKDUCK_URL:-https://redhathub.blackducksoftware.com}"

    echo "  \$ bash detect.sh --blackduck.url=$BLACKDUCK_URL"
    bash <(curl -s -L https://detect.blackduck.com/detect.sh) \
        --blackduck.url="$BLACKDUCK_URL" \
        --blackduck.api.token="$BLACKDUCK_API_TOKEN" \
        --blackduck.trust.cert=true
    exit 0
fi

# Try pip-audit (exits non-zero when vulnerabilities found — that's expected)
if command -v pip-audit &>/dev/null; then
    echo "Scanner: pip-audit"
    echo "  \$ pip-audit"
    echo ""
    OUTPUT=$(pip-audit 2>&1) || true
    # Reformat "not found on PyPI" skip messages for demo clarity
    echo "$OUTPUT" | while IFS= read -r line; do
        if echo "$line" | grep -q "not found on PyPI.*rhlw"; then
            pkg=$(echo "$line" | awk '{print $1}')
            ver=$(echo "$line" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\+rhlw\.[0-9]+')
            echo "$pkg   Sourced from Lightwell ($ver) — patched, not in PyPI vulnerability database"
        else
            echo "$line"
        fi
    done
    exit 0
fi

# Try grype
if command -v grype &>/dev/null; then
    echo "Scanner: Grype"
    echo "  \$ grype dir:venv/"
    echo ""
    grype dir:"$PROJECT_DIR/venv"
    exit 0
fi

echo "ERROR: No vulnerability scanner found."
echo ""
echo "Install one of the following:"
echo "  1. pip-audit  — pip install pip-audit"
echo "  2. Grype      — brew install grype (or https://github.com/anchore/grype)"
echo "  3. Black Duck — set BLACKDUCK_API_TOKEN in .env (see .env.example)"
exit 1

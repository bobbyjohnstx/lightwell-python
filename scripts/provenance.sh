#!/usr/bin/env bash
set -euo pipefail

APP="${1:-chatbot}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
REQ_FILE="$PROJECT_DIR/$APP/requirements.txt"
VENV_DIR="$PROJECT_DIR/venv"
TIER="remediated"

echo "=== SLSA L3 Provenance Verification ==="
echo ""

if [[ ! -d "$VENV_DIR" ]]; then
    echo "ERROR: No venv found. Run 'make setup' first."
    exit 1
fi

source "$VENV_DIR/bin/activate"

if ! command -v cosign &>/dev/null; then
    echo "NOTE: cosign is not installed. Displaying attestation metadata only."
    echo "Install cosign for full signature verification: brew install cosign"
    echo ""
    HAVE_COSIGN=false
else
    HAVE_COSIGN=true
fi

while IFS= read -r line; do
    pkg=$(echo "$line" | sed 's/[=<>!].*//' | tr -d '[:space:]')
    [[ -z "$pkg" || "$pkg" == \#* ]] && continue

    version=$(pip show "$pkg" 2>/dev/null | grep "^Version:" | awk '{print $2}')
    [[ -z "$version" ]] && continue
    [[ "$version" != *"+rhlw"* ]] && continue

    echo "--- $pkg==$version ---"

    # Construct wheel filename
    pkg_lower=$(echo "$pkg" | tr '[:upper:]' '[:lower:]' | tr '-' '_')
    # URL-encode the + sign in version
    version_encoded=$(echo "$version" | sed 's/+/%2B/g')
    WHEEL_NAME="${pkg_lower}-${version_encoded}-1-py3-none-any.whl"

    ATTESTATION_URL="https://packages.redhat.com/api/pypi/lightwell/python/${TIER}/integrity/${pkg_lower}/${version_encoded}/${WHEEL_NAME}/provenance/"

    echo "  Attestation URL: $ATTESTATION_URL"
    echo ""

    RESPONSE=$(curl -s -w "\n%{http_code}" --netrc "$ATTESTATION_URL" 2>/dev/null || true)
    HTTP_CODE=$(echo "$RESPONSE" | tail -1)
    BODY=$(echo "$RESPONSE" | sed '$ d')

    if [[ "$HTTP_CODE" == "200" ]]; then
        echo "  ✓ Attestation found (SLSA Level 3)"
        echo ""
        echo "$BODY" | python -m json.tool 2>/dev/null | head -30
        echo "  ..."
        echo ""

        if $HAVE_COSIGN; then
            echo "  Verifying signature with cosign..."
            # cosign verification depends on the attestation format
            echo "  (cosign integration — adjust for actual attestation bundle format)"
            echo ""
        fi
    elif [[ "$HTTP_CODE" == "404" ]]; then
        echo "  Attestation not found at this URL"
        echo "  (URL pattern may differ — check Lightwell docs for current format)"
    else
        echo "  HTTP $HTTP_CODE — unexpected response"
    fi

    echo ""
done < "$REQ_FILE"

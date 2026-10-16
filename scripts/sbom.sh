#!/usr/bin/env bash
set -euo pipefail

APP="${1:-chatbot}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
REQ_FILE="$PROJECT_DIR/$APP/requirements.txt"
VENV_DIR="$PROJECT_DIR/venv"

echo "=== SBOM Inspection ==="
echo ""

if [[ ! -d "$VENV_DIR" ]]; then
    echo "ERROR: No venv found. Run 'make setup' first."
    exit 1
fi

source "$VENV_DIR/bin/activate"

SITE_PACKAGES=$(python -c "import site; print(site.getsitepackages()[0])")
FOUND_SBOM=false

while IFS= read -r line; do
    pkg=$(echo "$line" | sed 's/[=<>!].*//' | tr -d '[:space:]')
    [[ -z "$pkg" || "$pkg" == \#* ]] && continue

    version=$(pip show "$pkg" 2>/dev/null | grep "^Version:" | awk '{print $2}')
    [[ -z "$version" ]] && continue
    [[ "$version" != *"+rhlw"* ]] && continue

    pkg_underscored=$(echo "$pkg" | tr '-' '_' | tr '[:upper:]' '[:lower:]')

    # Search for SBOM files in dist-info
    DIST_INFO=$(find "$SITE_PACKAGES" -maxdepth 1 -type d -iname "${pkg_underscored}-${version}*.dist-info" 2>/dev/null | head -1)

    if [[ -z "$DIST_INFO" ]]; then
        echo "  $pkg==$version: No dist-info directory found"
        continue
    fi

    SBOM_DIR="$DIST_INFO/sboms"
    if [[ -d "$SBOM_DIR" ]]; then
        SBOM_FILE=$(find "$SBOM_DIR" -name "*.spdx.json" -o -name "*.cdx.json" 2>/dev/null | head -1)
        if [[ -n "$SBOM_FILE" ]]; then
            FOUND_SBOM=true
            echo "--- $pkg==$version ---"
            echo "  SBOM file: $(basename "$SBOM_FILE")"
            echo "  Path: $SBOM_FILE"
            echo ""
            python -m json.tool "$SBOM_FILE" 2>/dev/null | head -50
            echo ""
            echo "  ... (showing first 50 lines — full SBOM at path above)"
            echo ""
        else
            echo "  $pkg==$version: SBOM directory exists but no JSON found in $SBOM_DIR"
        fi
    else
        echo "  $pkg==$version: No sboms/ directory in $DIST_INFO"

        # Check if SBOM might be at another location inside dist-info
        OTHER_JSON=$(find "$DIST_INFO" -name "*.json" -not -name "*.metadata" 2>/dev/null)
        if [[ -n "$OTHER_JSON" ]]; then
            echo "  Found other JSON files:"
            echo "$OTHER_JSON" | while read -r f; do echo "    $(basename "$f")"; done
        fi
    fi
done < "$REQ_FILE"

echo ""
if $FOUND_SBOM; then
    echo "SBOM data available for remediated packages."
else
    echo "No SBOM data found. SBOMs may be in the wheel archive itself."
    echo "Try: pip download <pkg>==<version> && unzip <wheel>.whl -d extracted/"
fi

#!/usr/bin/env bash
set -euo pipefail

APP="${1:-chatbot}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
REQ_FILE="$PROJECT_DIR/$APP/requirements.txt"
OSV_BASE_URL="https://packages.redhat.com/lightwell/osv/python/remediated"

echo "=== Lightwell VEX / OSV Vulnerability Data ==="
echo ""
echo "Source: $OSV_BASE_URL"
echo ""

# Fetch the OSV index
INDEX=$(curl -sL --netrc "$OSV_BASE_URL/" 2>/dev/null)

if [[ -z "$INDEX" ]]; then
    echo "ERROR: Could not fetch OSV index. Check network and ~/.netrc credentials."
    exit 1
fi

# Extract JSON filenames
JSON_FILES=$(echo "$INDEX" | grep -oE 'x_RHLW-CVE-[^"]+\.json' | sort -u)

if [[ -z "$JSON_FILES" ]]; then
    echo "No OSV records found."
    exit 0
fi

echo "Found $(echo "$JSON_FILES" | wc -l | tr -d ' ') vulnerability records for Python remediated packages:"
echo ""

for json_file in $JSON_FILES; do
    DATA=$(curl -sL --netrc "$OSV_BASE_URL/$json_file" 2>/dev/null)

    id=$(echo "$DATA" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null)
    summary=$(echo "$DATA" | python3 -c "import sys,json; print(json.load(sys.stdin).get('summary',''))" 2>/dev/null)
    severity=$(echo "$DATA" | python3 -c "import sys,json; s=json.load(sys.stdin).get('severity',[]); print(s[0].get('score','') if s else 'N/A')" 2>/dev/null)
    pkg=$(echo "$DATA" | python3 -c "import sys,json; a=json.load(sys.stdin).get('affected',[]); print(a[0]['package']['name'] if a else '')" 2>/dev/null)
    fixed=$(echo "$DATA" | python3 -c "import sys,json; a=json.load(sys.stdin).get('affected',[]); r=a[0].get('ranges',[{}]) if a else [{}]; e=r[0].get('events',[]) if r else []; print(next((x['fixed'] for x in e if 'fixed' in x),'N/A'))" 2>/dev/null)
    aliases=$(echo "$DATA" | python3 -c "import sys,json; print(', '.join(json.load(sys.stdin).get('aliases',[])))" 2>/dev/null)

    echo "  $id"
    echo "    Package: $pkg"
    echo "    Fixed in: $fixed"
    echo "    Severity: $severity"
    echo "    Aliases: $aliases"
    echo "    Summary: $summary"
    echo ""
done

echo "---"
echo "This VEX data proves Lightwell has remediated these CVEs."
echo "During the 14-day embargo period, scanners may still flag these"
echo "vulnerabilities — this data is the authoritative record that"
echo "the fix exists in the Lightwell-patched version."

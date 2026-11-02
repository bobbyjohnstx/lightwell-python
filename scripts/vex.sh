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
echo "Fetching OSV index..."
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

TOTAL=$(echo "$JSON_FILES" | wc -l | tr -d ' ')
echo "Found $TOTAL vulnerability records for Python remediated packages."
echo ""

# Bulk-fetch all JSON files in parallel to a temp directory
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

echo "Downloading CVE records (parallel)..."
echo "$JSON_FILES" | xargs -P 20 -I{} \
    curl -sL --netrc -o "$TMPDIR/{}" "$OSV_BASE_URL/{}" 2>/dev/null

echo "Filtering to this project's dependencies..."
echo ""

# Extract package names from requirements.txt
PACKAGES=$(sed 's/[=<>!].*//' "$REQ_FILE" | tr -d '[:space:]' | grep -v '^#' | grep -v '^$' | tr '\n' ' ')

# Process all downloaded files locally with a single python3 invocation
python3 - "$TMPDIR" $PACKAGES << 'PYEOF'
import json, os, sys, glob

tmpdir = sys.argv[1]
packages = [p.lower() for p in sys.argv[2:]]
shown = 0

for f in sorted(glob.glob(os.path.join(tmpdir, "*.json"))):
    try:
        with open(f) as fh:
            data = json.load(fh)
    except (json.JSONDecodeError, IOError):
        continue

    affected = data.get("affected", [])
    if not affected:
        continue

    pkg = affected[0].get("package", {}).get("name", "")
    if not any(p in pkg.lower() for p in packages):
        continue

    vid = data.get("id", "")
    summary = data.get("summary", "")
    severity = data.get("severity", [])
    score = severity[0].get("score", "N/A") if severity else "N/A"

    ranges = affected[0].get("ranges", [{}])
    events = ranges[0].get("events", []) if ranges else []
    fixed = next((x["fixed"] for x in events if "fixed" in x), "N/A")

    aliases = ", ".join(data.get("aliases", []))

    print(f"  {vid}")
    print(f"    Package: {pkg}")
    print(f"    Fixed in: {fixed}")
    print(f"    Severity: {score}")
    print(f"    Aliases: {aliases}")
    print(f"    Summary: {summary}")
    print()
    shown += 1

print("---")
print(f"Showed {shown} CVE records relevant to this project (of {len(glob.glob(os.path.join(tmpdir, '*.json')))} total).")
PYEOF

echo ""
echo "This VEX data proves Lightwell has remediated these CVEs."
echo "During the 14-day embargo period, scanners may still flag these"
echo "vulnerabilities — this data is the authoritative record that"
echo "the fix exists in the Lightwell-patched version."

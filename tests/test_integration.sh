#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

PASS=0
FAIL=0
pass() { echo "  PASS  $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL  $1"; FAIL=$((FAIL + 1)); }

echo "=== Integration Tests (lightwell-python) ==="
echo "Requires: ~/.netrc with packages.redhat.com credentials, network access"
echo ""

if ! grep -q "packages.redhat.com" ~/.netrc 2>/dev/null; then
    echo "SKIP: No Lightwell credentials in ~/.netrc"
    exit 0
fi

# Step 1: Reset
echo "--- Step 1: Reset ---"
make reset APP=minimal >/dev/null 2>&1 && pass "make reset" || fail "make reset"

# Step 2: Verify unpatched
echo "--- Step 2: Verify unpatched ---"
OUTPUT=$(make verify APP=minimal 2>&1)
echo "$OUTPUT" | grep -q "unpatched" && pass "deps are unpatched" || fail "deps are unpatched"
echo "$OUTPUT" | grep -q "WARNING" && pass "warns no +rhlw found" || fail "warns no +rhlw found"

# Step 3: Run minimal app
echo "--- Step 3: Run minimal app ---"
make run-minimal 2>&1 | grep -q "Lightwell Python Demo" && pass "minimal app runs" || fail "minimal app runs"

# Step 4: Scan finds vulnerabilities
echo "--- Step 4: Scan ---"
source venv/bin/activate
pip install --quiet pip-audit 2>/dev/null
OUTPUT=$(make scan 2>&1)
echo "$OUTPUT" | grep -qi "vulnerabilit" && pass "scan finds CVEs" || fail "scan finds CVEs"

# Step 5: Remediate
echo "--- Step 5: Remediate ---"
OUTPUT=$(make remediate APP=minimal 2>&1)
echo "$OUTPUT" | grep -q "remediated" && pass "remediate succeeds" || fail "remediate succeeds"
echo "$OUTPUT" | grep -q "+rhlw" && pass "packages show +rhlw versions" || fail "packages show +rhlw versions"

# Step 6: Verify patched
echo "--- Step 6: Verify patched ---"
OUTPUT=$(make verify APP=minimal 2>&1)
echo "$OUTPUT" | grep -q "PATCHED by Lightwell" && pass "deps show PATCHED" || fail "deps show PATCHED"

# Step 7: Rescan
echo "--- Step 7: Rescan ---"
OUTPUT=$(make scan 2>&1)
echo "$OUTPUT" | grep -q "No known vulnerabilities\|not found on PyPI" && pass "rescan shows remediation" || fail "rescan shows remediation"

# Step 8: VEX
echo "--- Step 8: VEX ---"
OUTPUT=$(make vex APP=minimal 2>&1)
echo "$OUTPUT" | grep -q "Fixed in:" && pass "VEX data fetched" || fail "VEX data fetched"

# Step 9: SBOM
echo "--- Step 9: SBOM ---"
OUTPUT=$(make sbom APP=minimal 2>&1)
echo "$OUTPUT" | grep -q "spdxVersion\|SBOM" && pass "SBOM data found" || fail "SBOM data found"

# Step 10: Provenance
echo "--- Step 10: Provenance ---"
OUTPUT=$(make provenance APP=minimal 2>&1)
echo "$OUTPUT" | grep -q "Attestation found\|attestation" && pass "provenance fetched" || fail "provenance fetched"

# Step 11: Reset back
echo "--- Step 11: Final reset ---"
make reset APP=minimal >/dev/null 2>&1 && pass "final reset" || fail "final reset"
OUTPUT=$(make verify APP=minimal 2>&1)
echo "$OUTPUT" | grep -q "WARNING" && pass "back to unpatched" || fail "back to unpatched"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]

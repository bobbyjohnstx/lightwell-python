#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

PASS=0
WARN=0
FAIL=0

pass() { echo "  ✓  $1"; PASS=$((PASS + 1)); }
warn() { echo "  ⚠  $1"; WARN=$((WARN + 1)); }
fail() { echo "  ✗  $1"; FAIL=$((FAIL + 1)); }

echo "=== Lightwell Python Demo — Environment Check ==="
echo ""

# --- Runtime ---
echo "Runtime:"

if command -v python3 &>/dev/null; then
    PY_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
    PY_MAJOR=$(echo "$PY_VERSION" | cut -d. -f1)
    PY_MINOR=$(echo "$PY_VERSION" | cut -d. -f2)
    if [[ "$PY_MAJOR" -ge 3 && "$PY_MINOR" -ge 12 ]]; then
        pass "Python $PY_VERSION (3.12+ required)"
    else
        fail "Python $PY_VERSION — need 3.12+"
    fi
else
    fail "Python 3 not found"
fi

if command -v pip3 &>/dev/null || command -v pip &>/dev/null; then
    pass "pip available"
else
    fail "pip not found"
fi

# --- Credentials ---
echo ""
echo "Credentials:"

if [[ -f ~/.netrc ]]; then
    NETRC_PERMS=$(stat -f "%Lp" ~/.netrc 2>/dev/null || stat -c "%a" ~/.netrc 2>/dev/null)
    if [[ "$NETRC_PERMS" == "600" ]]; then
        pass "~/.netrc exists (permissions 600)"
    else
        warn "~/.netrc exists but permissions are $NETRC_PERMS (should be 600)"
    fi
else
    fail "~/.netrc not found — Lightwell auth will not work"
fi

if grep -q "packages.redhat.com" ~/.netrc 2>/dev/null; then
    pass "Lightwell credentials found in ~/.netrc"

    # Test authentication
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --netrc --connect-timeout 5 \
        "https://packages.redhat.com/lightwell/python/remediated/simple/" 2>/dev/null)
    if [[ "$HTTP_CODE" == "200" ]]; then
        pass "Lightwell auth verified (HTTP 200)"
    elif [[ "$HTTP_CODE" == "401" || "$HTTP_CODE" == "403" ]]; then
        fail "Lightwell auth failed (HTTP $HTTP_CODE) — token may be expired or revoked"
    elif [[ "$HTTP_CODE" == "000" ]]; then
        warn "Lightwell server unreachable — check network"
    else
        warn "Lightwell returned HTTP $HTTP_CODE — unexpected"
    fi
else
    fail "No packages.redhat.com entry in ~/.netrc"
fi

JFROG_INSTANCE="${JFROG_INSTANCE:-your-instance}"
if grep -q "${JFROG_INSTANCE}.jfrog.io\|jfrog.io" ~/.netrc 2>/dev/null; then
    JFROG_HOST=$(grep "jfrog.io" ~/.netrc 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="machine") print $(i+1)}' | head -1)
    pass "JFrog credentials found in ~/.netrc ($JFROG_HOST)"

    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --netrc --connect-timeout 5 \
        "https://$JFROG_HOST/artifactory/api/system/ping" 2>/dev/null)
    if [[ "$HTTP_CODE" == "200" ]]; then
        pass "JFrog auth verified (HTTP 200)"
    elif [[ "$HTTP_CODE" == "401" || "$HTTP_CODE" == "403" ]]; then
        fail "JFrog auth failed (HTTP $HTTP_CODE) — token may be expired"
    elif [[ "$HTTP_CODE" == "000" ]]; then
        warn "JFrog server unreachable"
    else
        warn "JFrog returned HTTP $HTTP_CODE"
    fi
else
    warn "No JFrog credentials in ~/.netrc (make remediate-jfrog will not work)"
fi

if [[ -f "$PROJECT_DIR/.env" ]]; then
    if grep -q "BLACKDUCK_API_TOKEN=.\+" "$PROJECT_DIR/.env" 2>/dev/null; then
        pass "Black Duck token found in .env"
    else
        warn "Black Duck token not set in .env (Black Duck scanning unavailable)"
    fi
else
    warn "No .env file (Black Duck scanning unavailable — see .env.example)"
fi

# --- Scanners ---
echo ""
echo "Scanners:"

if command -v pip-audit &>/dev/null; then
    pass "pip-audit installed"
elif [[ -f "$PROJECT_DIR/venv/bin/pip-audit" ]]; then
    pass "pip-audit installed (in venv)"
else
    warn "pip-audit not installed — run: pip install pip-audit"
fi

if command -v grype &>/dev/null; then
    pass "Grype installed ($(grype --version 2>&1 | head -1))"
else
    warn "Grype not installed — run: brew install grype"
fi

# --- Project state ---
echo ""
echo "Project:"

if [[ -d "$PROJECT_DIR/venv" ]]; then
    pass "Virtual environment exists"
else
    warn "No venv — run: make setup"
fi

for req in minimal/requirements.txt chatbot/requirements.txt; do
    if [[ -f "$PROJECT_DIR/$req" ]]; then
        pass "$req exists"
    else
        fail "$req missing"
    fi
done

# --- Lightwell catalog ---
echo ""
echo "Lightwell catalog:"

PKG_COUNT=$(curl -sL --netrc --connect-timeout 5 \
    "https://packages.redhat.com/lightwell/python/remediated/simple/" 2>/dev/null \
    | grep -c '<a href' || echo "0")
if [[ "$PKG_COUNT" -gt 0 ]]; then
    pass "Python Remediated catalog accessible ($PKG_COUNT packages)"
else
    warn "Could not fetch Python Remediated catalog"
fi

# --- Summary ---
echo ""
echo "=============================="
if [[ $FAIL -eq 0 && $WARN -eq 0 ]]; then
    echo "All checks passed. Ready to demo."
elif [[ $FAIL -eq 0 ]]; then
    echo "$PASS passed, $WARN warnings, $FAIL failures"
    echo "Demo will work but some optional features are unavailable."
else
    echo "$PASS passed, $WARN warnings, $FAIL failures"
    echo "Fix the failures above before running the demo."
fi

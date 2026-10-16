# Lightwell Python Demo — Talking Points & Script

**Format:** 5-minute live demo with talking points
**Audience:** CISO, AppSec leads, Nexus/Artifactory admins
**Narrative:** "BlackDuck is the detector. Lightwell is the prevention. Together, the scan comes back cleaner and the audit trail is complete."

---

## Three Perceptions (frame every interaction)

1. **Functional in Under 24 Hours** — this is a repository redirect, not a platform migration
2. **Self-Sufficient** — no additional scanners or policy engines needed
3. **100% Process Compatible** — backported patches preserve API compatibility; plugs into existing CI/CD

---

## Demo Flow

### Setup (before the audience sees anything)

```bash
make setup APP=chatbot    # or APP=minimal for a quick run
```

This creates a Python venv and installs dependencies from standard PyPI — the same way your developers do it today.

### Step 1: Show the App (30 seconds)

```bash
make run
```

> "Here's a typical Python web application — a customer service chatbot. Flask, some utility libraries. Standard stuff your teams are already running. Let's look at what's under the hood."

Open `http://localhost:5001`, type a message, show it works. Close the app (Ctrl+C).

### Step 2: Scan — Find the Problem (60 seconds)

```bash
make scan
```

> "We run a vulnerability scan — pip-audit here, but your team probably uses BlackDuck, Snyk, or Grype. Same story regardless of scanner."

**What to point out:**
- PyPDF2 3.0.1: 1 CVE (infinite loop via crafted PDF)
- sqlparse 0.5.5: 9 CVEs (SQL injection parsing issues)
- "These are the exact versions your developers pinned. They chose them because they work. But they have known vulnerabilities."

**If using BlackDuck:** Run the detect CLI instead. Results go to the BlackDuck server dashboard — show it there for visual impact.

### Step 3: Remediate — Fix Without Code Changes (60 seconds)

```bash
make remediate APP=chatbot
```

> "Now watch what happens. We're pulling the same package versions from Red Hat Lightwell instead of PyPI. Same version numbers, same API compatibility — but with security patches backported by Red Hat engineers."

**What to point out:**
- Each package checked against the Lightwell catalog
- PyPDF2 goes from 3.0.1 to 3.0.1+rhlw.1
- sqlparse goes from 0.5.5 to 0.5.5+rhlw.1
- "The +rhlw suffix means Red Hat applied a security fix to YOUR exact version. No upgrade. No breaking changes. No regression testing."
- Flask shows "not in Lightwell catalog" — honest about coverage

### Step 4: Verify — Prove It Worked (30 seconds)

```bash
make verify APP=chatbot
```

> "Let's confirm. Every package with +rhlw is now running a Lightwell-patched version."

### Step 5: Rescan — Show the Difference (60 seconds)

```bash
make scan
```

> "Same scanner, same project, same code. The only thing that changed is WHERE the packages came from."

**Before:** 10 CVEs across 2 packages
**After:** 0 CVEs in the Lightwell-covered packages

**The embargo gap (key talking point):**
pip-audit shows "Dependency not found on PyPI" for +rhlw versions. This is because during the 14-day embargo period, the vulnerability data hasn't been published to OSV yet. The scanner can't find the package in its database — which means it can't flag it either. When the embargo lifts, the OSV data shows the fix.

> "Your scanner may not recognize the Lightwell version yet — that's by design. During the embargo period, Lightwell holds the patch before contributing upstream. The VEX data proves the fix exists."

### Step 6: Show the Proof Chain (90 seconds)

```bash
make sbom APP=chatbot
```

> "Every Lightwell package ships with a Software Bill of Materials — SPDX 2.3 format. Red Hat is the supplier. You can trace exactly what's in the package."

```bash
make provenance APP=chatbot
```

> "And here's the SLSA Level 3 build provenance. This is cryptographic proof of HOW this package was built — the Tekton pipeline, the source repo, the build timestamp, the signature. This is the audit trail your compliance team needs."

```bash
make vex APP=chatbot
```

> "And the VEX data — this is how Lightwell communicates which specific CVEs were fixed in each patched version. During the embargo period, this is the authoritative record."

### Step 7: Lightwell Lens (mention, show if available)

> "For the visual view, Lightwell Lens in the Red Hat console gives you the SBOM analysis dashboard — which packages are remediated, which CVEs are resolved, the full provenance chain. That's at console.redhat.com/lightwell/lens."

### Reset (for next demo)

```bash
make reset APP=chatbot
```

> "And we snap back to the vulnerable state. Ready to run again."

---

## Alternate Flow: Artifactory Integration

Use this flow when the audience includes Artifactory admins or when you want to show the enterprise deployment pattern. Replaces Steps 3-4 above.

### Step 3 (alt): Show the Artifactory Architecture (60 seconds)

> "Most enterprises don't point pip at package sources directly — they go through an artifact repository manager. Let me show you what that looks like with Artifactory."

Open your JFrog Artifactory UI in the browser. Show:
- `lightwell-python-local` repo containing the Lightwell remediated wheels
- `pypi-remote` repo proxying upstream PyPI
- `lightwell-python` virtual repo aggregating both

> "Three repos. The virtual repo gives developers one URL. Lightwell packages are served when available, PyPI fills in the rest. Developers don't change their workflow — they pip install from the same Artifactory URL they always use."

### Step 4 (alt): Remediate via Artifactory (60 seconds)

```bash
make remediate-jfrog APP=chatbot
```

> "Same remediation, but now the packages come through Artifactory. In production, Artifactory caches these locally — subsequent installs don't hit the internet at all."

**What to point out:**
- Same +rhlw.1 versions appear
- Artifactory caches the packages — faster and air-gap friendly
- "This is the same pattern your team already uses for Maven. Repository redirect, not platform migration."

Then continue with Steps 5-7 (rescan, SBOM, provenance, VEX) — they work the same regardless of how the packages were installed.

### If Asked: "Why not just use the virtual repo for everything?"

> "pip's version resolution picks the latest or cleanest version across all sources. If PyPI has 0.6.0 and Lightwell has 0.5.5+rhlw.1, pip takes 0.6.0. In production, you'd pin your requirements to the specific versions you've tested, and Lightwell patches those exact versions. The virtual repo works perfectly with pinned dependencies."

### If Asked: "Can Artifactory proxy Lightwell directly?"

> "JFrog's PyPI remote proxy has a known compatibility issue with Pulp-based repositories like Lightwell's. The workaround is pre-caching the wheels in a local repo — same result, and it's actually faster since the packages are served from Artifactory's local storage. JFrog is aware of the Pulp compatibility gap."

---

## Key Numbers to Know

- **32,000+ libraries** remediated across Java and Python (growing 34% week-over-week)
- **$5B commitment** from Red Hat + IBM + Palo Alto Networks
- **20,000 Red Hat engineers** vs Chainguard's ~700 employees
- **$925K** Network pricing — flat, all-you-can-eat (going up January 2027)
- **14-day embargo** on novel vulnerabilities before upstream contribution
- **SLSA Level 3** compliance on all packages
- **< 24 hours** to get functional with Lightwell (repository redirect)

## Competitive Counters

- **"We use Chainguard"** — "Chainguard rebuilds packages clean. Lightwell backports patches to YOUR version. Chainguard says 'move to latest.' We say 'stay where you are, we'll fix it in place.'"
- **"BlackDuck already finds everything"** — "Keep using it. We make its scan cleaner. We're not replacing the detector — we're reducing what it has to find."
- **"We'll do this ourselves"** — "You can try, but the value is doing it with a collective set of experts across FSI firms and Red Hat. Do you have crypto experts on staff? We do."
- **"What about npm/Go?"** — "Java and Python today. npm and Go are on the roadmap. The architecture is the same — repository redirect."

## If Asked About the Python Catalog Size

> "The remediated Python catalog is early — it's focused on the most impactful packages first. The validated catalog has thousands of securely rebuilt Python packages already. And the remediated catalog is growing fast — the Java side went from 20K to 32K in ten days. Python is on the same trajectory."

## If Someone Asks About TSSC/ACS

> "Post-sale expansion. Sell Lightwell first on its own merit. TSSC and ACS are the follow-on conversations once the customer is consuming from a trusted source."

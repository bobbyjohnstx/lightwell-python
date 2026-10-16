# Lightwell Python Demo

Customer-facing demo showing how Red Hat Lightwell Network patches vulnerable Python dependencies with zero application code changes. Install from PyPI, scan for CVEs, switch to Lightwell, rescan clean.

## Prerequisites

- Python 3.12+
- `~/.netrc` with Lightwell service account credentials:
  ```
  machine packages.redhat.com login <service-account-username> password <service-account-token>
  ```
  Create a service account at [Red Hat Registry Service Account Management](https://access.redhat.com/terms-based-registry/).
- A vulnerability scanner (at least one):
  - `pip-audit` — `pip install pip-audit` (free, recommended for demos)
  - `grype` — `brew install grype`
  - Black Duck — set `BLACKDUCK_API_TOKEN` in `.env` (see `.env.example`)

## Quick Start

```bash
make setup                 # Create venv, install vulnerable deps from PyPI
make scan                  # Find CVEs (10 vulnerabilities)
make remediate             # Patch via Lightwell (zero code changes)
make scan                  # Rescan — CVEs resolved
make verify                # Confirm +rhlw version suffixes
make reset                 # Snap back to vulnerable state for next demo
```

## Pre-Demo Check

Run `make doctor` before any demo to verify your environment:

```
=== Lightwell Python Demo — Environment Check ===

Runtime:
  ✓  Python 3.14.7 (3.12+ required)
  ✓  pip available

Credentials:
  ✓  ~/.netrc exists (permissions 600)
  ✓  Lightwell credentials found in ~/.netrc
  ✓  Lightwell auth verified (HTTP 200)
  ✓  JFrog credentials found in ~/.netrc
  ✓  JFrog auth verified (HTTP 200)

Scanners:
  ✓  pip-audit installed
  ✓  Grype installed

Project:
  ✓  Virtual environment exists
  ✓  minimal/requirements.txt exists
  ✓  chatbot/requirements.txt exists

Lightwell catalog:
  ✓  Python Remediated catalog accessible (2 packages)
```

Checks performed:
- **Runtime** — Python 3.12+ and pip are available
- **Credentials** — `~/.netrc` exists with correct permissions (600), contains entries for `packages.redhat.com` and JFrog. Tests actual authentication against both APIs — catches expired or revoked tokens before you're in front of a customer.
- **Scanners** — at least one of pip-audit, Grype, or Black Duck (`.env` token) is available
- **Project** — venv and requirements files exist
- **Catalog** — live connectivity to the Lightwell Remediated repository, with package count

Items are flagged as pass (✓), warning (⚠ optional feature unavailable), or failure (✗ demo will not work).

## Demo Apps

**Minimal** (`minimal/`) — 10-line script using PyPDF2 and sqlparse. For quick testing.

**Chatbot** (`chatbot/`) — Flask web app with a mocked customer service chatbot UI. Professional look for customer demos. Runs on port 5001.

```bash
make setup APP=minimal     # Use minimal app
make setup APP=chatbot     # Use chatbot app (default)
make run                   # Launch chatbot at http://localhost:5001
```

## All Targets

```bash
make help                  # Show all available targets
make setup                 # Create venv, install vulnerable deps from PyPI
make scan                  # Vulnerability scan (pip-audit / Grype / Black Duck)
make remediate             # Patch via Lightwell direct
make remediate-jfrog       # Patch via JFrog Artifactory proxy
make verify                # Show installed versions, confirm +rhlw suffixes
make reset                 # Reset to unpatched state
make run                   # Start Flask chatbot (port 5001)
make run-minimal           # Run minimal script
make sbom                  # Extract SPDX 2.3 SBOM from remediated packages
make provenance            # Fetch SLSA L3 build provenance attestation
make vex                   # Show VEX/OSV vulnerability remediation data
make lens                  # Open Lightwell Lens dashboard in browser
make test                  # Run unit tests
make test-integration      # Run full demo cycle against live Lightwell API
```

## How It Works

1. **Setup** installs pinned vulnerable versions (PyPDF2 3.0.1, sqlparse 0.5.5) from standard PyPI.
2. **Scan** finds known CVEs in those versions using whichever scanner is available.
3. **Remediate** installs the same base versions from the Lightwell Remediated repository. Lightwell applies backported security patches without changing the API — versions show a `+rhlw.N` suffix (e.g., `3.0.1+rhlw.1`).
4. **Rescan** shows the CVEs are resolved.
5. **Verify** confirms the `+rhlw` version suffixes on installed packages.
6. **Reset** destroys the venv and reinstalls unpatched versions — ready for the next demo.

No application code changes at any step. The only difference is where pip pulls packages from.

## Proof Chain

After remediation, three additional commands show the audit trail:

- **SBOM** — SPDX 2.3 Software Bill of Materials embedded in each remediated wheel, with Red Hat as supplier
- **Provenance** — SLSA Level 3 build attestation from Lightwell's Tekton pipeline, cryptographically signed
- **VEX** — OSV vulnerability data proving which specific CVEs are fixed in each `+rhlw` version

## JFrog Artifactory Integration

`make remediate-jfrog` patches through a JFrog Artifactory instance instead of connecting to Lightwell directly. This shows the enterprise deployment pattern where Artifactory proxies and caches Lightwell packages.

Requires JFrog credentials in `~/.netrc`:
```
machine <instance>.jfrog.io login <email> password <identity-token>
```

## Credentials

All credentials live outside the repository:

| Credential | Location | Purpose |
|---|---|---|
| Lightwell service account | `~/.netrc` | Authenticate to `packages.redhat.com` |
| JFrog identity token | `~/.netrc` | Authenticate to JFrog Artifactory (optional) |
| Black Duck API token | `.env` (gitignored) | Authenticate to Black Duck scanner (optional) |

Copy `.env.example` to `.env` and fill in values as needed. Never commit `.env` or `~/.netrc`.

## Lightwell Python Catalog

The Lightwell Python Remediated catalog currently contains a small number of packages (growing rapidly). The Validated catalog contains ~2,000 securely rebuilt packages. This demo uses packages confirmed in the Remediated catalog.

## Companion Project

[lightwell-java](https://github.com/bobbyjohnstx/lightwell-java) — same demo flow for Java/Maven with a much larger remediated catalog (261 artifact-version pairs, 522 CVE records).

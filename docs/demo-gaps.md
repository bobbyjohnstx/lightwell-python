# Lightwell Python Demo — Known Gaps

Items that would strengthen the demo but are not yet implemented. Organized by audience impact.

## High Impact

### CI/CD Integration Example
Every platform engineer asks "how does this go in my pipeline?" No GitHub Actions/GitLab CI/Jenkins example exists. A `.github/workflows/lightwell-scan.yml` showing setup → remediate → scan → verify would answer the question before it's asked.

### ROI / Time-Savings Framing
CISOs buy on cost and risk, not technology. The demo shows *what* Lightwell does but not *why it matters financially*. Missing: time-to-patch comparison (manual upgrade vs. Lightwell), developer hours saved per CVE remediation cycle, risk quantification for delayed patching.

### Competitive Positioning in Dashboard
`docs/demo-script.md` has competitive counters (Chainguard, BlackDuck) but the dashboard has no visual comparison. A slide or panel showing Lightwell vs. manual upgrade vs. Chainguard would make the differentiation concrete.

## Medium Impact

### Transitive Dependency Story
The demo only remediates direct dependencies (PyPDF2, sqlparse). Flask and its transitive deps are skipped. The audience will ask: "Does Lightwell patch transitive deps too?" If yes, show it. If no, explain the roadmap.

### Rollback Story
`make reset` restores the demo, but there's no production rollback narrative. What happens if a `+rhlw` patch causes a regression? Talking points needed: version pinning, Artifactory caching, pip constraints files.

### Offline / Air-Gapped Demo Mode
Conference and FSI demos often lack reliable internet. The scan, remediate, and VEX steps all require network access. A `make demo-offline` mode that uses pre-cached data would eliminate this risk. Fonts are now bundled locally (no Google CDN dependency).

### End-to-End Dry Run Validation
No mechanism to validate the full demo path matches dashboard expectations before the audience sees it. A `make demo-check` that runs setup → scan → remediate → scan → vex and compares output to expected values would catch drift.

### Pulp/Artifactory Workaround Documentation
The JFrog integration has a known Pulp URL rewriting issue mentioned in the Java sibling project. The workaround should be documented in the README or demo script for when prospects ask about Artifactory integration.

## Lower Impact

### Scale Narrative
"32,000+ Libraries" (dashboard Step 8) has no citation or demo proof. No story about how Lightwell works across a large Python monorepo. The number will go stale as the catalog grows.

### Regression Guarantee Clarification
Dashboard Step 3 says "No regression testing." Is this a contractual guarantee or a design goal? A skeptical CISO will press this point. The demo script should have a prepared answer.

### Multi-Language Story
The sibling `lightwell-java` project exists but the dashboard doesn't mention it. Showing Python + Java side-by-side in the architecture step would reinforce "this works across your stack."

### Wheel Filename in Provenance Script
`scripts/provenance.sh` constructs the wheel filename with a build number (`-1-py3-none-any.whl`) that may not match actual Lightwell wheel names. This could cause 404s during live demos. Verify and fix the construction pattern.

---

*Last updated: 2026-11-02. Review before each demo cycle — gaps may have been addressed.*

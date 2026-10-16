.PHONY: doctor setup scan remediate remediate-jfrog verify reset run run-minimal provenance sbom vex lens test test-integration help

APP ?= chatbot

doctor: ## Check environment, credentials, and connectivity
	@bash scripts/doctor.sh

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

setup: ## Create venv and install vulnerable deps from PyPI
	@bash scripts/setup.sh $(APP)

scan: ## Run vulnerability scanner (Black Duck / pip-audit / Grype)
	@bash scripts/scan.sh

remediate: ## Switch to Lightwell Remediated repo and reinstall deps
	@bash scripts/remediate.sh $(APP)

remediate-jfrog: ## Remediate via JFrog Artifactory (proxies Lightwell)
	@bash scripts/remediate-artifactory.sh $(APP)

verify: ## Show installed versions and confirm +rhlw patched suffixes
	@bash scripts/verify.sh $(APP)

reset: ## Reset demo to unpatched state (destroys and recreates venv)
	@bash scripts/reset.sh $(APP)

provenance: ## Verify SLSA L3 build provenance for remediated packages
	@bash scripts/provenance.sh $(APP)

sbom: ## Extract and display SBOM from remediated packages
	@bash scripts/sbom.sh $(APP)

vex: ## Show VEX/OSV vulnerability data for remediated packages
	@bash scripts/vex.sh $(APP)

lens: ## Open Lightwell Lens in browser (SBOM analysis dashboard)
	@echo "Opening Lightwell Lens..."
	@open "https://console.redhat.com/lightwell/lens" 2>/dev/null || \
		xdg-open "https://console.redhat.com/lightwell/lens" 2>/dev/null || \
		echo "Visit: https://console.redhat.com/lightwell/lens"

test: ## Run unit tests
	@source venv/bin/activate && python -m pytest tests/ -v

test-integration: ## Run full demo cycle against live Lightwell API
	@bash tests/test_integration.sh

run: ## Run the Flask chatbot app
	@source venv/bin/activate && python chatbot/app.py

run-minimal: ## Run the minimal crypto script
	@source venv/bin/activate && python minimal/app.py

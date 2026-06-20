#!/usr/bin/env bash
# Makefile for bootstreep-homelab
# Replaces complex shell pipelines with simple commands.

.PHONY: help install test lint clean validate deploy backup logs report \
        shellcheck yamllint bats hadolint secrets update format

# Defaults
SHELL := /usr/bin/env bash
COMPOSE_DIR := bootstrap/compose

help:  ## Show this help message
	@echo "Bootstreep Homelab - Available commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""

install:  ## Run full bootstrap on target system (requires root)
	@echo "🚀 Running bootstreep bootstrap..."
	@sudo ./bootstrap/bootstrap.sh

test: bats  ## Run all tests

lint: shellcheck yamllint  ## Run all linters

shellcheck:  ## Run shellcheck on all bash scripts
	@echo "🔍 Running shellcheck..."
	@if which shellcheck >/dev/null 2>&1; then \
		shellcheck bootstrap/bootstrap.sh bootstrap/scripts/*.sh; \
	else \
		echo "❌ shellcheck not installed. Install with: apt install shellcheck"; \
		exit 1; \
	fi

yamllint:  ## Run yamllint on compose files
	@echo "🔍 Running yamllint..."
	@if which yamllint >/dev/null 2>&1; then \
		yamllint -c .yamllint.yaml $(COMPOSE_DIR)/; \
	else \
		echo "❌ yamllint not installed. Install with: pip install yamllint"; \
		exit 1; \
	fi

hadolint:  ## Run hadolint on Dockerfiles
	@echo "🔍 Running hadolint..."
	@if which hadolint >/dev/null 2>&1; then \
		find . -name "Dockerfile*" -exec hadolint {} +; \
	else \
		echo "❌ hadolint not installed."; \
	fi

bats:  ## Run BATS tests
	@echo "🧪 Running BATS tests..."
	@if which bats >/dev/null 2>&1; then \
		bats tests/; \
	else \
		echo "❌ bats not installed. Install with: apt install bats"; \
		exit 1; \
	fi

secrets:  ## Scan for hardcoded secrets
	@echo "🔒 Scanning for hardcoded secrets..."
	@grep -rn --include="*.sh" --include="*.yml" --include="*.env" \
			-E "(api_key|secret|password|token)\s*=\s*['\"][^'\"]{6,}['\"]" \
			bootstrap/ scripts/ 2>/dev/null || echo "✅ No hardcoded secrets found"

validate: lint secrets  ## Run full validation (lint + secrets)

deploy:  ## Deploy all docker compose stacks
	@echo "🐳 Deploying all Docker Compose stacks..."
	@for dir in $(COMPOSE_DIR)/*/; do \
		echo "  → $$dir"; \
		(cd $$dir && docker compose up -d) || echo "  ⚠️ Failed: $$dir"; \
	done

backup:  ## Run backup script
	@echo "💾 Running backup..."
	@sudo /opt/docker/scripts/backup-all.sh

logs:  ## Tail logs from all services
	@docker compose -f bootstrap/compose/*/docker-compose.yml logs -f --tail=50 2>/dev/null || \
		echo "No services running"

report:  ## Generate system report
	@echo "📊 Generating system report..."
	@sudo bash bootstrap/scripts/11-finish.sh

update:  ## Update all Docker images
	@echo "🔄 Updating Docker images..."
	@for dir in $(COMPOSE_DIR)/*/; do \
		(cd $$dir && docker compose pull); \
	done
	@echo "📦 Watchtower will handle automatic updates at 04:00 daily"

clean:  ## Clean up Docker resources
	@echo "🧹 Cleaning Docker resources..."
	@docker system prune -af --volumes
	@echo "✅ Cleanup complete"

format:  ## Format bash scripts with shfmt
	@echo "✨ Formatting bash scripts..."
	@if which shfmt >/dev/null 2>&1; then \
		shfmt -i 4 -ci -w bootstrap/scripts/*.sh bootstrap/bootstrap.sh; \
	else \
		echo "❌ shfmt not installed."; \
	fi

# Advanced
all: lint test validate  ## Run everything
ci: lint bats secrets   ## CI pipeline (what GitHub Actions runs)
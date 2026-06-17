# Contributing to Bootstreep Homelab

## Reporting Issues

- Check existing issues first
- Include Ubuntu version, Docker version, relevant logs
- Use issue templates

## Pull Requests

1. Fork & create branch: `git checkout -b feature/xyz`
2. Run linters locally:
   ```bash
   shellcheck bootstrap.sh scripts/*.sh
   yamllint compose/*.yml
   ruff check ai-agent/
   ```
3. Commit: `git commit -m "feat: add XYZ"`
4. Push & open PR

## Code Style

- **Shell**: `set -euo pipefail`, ShellCheck-clean, lib.sh helpers
- **YAML**: 2-space indent, no tabs, 200 char line max
- **Python**: PEP 8, ruff-formatted
- **Docker Compose**: named volumes, no-new-privileges, healthchecks, pinned versions

## Security

Report vulnerabilities via Security Advisory, not public issues.

# Contributing to Bootstreep Homelab

Thank you for considering contributing! Here is how you can help:

## Reporting Issues

- Check existing issues before creating a new one
- Use the issue templates (bug report / feature request)
- Include your Ubuntu version, Docker version, and relevant logs

## Pull Requests

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes
4. Run ShellCheck on any modified scripts: `shellcheck bootstrap.sh scripts/*.sh`
5. Run yamllint on any modified YAML files: `yamllint compose/*.yml`
6. Commit with clear messages: `git commit -m "feat: add XYZ"`
7. Push and open a PR against `main`

## Code Style

- Shell scripts: Use `set -euo pipefail`, follow existing patterns
- YAML: 2-space indentation, no tabs
- Docker Compose: Use named volumes, security_opt, healthchecks
- Python: Follow PEP 8, use async/await for I/O

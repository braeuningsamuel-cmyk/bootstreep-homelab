# Contributing to Bootstreep Homelab

## Reporting Issues

- Check existing issues first
- Include Ubuntu version, Docker version, relevant logs
- Use issue templates (`.github/ISSUE_TEMPLATE/`)

## Development Setup

```bash
git clone https://github.com/braeuningsamuel-cmyk/bootstreep-homelab.git
cd bootstreep-homelab
pre-commit install  # auto-lint before each commit
```

## Pull Requests

1. Fork & create branch: `git checkout -b feature/xyz`
2. Make changes, then run linters locally:
   ```bash
   # Shell
   shellcheck --severity=warning bootstrap.sh scripts/*.sh
   # YAML
   yamllint -c .yamllint.yaml compose/ docker-compose-all.yml .github/
   # Python
   pip install ruff && ruff check ai-agent/ && ruff format --check ai-agent/
   # Markdown
   npx markdownlint-cli2 '**/*.md'
   # Secrets
   gitleaks detect --source . -v
   ```
3. Commit with conventional message: `git commit -m "feat: add XYZ"`
4. Push & open PR against `main`

## Code Style

| Language | Standard | Tools |
|----------|----------|-------|
| Shell | `set -euo pipefail`, POSIX-ish | ShellCheck (severity: warning) |
| YAML | 2-space indent, no tabs, 200 char max | yamllint |
| Python | PEP 8 | ruff + ruff format |
| Markdown | Default rules, MD013/033/041 disabled | markdownlint-cli2 |
| Docker Compose | v3.8+, named volumes, healthchecks, pinned tags | yamllint + custom CI |

### Shell Guidelines
- Always `set -euo pipefail` (except short inline scripts)
- Use `scripts/lib.sh` helpers: `log()`, `warn()`, `err()`, `die()`
- Prefer `$HOME` over `/home/$USER`
- Quote all variable expansions: `"$var"` not `$var`
- Use `[[ ... ]]` over `[ ... ]` for bash tests

### Compose Guidelines
- Every service needs: healthcheck, resource limits, pinned image tag, logging config
- No `ports` on `0.0.0.0` – always bind to `127.0.0.1` for internal services
- No `:latest` tags (exceptions: unbound, valheim)
- Every new service needs an entry in `docker-compose-all.yml`

## Security

Report vulnerabilities via [Security Advisory](https://github.com/braeuningsamuel-cmyk/bootstreep-homelab/security/advisories), not public issues.

## CI Pipeline

The CI runs automatically on push/PR to `main`:

| Job | What it checks |
|-----|----------------|
| ShellCheck | All shell scripts (`--severity=warning`) |
| yamllint | All YAML files |
| ruff | Python code style |
| markdownlint | Markdown formatting |
| gitleaks | Hardcoded secrets |
| Compose Validate | Schema + required fields |
| Pinned Tags | No `:latest` (except whitelist) |
| Env Consistency | All `${VAR}` refs have defaults

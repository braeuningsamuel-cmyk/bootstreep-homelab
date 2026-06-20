# Testing Guide

> How to test Bootstreep Homelab locally and in CI.

## 🧪 Test Layers

| Layer | Tool | What it tests |
|-------|------|---------------|
| Bash scripts | BATS | Script logic, file existence, structure |
| Bash quality | ShellCheck | Shell scripting best practices |
| YAML quality | yamllint | Compose file syntax, structure |
| Secrets | grep + gitleaks | No hardcoded credentials |
| Integration | docker compose config | Compose files are valid |
| End-to-end | Manual smoke test | Full bootstrap on real VM |

---

## 🚀 Quick Start

### Install test tools (Ubuntu 24.04)

```bash
sudo apt update
sudo apt install -y shellcheck bats
pip install yamllint
```

### Run all tests

```bash
make test       # BATS only
make lint       # shellcheck + yamllint
make validate   # lint + secrets
make all        # everything
```

### Run individual test suites

```bash
make shellcheck
make yamllint
make bats
make secrets
```

---

## 📋 BATS Tests

### Run BATS

```bash
bats tests/bootstrap.bats
```

### Test coverage

The `tests/bootstrap.bats` file covers:

- ✅ Script existence and executability
- ✅ Bash shebang correctness
- ✅ Strict mode (`set -Eeuo pipefail`)
- ✅ CLI flags (`--help`, `--version`)
- ✅ Config files exist
- ✅ Compose files exist with required fields
- ✅ Healthchecks present
- ✅ Resource limits present
- ✅ Restart policies present
- ✅ No hardcoded secrets
- ✅ Documentation files exist
- ✅ No TODO/FIXME markers

### Writing new tests

```bash
@test "descriptive test name" {
    # Arrange
    local file="${REPO_ROOT}/path/to/file"

    # Act
    [ -f "$file" ]

    # Assert
    [ -f "$file" ]
}
```

---

## 🔍 ShellCheck

```bash
# All scripts
make shellcheck

# Specific script
shellcheck bootstrap/scripts/05-security.sh
```

### Common fixes

| Issue | Fix |
|-------|-----|
| SC2086 | Quote variables: `"$var"` |
| SC2046 | Quote command substitution: `"$(cmd)"` |
| SC2155 | Separate `local` from assignment |
| SC2068 | Quote array: `"${arr[@]}"` |

---

## 📐 yamllint

```bash
make yamllint
```

Configuration in `.yamllint.yaml`:

```yaml
extends: default
rules:
  line-length:
    max: 120
  document-start:
    present: true
  indentation:
    spaces: 2
    indent-sequences: true
```

---

## 🔐 Secret Scanning

```bash
make secrets
```

Checks for hardcoded secrets in bash/yaml/env files. Should always return clean.

---

## 🐳 Docker Compose Validation

```bash
# Validate all compose files
for f in bootstrap/compose/*/docker-compose.yml; do
    echo "Validating: $f"
    docker compose -f "$f" config --quiet
done
```

---

## 🔄 Integration Test (Real VM)

### On a fresh Ubuntu 24.04 VM:

```bash
# 1. Clone repo
git clone https://github.com/braeuningsamuel-cmyk/bootstreep-homelab.git
cd bootstreep-homelab

# 2. Dry run
sudo ./bootstrap/bootstrap.sh --dry-run

# 3. Full run
sudo ./bootstrap/bootstrap.sh

# 4. Verify
cat system-report.md
docker ps
curl -I https://traefik.${DOMAIN}
```

### Cleanup

```bash
# Remove everything
for f in bootstrap/compose/*/docker-compose.yml; do
    docker compose -f "$f" down -v
done
```

---

## 🤖 CI Pipeline

GitHub Actions runs on every push and PR (`.github/workflows/ci.yml`):

```yaml
jobs:
  shellcheck: ...
  yamllint: ...
  bats: ...
  secrets: ...
```

All must pass before merge.

---

## ✅ Pre-commit Checklist

Before committing changes:

- [ ] `make lint` passes
- [ ] `make bats` passes
- [ ] `make secrets` returns clean
- [ ] No new warnings introduced
- [ ] Documentation updated
- [ ] Commit message follows convention

### Conventional Commits

```
feat: add new service
fix: correct shellcheck warning in 05-security.sh
docs: update ARCHITECTURE.md
test: add bats tests for new feature
refactor: simplify docker-compose template
chore: bump version to 1.1.0
```

---

## 📊 Test Reports

### Local

```bash
make all > test-report.txt 2>&1
tail -50 test-report.txt
```

### CI

GitHub Actions publishes test results at:
`https://github.com/braeuningsamuel-cmyk/bootstreep-homelab/actions`

---

## 🐛 Debugging Failed Tests

### BATS test failed

```bash
# Run with verbose output
bats -t tests/bootstrap.bats

# Run single test
bats --filter "strict mode" tests/bootstrap.bats
```

### ShellCheck failed

```bash
# Show all info, not just warnings
shellcheck -S info bootstrap/scripts/*.sh

# Show explanation
shellcheck -e SC2086 -f explain bootstrap/scripts/*.sh
```

### yamllint failed

```bash
# Show parsed structure
yamllint -f parsable bootstrap/compose/
```

---

## 📚 References

- [BATS documentation](https://bats-core.readthedocs.io/)
- [ShellCheck wiki](https://github.com/koalaman/shellcheck/wiki)
- [yamllint rules](https://yamllint.readthedocs.io/en/stable/rules.html)
- [Docker Compose specification](https://docs.docker.com/compose/compose-file/)
# Bootstreep Homelab Improvement Plan

## 🎯 Goal

Transform the bootstreep-homelab repository from a basic bootstrap into a **production-grade, enterprise-class homelab framework** with:
- Zero critical security issues
- Shellcheck-clean Bash scripts
- yamllint-clean Docker Compose files
- BATS tests for bash scripts
- Continuous integration with full validation
- Comprehensive documentation

---

## 📊 Current State Analysis

### Repository Structure
- **Location**: `C:/Users/Samuel/bootstreep-homelab`
- **GitHub**: https://github.com/braeuningsamuel-cmyk/bootstreep-homelab
- **163 files**, 2 commits on `main`
- **Languages**: Shell, YAML, Markdown, Python

### Known Issues to Investigate
1. Bash scripts in `bootstrap/scripts/` may have shellcheck warnings
2. Docker Compose files may have yamllint issues
3. Missing BATS tests
4. Some services may not have healthchecks
5. Missing `.env.example` files for compose stacks
6. No automated testing in CI

---

## 📋 Implementation Plan

### Phase 1: Static Analysis & Bug Discovery

#### Task 1.1: Run shellcheck on all bash scripts
- **Files**: `bootstrap/scripts/*.sh`, `bootstrap/bootstrap.sh`
- **Command**: `shellcheck bootstrap/**/*.sh`
- **Expected**: Identify quoting issues, unused variables, missing error handling
- **Fix**: Patch each script with `set -Eeuo pipefail`, proper quoting

#### Task 1.2: Run yamllint on docker-compose files
- **Files**: `bootstrap/compose/*/docker-compose.yml`
- **Command**: `yamllint bootstrap/compose/`
- **Expected**: Document start, line length, indentation issues
- **Fix**: Add `---` document markers, fix indentation

#### Task 1.3: Security audit
- **Files**: All bash scripts
- **Command**: grep for hardcoded secrets, unsafe `eval`, missing `set -e`
- **Expected**: No hardcoded credentials, all scripts strict-mode
- **Fix**: Move secrets to env files, add strict mode

### Phase 2: Bug Fixes & Improvements

#### Task 2.1: Fix bash script issues
- Add `set -Eeuo pipefail` where missing
- Quote all variable expansions
- Replace `echo` with `printf` where appropriate
- Use `[[ ]]` instead of `[ ]`

#### Task 2.2: Fix docker-compose issues
- Add `---` YAML document start
- Fix line length (max 120 chars)
- Add healthchecks to all services
- Add resource limits (mem/cpu)

#### Task 2.3: Add missing .env.example files
- Create `bootstrap/compose/<service>/.env.example` for each stack
- Document all required variables

### Phase 3: Add Tests

#### Task 3.1: Create BATS tests
- **File**: `tests/bootstrap/test_helpers.bats`
- **Tests**: Helper functions (logging, validation)
- **Command**: `bats tests/`

#### Task 3.2: Add shell-script integration tests
- **File**: `tests/integration/test_dry_run.sh`
- **Test**: Bootstrap with `--dry-run` produces expected output

### Phase 4: Documentation Improvements

#### Task 4.1: Add ARCHITECTURE.md
- Complete system architecture diagram
- Service dependencies
- Network topology

#### Task 4.2: Add TESTING.md
- How to run tests
- How to contribute

#### Task 4.3: Improve README
- Add screenshots/diagrams
- Add "Why Bootstreep?" section

### Phase 5: CI Enhancements

#### Task 5.1: Add BATS to CI
- **File**: `.github/workflows/ci.yml`
- **Job**: Run BATS tests on every PR

#### Task 5.2: Add Dockerfile linting
- **Job**: Run `hadolint` on any Dockerfile

#### Task 5.3: Add security scanning
- **Job**: Run `trivy` or `gitleaks` for secret detection

### Phase 6: New Features

#### Task 6.1: Add Healthchecks to services
- Add `healthcheck:` blocks to each docker-compose service

#### Task 6.2: Add Makefile
- **File**: `Makefile`
- **Targets**: `install`, `test`, `lint`, `clean`, `deploy`

#### Task 6.3: Add rollback script
- **File**: `bootstrap/scripts/rollback.sh`
- **Purpose**: Restore from backup if bootstrap fails

---

## 🧪 Verification Steps

### After each task:
1. `shellcheck bootstrap/**/*.sh` — must be clean
2. `yamllint bootstrap/compose/` — must be clean
3. `bats tests/` — must pass
4. `git status` — verify only expected changes

### Final verification:
- Repository can be cloned and bootstrap runs with `--dry-run`
- All CI checks pass
- Documentation is complete and accurate

---

## 📁 Files to Create/Modify

### New files:
- `Makefile`
- `tests/bootstrap/helpers.bats`
- `tests/integration/test_dry_run.sh`
- `docs/ARCHITECTURE.md`
- `docs/TESTING.md`
- `bootstrap/compose/*/.env.example` (11 files)
- `bootstrap/scripts/rollback.sh`
- `.github/workflows/security.yml`

### Modified files:
- `bootstrap/scripts/*.sh` (fix shellcheck issues)
- `bootstrap/compose/*/docker-compose.yml` (add healthchecks, fix yaml)
- `.github/workflows/ci.yml` (add bats)
- `README.md` (add new sections)

---

## ⏱️ Estimated Effort

| Phase | Tasks | Time |
|-------|-------|------|
| 1. Static Analysis | 3 tasks | 30 min |
| 2. Bug Fixes | 3 tasks | 60 min |
| 3. Tests | 2 tasks | 45 min |
| 4. Documentation | 3 tasks | 30 min |
| 5. CI | 3 tasks | 20 min |
| 6. Features | 3 tasks | 45 min |
| **Total** | **17 tasks** | **~4 hours** |

---

## 🎯 Success Criteria

- [ ] `shellcheck` returns 0 errors across all scripts
- [ ] `yamllint` returns 0 errors across all compose files
- [ ] `bats tests/` passes 100%
- [ ] CI workflow is green
- [ ] Repository can be cloned and bootstrap runs in `--dry-run` mode
- [ ] All services have healthchecks
- [ ] All compose stacks have `.env.example` files
- [ ] Documentation is complete (INSTALL, CONFIGURATION, SERVICES, SECURITY, TROUBLESHOOTING, ARCHITECTURE, TESTING)
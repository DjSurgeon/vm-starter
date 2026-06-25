# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-06-25

### Added
- **CI/CD Pipeline:** Fully automated GitHub Actions workflow enforcing testing and SAST.
- **Advanced Testing Suite:** 15 robust integration tests via Bats-core, featuring system-level binary mocking and interactive simulation.
- **Input Sanitization:** Strict regex-based validation for critical hardware configurations (`TEMPLATE_RAM_MB`, `TEMPLATE_CPU`).
- **DevOps Documentation:** "DevOps Ecosystem & Reference Architecture" connecting IaC with container orchestration.
- **Trunk-Based Development:** Formalized branching strategy in `CONTRIBUTING.md`.

### Changed
- **Scalable Dependencies:** Refactored template pre-flight checks to dynamically support both `genisoimage` and `mkisofs`.
- **Dynamic Plugin Loader:** Implemented Dependency Injection in `config/config.sh` to allow fail-fast validation of config modules.
- **TTY Resilience:** Replaced error-prone `clear` fallbacks with POSIX-compliant TTY validations (`[ -t 1 ]`) to stabilize CI execution.

### Security
- **SAST Certified:** Achieved 100% ShellCheck compliance, resolving all warnings and edge cases.
- **Destructive Operation Hardening:** Prevented catastrophic wipes (`rm -rf /`) by strictly validating empty path variables (SC1115 fix).
- **Access Control:** Blocked root execution and directory traversal attempts via `check_not_root` and `validate_project_name`.

## [0.1.0] - 2025-03-14### Added
- Initial release.
- Modular configuration system (`config/*.sh`).
- `make template` to create a base Ubuntu 24.04 VM with Docker and essential tools.
- `make project` to clone the template into project‑specific VMs with two built‑in types: `web` and `inception`.
- Automatic SSH port allocation (range 4222–4299).
- Integration with host SSH config and VS Code Remote SSH.
- GRUB autoinstall parameter injection (so the user doesn't have to type `autoinstall`).
- Coloured Makefile output (fixed `printf` issue).
- Cross‑platform dependency installer (`make deps`).

### Known Issues
- None (so far). Please report any!
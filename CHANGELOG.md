# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-03-14

### Added
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
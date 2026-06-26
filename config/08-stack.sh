#!/bin/bash
# =============================================================================
# DevPod Configuration – 08-stack.sh
# Purpose: Define software stacks for different project modes (dev / inception).
#          This file centralizes all version numbers and container image tags.
# Source order: Should be sourced after 00-init.sh (no direct dependencies).
# =============================================================================

# -----------------------------------------------------------------------------
# STACK: Development (MODE_DEV) – modern web development tools
# -----------------------------------------------------------------------------

# Node.js version (LTS) – used by setup-web.sh to install via nodesource or nvm.
export DEV_NODE_VERSION="20"

# pnpm version – fast, disk‑efficient package manager (major version).
export DEV_PNPM_VERSION="9"

# List of default Docker containers for web development.
# These are references for docker-compose files; the actual images are pulled from registries.
export DEV_CONTAINERS=(
    "postgres:16-alpine"   # PostgreSQL 16 on Alpine (lightweight)
    "redis:7-alpine"       # Redis 7 on Alpine
)

# -----------------------------------------------------------------------------
# STACK: Inception (MODE_INCEPTION) – 42 project specific requirements
# -----------------------------------------------------------------------------

# Base OS versions – must be penultimate stable (no "latest" tags allowed).
export INCEPTION_ALPINE_VERSION="3.18"        # Penultimate stable Alpine (current latest is 3.19)

# Allowed base images – these are the only ones that may be used in Dockerfiles.
export INCEPTION_BASE_IMAGES=(
    "alpine:${INCEPTION_ALPINE_VERSION}"
)

# PHP version for WordPress (with php-fpm). Must match official images.
export INCEPTION_PHP_VERSION="8.2"

# MariaDB version – stable release compatible with WordPress.
export INCEPTION_MARIADB_VERSION="10.11"

# NGINX version – must support TLSv1.2/1.3 only (as required by subject).
export INCEPTION_NGINX_VERSION="1.24"

# -----------------------------------------------------------------------------
# STACK: C-Pure (MODE_CPURE) – 42 Cursus (Piscine & Common Core)
# -----------------------------------------------------------------------------
export CPURE_PACKAGES="build-essential gcc clang gdb lldb valgrind git python3-setuptools pipx vim"

# -----------------------------------------------------------------------------
# STACK: C++98 (MODE_CPP98) – 42 Cursus (C++ Modules)
# -----------------------------------------------------------------------------
export CPP98_PACKAGES="build-essential g++ clang clang-format gdb valgrind git vim"

# -----------------------------------------------------------------------------
# COMMON TOOLS – installed in the VM regardless of mode
# -----------------------------------------------------------------------------
export COMMON_TOOLS=(
    "docker-compose"       # Orchestration (v2 plugin is already installed, but keep for compatibility)
    "make"                 # Build tool for the project Makefile
    "openssl"              # Generate TLS certificates for development
)

# -----------------------------------------------------------------------------
# USAGE NOTES
#   - Variables prefixed with DEV_ are used by the web‑type setup scripts.
#   - Variables prefixed with INCEPTION_ are used by the inception‑type setup.
#   - COMMON_TOOLS are installed in the base template (via cloud‑init) so they
#     are available in every clone.
#   - The arrays (DEV_CONTAINERS, INCEPTION_BASE_IMAGES, COMMON_TOOLS) are
#     defined for reference; they are not automatically exported but can be
#     used directly in scripts that source this file.
#   - When adding a new mode, create corresponding variables here and in
#     04-clones.sh for resources.
# -----------------------------------------------------------------------------
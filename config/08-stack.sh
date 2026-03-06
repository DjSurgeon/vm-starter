#!/bin/bash
# =============================================================================
# DevPod Configuration – 08-stack.sh
# Purpose: Define versions and container images for the web development stack.
# =============================================================================

# -----------------------------------------------------------------------------
# Node.js version (installed via nodesource repository or nvm)
# -----------------------------------------------------------------------------
export NODE_VERSION="20"				# Node.js 20 LTS (Iron) – current long‑term support version

# -----------------------------------------------------------------------------
# pnpm version – fast, disk‑efficient package manager
# -----------------------------------------------------------------------------
export PNPM_VERSION="9"					# Major version of pnpm (latest stable as of 2025)

# -----------------------------------------------------------------------------
# Default Docker container images for common services
# These are used when generating docker-compose files or during project setup.
# -----------------------------------------------------------------------------
export CONTAINER_POSTGRES="postgres:16-alpine"	# PostgreSQL 16 on Alpine Linux (lightweight)
export CONTAINER_REDIS="redis:7-alpine"			# Redis 7 on Alpine
export CONTAINER_NGINX="nginx:alpine"			# Latest stable Nginx on Alpine (reverse proxy / static server)

# -----------------------------------------------------------------------------
# USAGE NOTES
#   - NODE_VERSION is used by setup-web.sh to install the desired Node release
#     (either via nodesource or nvm).
#   - PNPM_VERSION is used to install the specific pnpm version globally.
#   - Container variables are referenced when creating docker-compose.yml
#     for a new web project (e.g., in clone.sh or setup-web.sh).
#   - Alpine‑based images are preferred to minimise disk usage and attack surface.
# -----------------------------------------------------------------------------
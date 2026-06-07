#!/bin/bash
# =============================================================================
# DevPod Configuration – 13-inception.sh
# Purpose: Project‑specific settings for the 42 Inception project.
#          Defines directory structure, service names, ports, volumes, and
#          other constants required to bootstrap an Inception‑type VM.
# Source order: Must be sourced after 02-users.sh (uses ADMIN_USER) and
#               04-clones.sh (may use INCEPTION_* resources). Typically placed
#               after 08-stack.sh.
# =============================================================================

# -----------------------------------------------------------------------------
# DIRECTORY STRUCTURE (inside the project repo folder ~/inception/)
# These are the paths required by the Inception subject v5.3.
# -----------------------------------------------------------------------------
export INCEPTION_SRCS_DIR="srcs"                    # Root of the project sources
export INCEPTION_SECRETS_DIR="secrets"              # Must be at repo root, same level as srcs/
export INCEPTION_REQUIREMENTS_DIR="srcs/requirements" # Contains each service's subdirectory

# -----------------------------------------------------------------------------
# CORE SERVICES – mandatory for the project
# Each service runs in its own container and has its own Dockerfile.
# -----------------------------------------------------------------------------
export INCEPTION_SERVICES=(
    "nginx"      # Reverse proxy with TLSv1.2/1.3 only
    "wordpress"  # WordPress + php‑fpm (no nginx inside)
    "mariadb"    # MariaDB database
)

# -----------------------------------------------------------------------------
# BONUS SERVICES – optional extra containers (evaluated only if mandatory is perfect)
# -----------------------------------------------------------------------------
export INCEPTION_BONUS_SERVICES=(
    "redis"      # Redis cache for WordPress
    "ftp"        # FTP server pointing to WordPress volume
    "adminer"    # Database management web interface
    "static"     # Simple static website (not PHP)
)

# -----------------------------------------------------------------------------
# NETWORK AND PORTS
# The subject requires that only port 443 be exposed to the host.
# The host port 8443 is a development convenience (maps to VM's port 443).
# -----------------------------------------------------------------------------
export INCEPTION_NGINX_PORT="443"               # Internal port where nginx listens (HTTPS)
export INCEPTION_NGINX_PORT_HOST="443"         # Host port forwarded to VM's port 443

# -----------------------------------------------------------------------------
# TLS CONFIGURATION
# -----------------------------------------------------------------------------
export INCEPTION_TLS_VERSION="1.3"               # Allowed: "1.2" or "1.3"
export INCEPTION_CERT_DAYS="365"                  # Validity of self‑signed certificate (days)

# -----------------------------------------------------------------------------
# DATABASE DEFAULTS
# Used when generating .env file or seeding the database.
# Note: The subject forbids usernames containing "admin" or "Administrator".
# -----------------------------------------------------------------------------
export INCEPTION_DB_NAME="wordpress"              # Database name for WordPress
export INCEPTION_DB_USER="wpuser"                 # Regular DB user (no "admin" in name)
export INCEPTION_DB_ADMIN="wpadmin"               # Admin user for WordPress (must not contain "admin")

# -----------------------------------------------------------------------------
# DOCKER VOLUME NAMES (will be created under INCEPTION_DATA_DIR)
# -----------------------------------------------------------------------------
export INCEPTION_VOLUME_DB="mariadb"               # Volume name for database files
export INCEPTION_VOLUME_WP="wordpress"             # Volume name for WordPress files

# -----------------------------------------------------------------------------
# DOCKER NETWORK NAME
# All containers must communicate through this user‑defined network.
# -----------------------------------------------------------------------------
export INCEPTION_NETWORK_NAME="inception"

# -----------------------------------------------------------------------------
# DOMAIN NAME
# Must be of the form login.42.fr and point to localhost (127.0.0.1).
# ADMIN_USER is imported from 02-users.sh.
# -----------------------------------------------------------------------------
export INCEPTION_DOMAIN="${ADMIN_USER}.42.fr"

# -----------------------------------------------------------------------------
# REQUIRED FILES (for repository validation)
# The project will be considered incomplete if any of these are missing.
# -----------------------------------------------------------------------------
export INCEPTION_REQUIRED_FILES=(
    "Makefile"
    "srcs/docker-compose.yml"
    "srcs/.env"
    "srcs/requirements/nginx/Dockerfile"
    "srcs/requirements/wordpress/Dockerfile"
    "srcs/requirements/mariadb/Dockerfile"
)

# -----------------------------------------------------------------------------
# DOCUMENTATION FILES (additional requirements from subject)
# These must be present at the root of the repository.
# -----------------------------------------------------------------------------
export INCEPTION_DOC_FILES=(
    "README.md"
    "USER_DOC.md"
    "DEV_DOC.md"
)

# -----------------------------------------------------------------------------
# USAGE NOTES
#   - This configuration is consumed by the inception‑type project setup script
#     (e.g., projects/types/inception.sh) to generate the initial directory
#     structure, docker‑compose.yml, and .env file.
#   - The arrays INCEPTION_SERVICES and INCEPTION_BONUS_SERVICES are used to
#     create subdirectories and maybe placeholder Dockerfiles.
#   - INCEPTION_DOMAIN relies on ADMIN_USER; ensure 02-users.sh is sourced first.
#   - Host port 8443 is a development convenience; in a real deployment only
#     443 would be used, but for local testing with NAT forwarding we map it
#     to a non‑privileged host port to avoid requiring root.
# -----------------------------------------------------------------------------
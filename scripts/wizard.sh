#!/bin/bash
# =============================================================================
# scripts/wizard.sh – DevPod Interactive Wizard
# Purpose: Guide the user through VM creation with a Vite-like CLI experience.
# =============================================================================

set -e

# Get project root and source config
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "${PROJECT_ROOT}/config/config.sh"

# -----------------------------------------------------------------------------
# 1. Welcome Message
# -----------------------------------------------------------------------------
# Only clear the screen if running in a true interactive terminal
if [ -t 1 ]; then
    clear
fi
printf "%b\n" "${C_CYAN}${C_BOLD}🚀 VM-Starter Interactive Wizard${C_RESET}"
printf "%b\n\n" "${C_BLUE}Let's create a new project environment.${C_RESET}"

# -----------------------------------------------------------------------------
# 2. Project Name (ui_input)
# -----------------------------------------------------------------------------
ui_input "What is the name of your project?" "my-project"
PROJECT_NAME=$(echo "$UI_INPUT_RESULT" | tr -d '\r')

# -----------------------------------------------------------------------------
# 3. Project Type (ui_select)
# -----------------------------------------------------------------------------
TYPE_OPTIONS=("Web (Node.js, Docker, pnpm)" "Inception (42 Project Structure)")
ui_select "Select Project Type:" "${TYPE_OPTIONS[@]}"

if [[ "$UI_SELECT_RESULT" -eq 0 ]]; then
    PROJECT_TYPE="web"
else
    PROJECT_TYPE="inception"
fi

# -----------------------------------------------------------------------------
# 4. Summary & Confirmation
# -----------------------------------------------------------------------------
printf "\n%b\n" "${C_CYAN}=== Configuration Summary ===${C_RESET}"
printf "  %bProject Name:%b %s\n" "${C_BOLD}" "${C_RESET}" "$PROJECT_NAME"
printf "  %bProject Type:%b %s\n" "${C_BOLD}" "${C_RESET}" "$PROJECT_TYPE"
printf "  %bTemplate:%b     %s\n" "${C_BOLD}" "${C_RESET}" "$TEMPLATE_NAME"
printf "%b\n\n" "${C_CYAN}=============================${C_RESET}"

CONFIRM_OPTIONS=("Yes, create it!" "No, start over" "Cancel")
ui_select "Does this look correct?" "${CONFIRM_OPTIONS[@]}"

case "$UI_SELECT_RESULT" in
    0)
        success "Great! Creating project..."
        
        PROJECT_NAME=$(echo "$PROJECT_NAME" | tr -d '\r')
        
        # Call clone.sh
        "${PROJECT_ROOT}/scripts/clone.sh" "$PROJECT_NAME" "$PROJECT_TYPE"
        ;;
    1)
        warn "Starting over..."
        exec "$0"
        ;;
    *)
        info "Operation cancelled."
        exit 0
        ;;
esac

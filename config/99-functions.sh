#!/bin/bash
# =============================================================================
# config/99-functions.sh – Shared system-wide functions
# =============================================================================

# -----------------------------------------------------------------------------
# Marker function to confirm config loading
# -----------------------------------------------------------------------------
devpod_config_loaded() { return 0; }

# -----------------------------------------------------------------------------
# 1. UI & Logging Functions
# -----------------------------------------------------------------------------
# Helper to write to log file if LOG_FILE is defined
_log_to_file() {
    if [ -n "$LOG_FILE" ]; then
        # Ensure log directory exists
        mkdir -p "$(dirname "$LOG_FILE")"
        # Strip ANSI colors for the log file
        echo -e "$*" | sed 's/\x1b\[[0-9;]*m//g' >> "$LOG_FILE"
    fi
}

log()     { local m; m="[$(date +'%H:%M:%S')] $*"; echo -e "${C_BLUE}$m${C_RESET}"; _log_to_file "$m"; }
success() { local m; m="[$(date +'%H:%M:%S')] ✅ $*"; echo -e "${C_GREEN}$m${C_RESET}"; _log_to_file "$m"; }
warn()    { local m; m="[$(date +'%H:%M:%S')] ⚠ $*"; echo -e "${C_YELLOW}$m${C_RESET}"; _log_to_file "$m"; }
error()   { local m; m="[$(date +'%H:%M:%S')] ❌ ERROR: $*"; echo -e "${C_RED}$m${C_RESET}" >&2; _log_to_file "$m"; exit 1; }
info()    { local m; m="[$(date +'%H:%M:%S')] ℹ $*"; echo -e "${C_CYAN}$m${C_RESET}"; _log_to_file "$m"; }

# -----------------------------------------------------------------------------
# 2. Spinner (Reusable)
# -----------------------------------------------------------------------------
# Usage: long_command & show_spinner $! "Text..."
show_spinner() {
    local pid=$1
    local msg=$2
    local spin_chars="/-\|"
    local spin_idx=0

    while kill -0 "$pid" 2>/dev/null; do
        printf "\r${C_YELLOW}[%c] %s${C_RESET}" "${spin_chars:$spin_idx:1}" "$msg"
        spin_idx=$(( (spin_idx + 1) % 4 ))
        sleep 0.5
    done
    printf "\r\033[K" # Clear the line when done
}

# -----------------------------------------------------------------------------
# 3. Command Checker
# -----------------------------------------------------------------------------
check_command() {
    if ! command -v "$1" &> /dev/null; then
        error "Command '$1' not found. Please install it (e.g., sudo apt install $2) and try again."
    fi
}

# -----------------------------------------------------------------------------
# 4. Configuration Summary
# -----------------------------------------------------------------------------
show_config() {
    printf "%b\n" "${C_CYAN}=== VM-Starter Configuration ===${C_RESET}"
    printf "  %bTemplate:%b %s (%sMB RAM, %s CPUs)\n" "${C_BOLD}" "${C_RESET}" "${TEMPLATE_NAME}" "${TEMPLATE_RAM_MB}" "${TEMPLATE_CPU}"
    printf "  %bUser:%b     %s\n" "${C_BOLD}" "${C_RESET}" "${ADMIN_USER}"
    printf "  %bHostname:%b %s\n" "${C_BOLD}" "${C_RESET}" "${TEMPLATE_HOSTNAME}"
    printf "  %bSSH:%b      host port %s → VM port %s\n" "${C_BOLD}" "${C_RESET}" "${SSH_PORT}" "${SSH_VM_PORT}"
    printf "  %bDisk:%b     %sMB (boot: %sMB)\n" "${C_BOLD}" "${C_RESET}" "${TEMPLATE_DISK_MB}" "${PARTITION_BOOT_SIZE_MB}"
    printf "%b\n" "${C_CYAN}===========================${C_RESET}"
}

# -----------------------------------------------------------------------------
# 5. Key Capture (Interactive UI)
# -----------------------------------------------------------------------------
# Reads a single key (including arrow keys)
get_key() {
    local key next_chars
    # Use -r to prevent backslash escaping, -s for silent, -n1 for one char
    IFS= read -rsn1 key
    # If key is empty, it means Enter was pressed
    if [[ -z "$key" ]]; then
        printf ""
        return
    fi
    # If key is Escape (\e), check for following chars (arrow keys)
    if [[ $key == $'\e' ]]; then
        read -rsn2 -t 0.001 next_chars
        key+="$next_chars"
    fi
    printf "%s" "$key"
}

# -----------------------------------------------------------------------------
# 6. Interactive Selection Menu (ui_select)
# -----------------------------------------------------------------------------
# Usage: ui_select "Choose an option:" "Option 1" "Option 2" "Option 3"
# Returns: The index of the selected option (0-based) in global variable UI_SELECT_RESULT
ui_select() {
    local prompt="$1"
    shift
    local options=("$@")
    local current_idx=0
    local num_options=${#options[@]}
    local key

    # Hide cursor
    printf "\033[?25l"

    while true; do
        # Print prompt and options
        printf "\r${C_BOLD}${C_CYAN}?${C_RESET} ${C_BOLD}%s${C_RESET}\n" "$prompt"
        for i in "${!options[@]}"; do
            if [ "$i" -eq "$current_idx" ]; then
                printf "  ${C_CYAN}❯ %s${C_RESET}\n" "${options[$i]}"
            else
                printf "    %s\n" "${options[$i]}"
            fi
        done

        # Read key
        key=$(get_key)

        # Process key
        if [[ "$key" == "$KEY_UP" ]]; then
            current_idx=$(( (current_idx - 1 + num_options) % num_options ))
        elif [[ "$key" == "$KEY_DOWN" ]]; then
            current_idx=$(( (current_idx + 1) % num_options ))
        elif [[ "$key" == "$KEY_ENTER" ]]; then
            # Clean up and return
            printf "\033[%dA\r\033[K" $((num_options + 1))
            printf "%b %b%s%b %b%s%b\n" "${C_GREEN}✔${C_RESET}" "${C_BOLD}" "$prompt" "${C_RESET}" "${C_CYAN}" "${options[$current_idx]}" "${C_RESET}"
            UI_SELECT_RESULT=$current_idx
            printf "\033[?25h" # Show cursor
            return 0
        elif [[ "$key" == "$KEY_ESC" || "$key" == "q" ]]; then
            printf "\033[%dA\r\033[K" $((num_options + 1))
            printf "\033[?25h" # Show cursor
            return 1
        fi

        # Move cursor back up to redraw
        printf "\033[%dA" $((num_options + 1))
    done
}

# -----------------------------------------------------------------------------
# 7. Interactive Text Input (ui_input)
# -----------------------------------------------------------------------------
# Usage: ui_input "Enter hostname:" "devpod-vm"
# Returns: The entered string (or default) in global variable UI_INPUT_RESULT
ui_input() {
    local prompt="$1"
    local default="$2"
    local input

    printf "%b %b%s%b %b(%s)%b: " "${C_BOLD}${C_CYAN}?${C_RESET}" "${C_BOLD}" "$prompt" "${C_RESET}" "${C_YELLOW}" "$default" "${C_RESET}"
    read -r input
    
    # Clean input: remove ANY carriage returns or non-printable chars
    input=$(echo "$input" | tr -d '\r\n')

    if [ -z "$input" ]; then
        UI_INPUT_RESULT="$default"
    else
        UI_INPUT_RESULT="$input"
    fi

    # Visual feedback
    printf "\033[1A\r\033[K"
    printf "%b %b%s%b %b%s%b\n" "${C_GREEN}✔${C_RESET}" "${C_BOLD}" "$prompt" "${C_RESET}" "${C_CYAN}" "$UI_INPUT_RESULT" "${C_RESET}"
}

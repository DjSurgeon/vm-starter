# VM-Starter Engineering Standards & Knowledge Base 🧠

Welcome to the internal engineering standards for **vm-starter**. 

This document serves as our "Source of Truth" for coding standards, security best practices, and a log of common errors we have encountered and solved. By documenting our learnings here, we ensure that new contributors can quickly onboard and avoid making the same mistakes.

## 1. Coding Philosophy

We believe in Infrastructure as Code (IaC) that is **robust, predictable, and secure**.
- **Strict Linting**: Every Bash script must pass `shellcheck` without errors. We do not use "ignores" or shortcuts in our CI/CD pipeline.
- **Fail Fast**: Scripts must use `set -e` to exit immediately if any command fails, preventing cascading disasters.
- **Idempotency**: Whenever possible, our commands should be safe to run multiple times without breaking the environment.

---

## 2. Known Issues & Solutions (The "Gotchas")

This section acts as a Runbook for common errors detected by our CI/CD pipeline or encountered during development.

### [SC2059] Don't use variables in the printf format string

**Severity**: High (Potential Security Vulnerability / Format String Attack)
**Context**: This error occurs when a variable is placed directly in the first argument of the `printf` command.

#### ❌ The Problem (Anti-Pattern)
```bash
# BAD: The variable is interpreted as part of the format string.
# If $CUSTOM_PATH contains '%s' or '\n', printf will execute them unexpectedly.
printf "  - VMs will be stored in: $CUSTOM_PATH\n"

# BAD: Printing ANSI color codes directly.
printf "${C_CYAN}${C_BOLD}🚀 Welcome${C_RESET}\n"
```

#### ✅ The Solution (Enterprise Standard)
The first argument of `printf` must **always** be a static, literal string. Use `%s` as placeholders for normal strings, and `%b` as placeholders for strings that contain escape sequences (like ANSI colors).

```bash
# GOOD: Using %s for normal strings
printf "  - VMs will be stored in: %s\n" "$CUSTOM_PATH"

# GOOD: Using %b to expand ANSI color codes safely
printf "%b\n" "${C_CYAN}${C_BOLD}🚀 Welcome${C_RESET}"
```

**Why we do this**: It guarantees that user input or dynamic variables will never execute arbitrary format sequences, ensuring the script remains secure and predictable.

---

### [SC2162] read without -r will mangle backslashes

**Severity**: Medium (Data Integrity / Bug)
**Context**: This error occurs when `read` is used without the `-r` flag to capture user input.

#### ❌ The Problem (Anti-Pattern)
```bash
# BAD: If the user inputs a path with backslashes like C:\dev,
# Bash will consume the backslashes as escape characters.
read -p "Enter absolute path: " CUSTOM_PATH
```

#### ✅ The Solution (Enterprise Standard)
Always use the `-r` (raw) flag when reading user input to ensure backslashes are interpreted literally.

```bash
# GOOD: Using -r ensures data is captured exactly as typed.
read -r -p "Enter absolute path: " CUSTOM_PATH
```

**Why we do this**: It prevents unexpected behavior when users input paths or strings containing backslashes, guaranteeing data integrity.

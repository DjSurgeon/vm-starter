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

---

### [SC2087] Quote 'EOF' to make here document expansions happen on the server side

**Severity**: High (Security / Readability)
**Context**: Occurs when running commands on a remote server via SSH using a HereDoc (`<<EOF`) without quoting the `EOF`.

#### ❌ The Problem (Anti-Pattern)
If you don't quote `EOF`, your **local** computer evaluates all variables (like `$VAR`) *before* sending the script to the remote server. 
1. If you actually want a variable to evaluate on the remote server (like `$(hostname)`), you are forced to escape it with ugly backslashes (`\$(hostname)` or `\\\$(hostname)`).
2. It's vulnerable to local variable injection.

```bash
# BAD: The local computer replaces $ADMIN_PASSWORD. 
# But it also replaces $HOST locally before the server even sees it!
ssh user@server <<EOF
    echo "${ADMIN_PASSWORD}" > /secret.txt
    echo "Mi servidor es: \$HOST"
EOF
```

#### ✅ The Solution (Enterprise Standard: SSH Bash-Args)
Always quote `'EOF'` so the script is sent safely and literally to the server. To pass local variables, pass them as arguments to `bash -s`.

```bash
# GOOD: Quote 'EOF'. Pass local variables as arguments ($1, $2).
ssh user@server "bash -s" -- "$ADMIN_PASSWORD" <<'EOF'
    REMOTE_PASS="$1"
    echo "${REMOTE_PASS}" > /secret.txt
    
    # We can now use server-side variables cleanly without !
    echo "Mi servidor es: $(hostname)" escaping
EOF
```

**Why we do this**: It creates a clean barrier between local variables and remote execution, eliminating the need for complex escaping and preventing injection bugs.

---

### [SC2155] Declare and assign separately to avoid masking return values

**Severity**: High (Error Handling / Bug)
**Context**: Occurs when you declare a local variable and assign it a command substitution on the same line, which breaks the `set -e` (Fail Fast) policy.

#### ❌ The Problem (Anti-Pattern)
In our scripts, we use `set -e` so that if any command fails, the script aborts immediately. However, the `local` keyword is itself a command that always returns `0` (Success). If you assign the variable on the same line, it masks the failure of the underlying command.

```bash
# BAD: If 'failing_command' fails, the script will NOT abort
# because 'local' returns a success code (0).
local my_var="$(failing_command)"
```

#### ✅ The Solution (Enterprise Standard)
Always declare the variable first, and then assign the value on the next statement. This ensures the return code of the command substitution is correctly captured by `set -e`.

```bash
# GOOD: The failure of 'failing_command' will trigger 'set -e' and abort the script.
local my_var
my_var="$(failing_command)"

# GOOD: For one-liners (like logging functions), separate statements with a semicolon.
log() { local m; m="[$(date +'%H:%M:%S')] $*"; echo "$m"; }
```

**Why we do this**: It guarantees that silent failures don't creep into our automation, respecting our strict "Fail Fast" policy.

---

### [SC2034] Variable appears unused. Verify use (or export if used externally)

**Severity**: Low (Code Quality / Clean Code)
**Context**: Occurs when you declare a variable but never read its value.

#### ❌ The Problem (Anti-Pattern)
Leaving unused variables in the code creates confusion for future developers and wastes memory. ShellCheck flags this to enforce clean code. We face this in two specific scenarios: loop iterators and global return variables.

```bash
# BAD: We declare 'i' but never use it inside the loop.
for i in {1..60}; do
    echo "Waiting..."
done

# BAD: A global variable acting as a function return value, 
# which is read in other scripts but appears unused locally.
UI_SELECT_RESULT="my_value"
```

#### ✅ The Solution (Enterprise Standard)
Depending on the scenario, we apply two different standards:

1. **For unused loop variables**: Use an underscore (`_`), which is the universal standard for "intentionally ignored variable".
```bash
# GOOD: The underscore clearly communicates the intent.
for _ in {1..60}; do
    echo "Waiting..."
done
```

2. **For global return variables**: Use a specific ShellCheck disable directive to tell the linter that this is intentional.
```bash
# GOOD: We explicitly document that this variable is used externally.
# shellcheck disable=SC2034
UI_SELECT_RESULT="my_value"
```

**Why we do this**: It keeps our codebase perfectly clean, avoids "dead code", and documents our architectural decisions regarding function return values.

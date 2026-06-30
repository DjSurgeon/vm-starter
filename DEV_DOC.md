# VM-Starter: Developer Architecture Guide 🏗️

This guide is intended for developers, DevOps engineers, and recruiters who want to understand the inner workings of **vm-starter**.

## 1. Core Architecture

`vm-starter` is built upon **Bash scripts, Makefiles, and Cloud-Init**, leveraging VirtualBox's command-line tool `VBoxManage` for hypervisor interactions.

The core philosophy is **Infrastructure as Code (IaC)** without needing heavy external tools like Terraform or Ansible. We rely purely on tools available in standard Linux/macOS environments to keep the dependency tree minimal.

### Component Breakdown
1. **Makefile**: The main entry point. It orchestrates the scripts and provides a simple CLI UX (`make init`, `make create`, `make fclean`).
2. **Config (`config/`)**: Modular configuration files (Bash variables) defining specs like RAM, CPU, network ports, and packages.
3. **Template Engine (`scripts/build-template.sh`)**: Creates an immutable "Base Template" VM from an Ubuntu Server ISO.
4. **Cloud-Init (`cloud-init/`)**: Handles the unattended OS installation (autoinstall via `user-data` and `meta-data`).
5. **Cloning Engine (`scripts/create-clone.sh`)**: Uses VirtualBox's linked cloning feature to rapidly spawn project VMs from the Base Template, injecting specific project environments via SSH commands over `nc` (Netcat).

## 2. Unattended Installation (Cloud-Init)

To achieve a 100% automated installation, `vm-starter` uses Ubuntu's **autoinstall** (subiquity) feature powered by Cloud-Init.

When `make template` is called:
1. `cloud-init/user-data` and `meta-data` are packaged into an ISO (`seed.iso`) using `genisoimage`.
2. The Ubuntu ISO and the `seed.iso` are mounted to the template VM.
3. Boot parameters are modified to look for the `seed.iso` for installation instructions.
4. The system installs silently, setting up user passwords, SSH keys, network interfaces, and basic packages without human interaction.

## 3. Storage Abstraction Layer

A key feature for 42 students is dynamic storage pathing. The `/goinfre` directories are volatile.

The `make init` command runs `scripts/init-env.sh`, which:
- Prompts the user for a high-capacity storage path.
- Updates VirtualBox's default machine folder via `VBoxManage setproperty machinefolder`.
- Creates a local `.devpod-data` reference so scripts know where to look for artifacts (like ISOs).

## 4. Smart Port Allocation

Running multiple VMs on the same host requires dynamic port mapping for SSH.
In `config/06-network.sh`, a base port (e.g., `4222`) is defined. The clone script automatically finds the next available port using `netstat` and increments it, ensuring port collisions never occur. It then appends this to `~/.ssh/config` for seamless login.

## 5. Adding New Project Types

To add a new environment type (e.g., `python-data`):
1. Define resource limits (RAM, CPU, disk) and naming prefixes in `config/04-clones.sh`.
2. Add the software dependency arrays or strings in `config/08-stack.sh`.
3. Update the `wizard.sh` UI options and handle the `PROJECT_TYPE` assignment.
4. Add the validation and variable extraction logic into `scripts/clone.sh`.
5. Inject the environment-specific setup logic via SSH in `scripts/provision-project.sh`.
6. Enforce configuration immutability by adding integration tests in `tests/test_config_validation.bats`.

> **Note on Complex Environments (e.g., `inception-gui`)**: The provisioning engine supports completely unattended installation of Graphical User Interfaces (XFCE, X11 configurations) without user interaction by setting `DEBIAN_FRONTEND=noninteractive` and injecting configuration blocks directly into system paths via SSH.

# DevPod – Development Virtual Machines on Steroids 🚀

> Create disposable, reproducible development environments in minutes.

DevPod is a set of scripts and configurations that automate the creation of **Ubuntu 24.04 LTS** based virtual machines (using VirtualBox) tailored for different development workflows. It provides a **base template** that can be cloned into **project-specific VMs** with custom resources (RAM, CPU, disk) and pre-installed stacks (web, Inception, etc.).

## ✨ Features

- **Fully automated** – From ISO download to template creation (no manual steps).
- **Modular configuration** – All settings are split into small, documented files.
- **Two built‑in project types**:
  - `web` – Node.js 20 + pnpm + Docker (ideal for modern web development).
  - `inception` – Skeleton for the 42 Inception project (lightweight, with required directory structure).
- **Smart SSH port allocation** – Each clone gets a unique host port (4222, 4223, …) to avoid conflicts.
- **VS Code Remote SSH ready** – Pre‑configured settings to prevent connection drops.
- **One‑command operations** – `make template`, `make project`, `make ssh`, etc.
- **Cross‑platform** – Works on Linux (apt, dnf, pacman) and macOS (homebrew).

## 📦 Prerequisites

- [VirtualBox](https://www.virtualbox.org/) 7.0+
- `genisoimage` (or `mkisofs`), `curl`, `wget`, `netcat` (`nc`)
- An SSH key pair (`~/.ssh/id_ed25519.pub` or `~/.ssh/id_rsa.pub`)

On most systems you can install everything with:
```bash
make deps
```

## 🚀 Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/dev-pod.git
   cd dev-pod
   ```

2. **Create the base template** (takes ~10 minutes)
   ```bash
   make template
   ```

3. **Create a new project**
   ```bash
   make project
   # Follow the prompts (name and type)
   ```
   or in one line:
   ```bash
   make project NAME=myblog TYPE=web
   ```

4. **Connect to your VM**
   ```bash
   make ssh NAME=web-myblog
   ```
   (The first connection may ask to confirm the host key – type `yes`.)

5. **Start coding!** Your VM is ready with Docker, Node.js (if web type), and the project directory.

## 🛠️ Makefile Commands

| Command | Description |
|---------|-------------|
| `make template` | Create the base template VM (`devpod-base`) |
| `make project` | Create a new project VM (interactive or with NAME=… TYPE=…) |
| `make list` | List all VirtualBox VMs |
| `make start NAME=vm` | Start a VM by name |
| `make stop NAME=vm` | Power off a VM |
| `make ssh NAME=vm` | SSH into a VM (using alias in `~/.ssh/config`) |
| `make status` | Show status of template and projects |
| `make check` | Verify dependencies and configuration |
| `make deps` | Install required system packages |
| `make clean` | Remove downloaded ISOs and seed files (keep VMs) |
| `make fclean` | Delete **all** DevPod VMs, ISOs, and seed files (with confirmation) |
| `make re` | Full rebuild (`fclean` + `template`) |
| `make help` | Display this help |

## ⚙️ Configuration

All settings are stored in the `config/` directory as numbered shell scripts. You can easily customise:

- User name and passwords (`02-users.sh`)
- Hardware resources (`03-template.sh`, `04-clones.sh`)
- Partition sizes (`05-partition.sh`)
- Network ports (`06-network.sh`)
- Installed packages (`07-packages.sh`)
- Software versions (`08-stack.sh`)
- And more…

After changing any configuration, **recreate the template** with `make re` for the changes to take effect.

## 🧩 Project Types

### `web` (Modern Web Development)
- **Resources**: 8 GB RAM, 4 CPUs, 80 GB disk (configurable).
- **Software**: Node.js 20 (via NodeSource), pnpm 9, Docker, Docker Compose.
- **Use case**: Full‑stack JavaScript/TypeScript projects, containers, microservices.

### `inception` (42 Project)
- **Resources**: 4 GB RAM, 2 CPUs, 50 GB disk.
- **Structure**: Creates the `srcs/` directory with subfolders for `nginx`, `wordpress`, `mariadb`, and a basic `docker-compose.yml` template.
- **Use case**: Starting point for the [Inception](https://github.com/42School/inception) project.

## 🔧 Troubleshooting

### Colours not showing in `make help`
Make sure your `make` uses `printf` (the provided Makefile already does). If you still see raw escape codes, your terminal may not support ANSI colours – you can disable them by editing the colour variables in the Makefile.

### SSH connection refused after cloning
The VM may still be booting. Wait a few seconds and try again, or increase `SSH_WAIT_TIMEOUT` in `12-behavior.sh`.

### Docker permission denied inside the VM
Log out and log back in (or run `newgrp docker`). The `usermod -aG docker` command takes effect only for new sessions.

## 📚 Documentation

- [`USER_DOC.md`](USER_DOC.md) – End‑user guide (how to start/stop projects, access the VM, etc.)
- [`DEV_DOC.md`](DEV_DOC.md) – Developer documentation (how to extend DevPod, add new project types, etc.)

## 🤝 Contributing

Contributions are welcome! Please open an issue or a pull request.

## 📄 License

This project is licensed under the MIT License – see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgements

- Inspired by the 42 Born2beRoot and Inception projects.
- Thanks to [dlesieur](https://github.com/LESdylan) for the original ideas.

# VM-Starter 🚀

[![CI Pipeline - Validation & Testing](https://github.com/DjSurgeon/vm-starter/actions/workflows/ci.yml/badge.svg)](https://github.com/DjSurgeon/vm-starter/actions/workflows/ci.yml)
[![Bash](https://img.shields.io/badge/Language-Bash-4EAA25?logo=gnu-bash&logoColor=white)](#)
[![VirtualBox](https://img.shields.io/badge/Virtualization-VirtualBox-183A61?logo=virtualbox&logoColor=white)](#)
[![License](https://img.shields.io/badge/License-CC_BY--NC_4.0-lightgrey)](#)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-0A66C2?logo=linkedin&logoColor=white)](https://www.linkedin.com/in/sergiojimenez42dev/)

> Create disposable, reproducible development environments in minutes without losing your storage limits.

**VM-Starter** is a lightweight Infrastructure-as-Code (IaC) tool built purely with Bash and VirtualBox. It automates the creation of **Ubuntu 24.04 LTS** based virtual machines tailored for different development workflows. The repository employs professional DevOps practices including **Static Application Security Testing (SAST) via ShellCheck** and **Automated Integration Testing & Mocking via Bats-core**.

## 🎯 Why this project?

As a student at **42 School**, I realized that setting up development environments (like the ones needed for `Born2beRoot` or `Inception`) is repetitive and prone to cluster-specific issues (e.g., reaching the 5GB home directory quota). 

**VM-Starter** was born to:
1. **Simplify repetitive tasks**: Create a fully working VM with Docker, Nginx, or Node in a single command.
2. **Solve storage limits**: It dynamically stores your heavy VMs in the `/goinfre` partition, bypassing quota restrictions.
3. **Foster Collaboration**: It provides a standard, secure, and reproducible environment where teams can collaborate seamlessly on future Common Core projects.

## ✨ Features

- **Fully automated** – From ISO download to template creation using Cloud-Init (zero manual steps).
- **Modular configuration** – Settings (RAM, CPU, packages) are split into small, documented scripts.
- **Three built‑in project types**:
  - `web` – Node.js 20 + pnpm + Docker (modern web development).
  - `inception` – Skeleton for the 42 Inception project.
  - `c-pure` – Ultra lightweight C environment for 42 Cursus (Piscine, Libft) with Norminette and strict compilation.
- **Smart SSH port allocation** – Automatically assigns unique host ports (4222, 4223, …) preventing collisions.
- **VS Code Remote SSH ready** – Pre‑configured settings to prevent connection drops.

## 📦 Prerequisites

- [VirtualBox](https://www.virtualbox.org/) 7.0+
- `genisoimage` (or `mkisofs`), `curl`, `wget`, `netcat` (`nc`)
- An SSH key pair (`~/.ssh/id_ed25519.pub` or `~/.ssh/id_rsa.pub`)

On most systems (Linux/macOS) you can install everything with:
```bash
make deps
```

## 🚀 Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/DjSurgeon/vm-starter.git
   cd vm-starter
   ```

2. **Initialize the Storage Path** (Crucial for 42 Clusters)
   ```bash
   make init
   ```
   *Follow the prompts to select `/goinfre/$USER` as your storage path.*

3. **Create the base template** (takes ~10 minutes)
   ```bash
   make template
   ```

4. **Create a new project**
   ```bash
   make create
   # Or in one line: make project NAME=myblog TYPE=web
   ```

5. **Connect to your VM**
   ```bash
   make ssh NAME=web-myblog
   ```
   *Start coding! Your VM is ready with Docker, Node.js (if web type), and the project directory.*

## 🌐 DevOps Ecosystem & Reference Architecture

**VM-Starter** acts as the foundational Infrastructure-as-Code (IaC) layer. It is explicitly designed to integrate seamlessly with microservices and containerized environments. 

You can explore how automated Docker container deployments, artifact registries, and advanced CI/CD pipelines are orchestrated on top of this very infrastructure in my sister repository:
👉 [**Inception - Docker Orchestration Architecture**](https://github.com/DjSurgeon/cursus/tree/main/cursus/inception/intra)

*This dual-repository setup demonstrates a complete End-to-End lifecycle understanding, from bare-metal VM provisioning to application-level container orchestration.*

## 📚 Documentation

Dive deeper into how VM-Starter works:
- [**USER_DOC.md**](USER_DOC.md) – End‑user guide specifically tailored for 42 cluster usage.
- [**DEV_DOC.md**](DEV_DOC.md) – Architecture and developer guide (Cloud-init, Bash scripts, Makefiles).

## 🤝 Contributing & Community

Contributions make the open-source community an amazing place to learn!
- [Contributing Guidelines](CONTRIBUTING.md)
- [Code of Conduct](CODE_OF_CONDUCT.md)
- [Security Policy](SECURITY.md)

## 📄 License

This project is licensed under the **CC BY-NC 4.0 License** – see the [LICENSE](LICENSE) file for details (Non-Commercial use).

---
- Inspired by the 42 Born2beRoot and Inception projects.
- Thanks to [dlesieur](https://github.com/LESdylan) for the original ideas.

*Developed with ❤️ by [Sergio Jimenez](https://www.linkedin.com/in/sergiojimenez42dev/)*

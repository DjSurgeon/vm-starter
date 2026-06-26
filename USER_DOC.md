# VM-Starter: User Guide 🖥️

Welcome to the **vm-starter** user guide. If you are a 42 student working on the cluster iMacs, or if you are on your own machine and want to create virtual machines without the hassle, this guide is for you.

## 1. The Cluster iMacs Problem

In the 42 clusters, the space in your home directory (HOME) is very limited (usually around a 5GB quota). Virtual machines easily take up between 10GB and 20GB. If you try to save them in your HOME, **you will run out of space and won't be able to log in**.

The solution is to use the `/goinfre` (or `/sgoinfre`) directory, which has hundreds of GBs available, but which **is frequently wiped** or doesn't travel with you across different computers.

**vm-starter** solves this problem by automating the VirtualBox configuration to use `/goinfre` or any path you prefer, and allows you to recreate your entire development environment in minutes if you switch computers.

## 2. Quick Initialization (`make init`)

When you arrive at an iMac and clone the repository, the first thing you must do is tell `vm-starter` where to store the heavy data (ISOs, hard drives, etc.).

```bash
git clone https://github.com/DjSurgeon/vm-starter.git
cd vm-starter
make init
```

The interactive script will ask you:
1. **Base path**: By default, it will suggest `/goinfre/$USER`. Accept it!
2. **Create folders**: It will automatically create the necessary folders in `/goinfre`.
3. **Configure VirtualBox**: It will modify the VirtualBox configuration on your system to save the VMs there.

## 3. Create your First Machine (`make create`)

Once initialized, you can create your virtual machine:

```bash
make create
```

The wizard will prompt you for:
1. **Project name**: For example, `inception` or `my-server`.
2. **Project type**:
   - `web`: Installs Node.js, Docker, and modern web development tools.
   - `inception`: Leaves a folder skeleton (`srcs/nginx`, etc.) ready for the 42 Inception project.
   - `c-pure`: Installs a strict, ultra-lightweight C environment (`gcc`, `clang`, `valgrind`, official `norminette`) specifically tuned for the 42 Cursus (Piscine, Libft). It pre-configures `.bashrc` aliases like `gcc42` and sets `CC=cc`.

> ⏳ **Note**: The first time you run this on a new computer, it will have to download the Ubuntu ISO (about 2GB) and create the base template. This can take about 10-15 minutes. Be patient!

## 4. Connect to the Machine

`vm-starter` automatically configures SSH ports to prevent conflicts between different machines (using ports like 4222, 4223, etc.). It also adds aliases to your `~/.ssh/config` file.

To connect, simply use:

```bash
make ssh NAME=your-project
```

That's it! You will be inside your virtual machine and ready to start coding.

## 5. Maintenance and Cleanup

To see the machines you have:
```bash
make list
```

To power off the machine when you finish for the day:
```bash
make stop NAME=your-project
```

To delete absolutely everything (ideal if you need to free up space quickly):
```bash
make fclean
```

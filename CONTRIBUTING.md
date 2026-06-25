# Contributing to vm-starter

First off, thank you for considering contributing to `vm-starter`! It's people like you that make the open-source community such a great place to learn, inspire, and create.

## How to Contribute

### 1. Report Bugs
If you find a bug, please create an issue using the `Bug Report` template. Include as much detail as possible.

### 2. Suggest Enhancements
If you have an idea to improve `vm-starter`, create an issue using the `Feature Request` template.

### 3. Pull Requests & Development Workflow (Branching Strategy)

This project strictly follows a **Trunk-Based Development** methodology to ensure rapid continuous integration and deployment robustness:

1. All new features and bug fixes must be developed in short-lived branches (`feature/feature-name` or `fix/bug-name`).
2. Ensure your code follows the existing style (Shellcheck for bash scripts). **Please read our [Engineering Standards](docs/engineering_standards.md) before submitting code.**
3. **Crucial:** Run the testing suite locally using `make test`. It is **mandatory** that the automated CI/CD pipeline (SAST via ShellCheck + Integration Tests via Bats) passes with a green build before any merge is allowed.
4. Update the documentation (`README.md`, `USER_DOC.md`, or `DEV_DOC.md`) if necessary.
5. Code is integrated directly into the `main` branch via peer-reviewed Pull Requests.

## Testing Changes
To test your changes locally, we recommend running:
```bash
make fclean
make re
```
Ensure that the template VM is created successfully and you can spawn a project VM without errors.

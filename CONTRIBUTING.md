# Contributing to vm-starter

First off, thank you for considering contributing to `vm-starter`! It's people like you that make the open-source community such a great place to learn, inspire, and create.

## How to Contribute

### 1. Report Bugs
If you find a bug, please create an issue using the `Bug Report` template. Include as much detail as possible.

### 2. Suggest Enhancements
If you have an idea to improve `vm-starter`, create an issue using the `Feature Request` template.

### 3. Pull Requests
1. Fork the repo and create your branch from `main`.
2. If you've added code that should be tested, add tests or describe how to test it.
3. Ensure your code follows the existing style (Shellcheck for bash scripts).
4. Update the documentation (`README.md`, `USER_DOC.md`, or `DEV_DOC.md`) if necessary.
5. Create a Pull Request using the provided template.

## Testing Changes
To test your changes locally, we recommend running:
```bash
make fclean
make re
```
Ensure that the template VM is created successfully and you can spawn a project VM without errors.

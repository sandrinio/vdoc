# Contributing to vdoc

Thank you for your interest in contributing to vdoc!

## Development Setup

### Prerequisites

- Bash 4.0+
- Git
- [shellcheck](https://github.com/koalaman/shellcheck) - Shell script linter
- [bats-core](https://github.com/bats-core/bats-core) - Bash testing framework

### Install Development Tools

```bash
# macOS
brew install shellcheck bats-core

# Ubuntu/Debian
sudo apt-get install shellcheck
git clone https://github.com/bats-core/bats-core.git && cd bats-core && sudo ./install.sh /usr/local
```

### Clone and Test

```bash
git clone https://github.com/sandrinio/vdoc.git
cd vdoc
bats tests/
```

## Code Standards

### Shell Scripts

- Use `#!/usr/bin/env bash` shebang
- Always use `set -euo pipefail`
- Quote all variables: `"${var}"` not `$var`
- Use `[[` for conditionals, not `[`
- Pass shellcheck with no warnings

### Naming Conventions

| Item | Convention | Example |
|------|------------|---------|
| Variables | UPPER_SNAKE_CASE | `PRESET_NAME` |
| Functions | lower_snake_case | `detect_language` |
| Files | kebab-case | `doc-page.md` |
| Presets | language.conf | `typescript.conf` |

### Comments

```bash
# Single line comment for simple explanations

# Multi-line comments for complex logic:
# - First point
# - Second point

# TODO: Description of future work
```

## Project Structure

```
core/           # Universal tools (scanner, instructions, presets)
adapters/       # Platform-specific adapters
tests/          # Bats test files
tests/fixtures/ # Test project fixtures
```

## Making Changes

### 1. Create a Branch

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/your-bug-fix
```

### 2. Make Your Changes

- Keep commits atomic and focused
- Write clear commit messages
- Add tests for new functionality

### 3. Test Your Changes

```bash
# Run shellcheck
shellcheck core/scan.sh install.sh adapters/*/generate.sh

# Run tests
bats tests/

# Test manually with a sample project
./install.sh claude
```

### 4. Submit a Pull Request

- Fill out the PR template
- Reference any related issues
- Ensure CI passes

## Adding a New Language Preset

1. Create `core/presets/<language>.conf`
2. Define required variables:
   - `PRESET_NAME`
   - `PRESET_VERSION`
   - `EXCLUDE_DIRS`
   - `EXCLUDE_FILES`
   - `ENTRY_PATTERNS`
   - `DOCSTRING_PATTERN`
   - `DOCSTRING_END`
   - `DOC_SIGNALS`
3. Add a test fixture in `tests/fixtures/<language>-project/`
4. Add tests in `tests/test_presets.bats`

## Adding a New Platform Adapter

1. Create `adapters/<platform>/generate.sh`
2. Read `core/instructions.md`
3. Transform to platform-specific format
4. Document the output location in README
5. Add to install.sh platform list

## Reporting Issues

- Use GitHub Issues
- Include vdoc version (`vdoc --version`)
- Include platform and OS
- Provide reproduction steps
- Include relevant error output

## Questions?

Open a Discussion on GitHub or reach out to maintainers.

---

*Thank you for contributing to vdoc!*

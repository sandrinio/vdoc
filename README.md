# vdoc

**AI-Powered Documentation Generator**

Generate and maintain living documentation for your codebase using AI.

---

## Quick Start

```bash
# Install vdoc
curl -fsSL https://raw.githubusercontent.com/sandrinio/vdoc/main/scripts/install-global.sh | bash

# Initialize in your project
cd your-project
vdoc init --ai claude

# That's it! Open Claude Code and say:
# "generate documentation for this project"
```

---

## What is vdoc?

vdoc generates comprehensive documentation from your source code and keeps it current as your codebase evolves. It works with multiple AI coding tools including Claude Code, Cursor, Windsurf, Aider, and Continue.

**Key Features:**
- **One command install** - `curl | bash` and you're ready
- **Zero dependencies** - Pure bash, works everywhere
- **Multi-platform** - Single source of truth, adapters for each AI tool
- **Quality metrics** - Track documentation coverage, freshness, completeness

---

## Installation

### One-liner (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/sandrinio/vdoc/main/scripts/install-global.sh | bash
```

This installs `vdoc` to `~/.vdoc/` and adds it to your PATH.

### Manual Installation

```bash
git clone https://github.com/sandrinio/vdoc.git
cd vdoc
./install.sh claude  # or: cursor, windsurf, aider, continue
```

### Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/sandrinio/vdoc/main/scripts/install-global.sh | bash -s -- --uninstall
```

---

## Usage

### Initialize Project

```bash
vdoc init                    # Basic initialization
vdoc init --ai claude        # Init + Claude Code integration
vdoc init --ai cursor        # Init + Cursor integration
```

### Scan Codebase

```bash
vdoc scan                    # Incremental scan (fast)
vdoc scan --full             # Full rescan
```

### Check Quality

```bash
vdoc quality                 # Terminal report
vdoc quality --json          # JSON output (for CI)
vdoc quality --md            # Markdown output
vdoc quality --threshold 70  # Fail if score < 70
```

### Manage Platforms

```bash
vdoc install cursor          # Add Cursor integration
vdoc install windsurf        # Add Windsurf integration
vdoc uninstall cursor        # Remove integration
```

---

## Supported Platforms

| Platform | Command | Integration Location |
|----------|---------|---------------------|
| **Claude Code** | `vdoc init --ai claude` | `~/.claude/skills/vdoc/` |
| **Cursor** | `vdoc init --ai cursor` | `.cursor/rules/vdoc.md` |
| **Windsurf** | `vdoc init --ai windsurf` | `.windsurfrules` |
| **Aider** | `vdoc init --ai aider` | `.aider/conventions/` |
| **Continue** | `vdoc init --ai continue` | `.continue/prompts/` |

---

## Project Structure

After initialization, your project will have:

```
your-project/
└── vdocs/
    ├── _manifest.json     # Codebase index + quality metrics
    ├── .vdoc/
    │   └── presets/       # Custom presets (optional)
    └── *.md               # Generated documentation
```

---

## Quality Metrics

vdoc tracks three documentation health metrics:

| Metric | Weight | Description |
|--------|--------|-------------|
| **Coverage** | 40% | Percentage of files with documentation |
| **Freshness** | 35% | How recent docs are vs source changes |
| **Completeness** | 25% | Required sections present in docs |

Run `vdoc quality` to see your score:

```
Documentation Quality Report
════════════════════════════════════════════

  Overall Score:  78/100  ███████░░░

────────────────────────────────────────────
  Coverage:       85%     (42/50 files documented)
  Freshness:      72%     (14 days avg staleness)
  Completeness:   80%     (4 docs with gaps)
════════════════════════════════════════════
```

---

## CI Integration

Use `vdoc quality` as a quality gate in CI:

```bash
# Fail build if quality < 70
vdoc quality --threshold 70

# JSON output for parsing
vdoc quality --json | jq '.overall_score'
```

---

## Troubleshooting

### vdoc command not found

Add to your shell profile (`~/.bashrc` or `~/.zshrc`):

```bash
export PATH="$HOME/.local/bin:$PATH"
```

### jq not found

Install jq for full functionality:

```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt install jq
```

---

## Requirements

- Bash 3.2+ (macOS default)
- jq (recommended, for JSON processing)
- Git (optional, for incremental scanning)

---

## Documentation

- [Product Specification](vdoc-product-specification.md)
- [Contributing](CONTRIBUTING.md)
- [Changelog](CHANGELOG.md)

---

## License

[MIT](LICENSE)

---

*vdoc v2.0.0 | Made with AI, for AI-assisted development*

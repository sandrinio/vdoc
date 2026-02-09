# STORY-089: Update README & GitHub Documentation

## Metadata
| Field | Value |
|-------|-------|
| **Parent Epic** | [EPIC-008](EPIC.md) |
| **Status** | Draft |
| **Ambiguity Score** | Low |
| **Actor** | New User / Evaluator |
| **Complexity** | Low |
| **Priority** | P1 - High |

---

## 1. The Spec (The Contract)

### 1.1 User Story
> As a **Developer evaluating vdoc**,
> I want the GitHub README to clearly explain what vdoc does in 30 seconds,
> So that **I can decide if it's right for my project without reading code**.

### 1.2 Detailed Requirements
- [ ] Lead with a clear, one-line value proposition
- [ ] Show installation in 1 command
- [ ] Show usage in 2-3 commands
- [ ] Explain what the tool does step-by-step
- [ ] Add security statement (read-only, no code changes)
- [ ] List what gets analyzed and what gets generated
- [ ] Keep above-the-fold content under 20 lines
- [ ] Add badges (version, license, platforms)
- [ ] Update CONTRIBUTING.md with new architecture
- [ ] Update CHANGELOG.md with v3 features

---

## 2. The Truth (Executable Tests)

### 2.1 Acceptance Criteria (Gherkin)
```gherkin
Feature: GitHub Documentation

  Scenario: First impression (above the fold)
    Given a developer opens the GitHub repo
    Then they see value proposition in first line
    And they see install command within 5 lines
    And they see usage example within 10 lines

  Scenario: Security clarity
    Given a developer has security concerns
    When they read the README
    Then they find explicit "read-only" statement
    And they understand no source code is modified

  Scenario: How it works
    Given a developer wants to understand the tool
    When they scroll to "How It Works" section
    Then they see step-by-step explanation
    And they understand what gets analyzed
    And they understand what gets generated
```

---

## 3. Technical Context (For Coder Agent)

### 3.1 Affected Files
- `README.md` - Main documentation (complete rewrite)
- `CONTRIBUTING.md` - Update for new architecture
- `CHANGELOG.md` - Add v3 feature notes
- `.github/ISSUE_TEMPLATE/` - Update templates

### 3.2 README Structure

```markdown
# vdoc

**AI-powered documentation that understands your codebase.**

> Generate living documentation from code structure — not just comments.

[![Version](https://img.shields.io/badge/version-2.0.0-blue)]()
[![License](https://img.shields.io/badge/license-MIT-green)]()
[![Platforms](https://img.shields.io/badge/platforms-Claude%20|%20Cursor%20|%20Windsurf-purple)]()

## Quick Start

```bash
# Install (one command)
curl -fsSL https://vdoc.dev/install | bash

# Initialize in your project
cd your-project
vdoc init --ai claude

# Done! Ask your AI: "generate documentation for this project"
```

## What is vdoc?

vdoc scans your codebase and creates a **smart manifest** that helps AI tools generate accurate, feature-based documentation.

**Perfect for:**
- Product Managers → Understand what the app does
- New Developers → Onboard faster with feature docs
- Tech Leads → Keep documentation in sync with code

## 🔒 Security First

vdoc is **completely read-only**:

| What vdoc does | What vdoc does NOT do |
|----------------|----------------------|
| ✅ Reads source files | ❌ Modify your code |
| ✅ Analyzes structure | ❌ Execute your code |
| ✅ Creates `vdocs/` folder | ❌ Send data externally |
| ✅ Generates manifest | ❌ Access credentials |

Your code stays exactly as it is. vdoc only **analyzes** and **documents**.

## How It Works

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐    ┌──────────────┐
│  Your Code  │ → │  vdoc scan   │ → │  Manifest   │ → │  AI + Docs   │
└─────────────┘    └──────────────┘    └─────────────┘    └──────────────┘
```

### Step 1: Analyze
vdoc scans your project and detects:
- **Features** — Authentication, User Management, API, etc.
- **Functions** — Names, signatures, descriptions
- **Endpoints** — API routes from Express, FastAPI, Next.js, etc.
- **Dependencies** — What code calls what

### Step 2: Generate Manifest
Creates `vdocs/_manifest.json` containing:
```json
{
  "features": {
    "Authentication": {
      "functions": ["login", "logout", "validateJWT"],
      "endpoints": ["/api/auth/login", "/api/auth/logout"]
    }
  }
}
```

### Step 3: AI Documentation
Your AI tool (Claude, Cursor, etc.) reads the manifest and generates:
- `authentication.md` — Not `auth-ts.md`
- `user-management.md` — Not `user-service-file.md`
- Feature-based docs that humans actually want to read

## Usage

### Commands

```bash
vdoc init                    # Initialize vdoc
vdoc init --ai claude        # Initialize + Claude integration
vdoc scan                    # Update manifest (incremental)
vdoc scan --full             # Full rescan
vdoc quality                 # Check documentation coverage
vdoc quality --threshold 70  # CI quality gate
```

### Supported AI Platforms

| Platform | Command | Integration |
|----------|---------|-------------|
| Claude Code | `vdoc init --ai claude` | CLAUDE.md + skills |
| Cursor | `vdoc init --ai cursor` | .cursorrules |
| Windsurf | `vdoc init --ai windsurf` | .windsurfrules |
| Aider | `vdoc init --ai aider` | .aider/ |
| Continue | `vdoc init --ai continue` | .continue/ |

## What Gets Analyzed

| Language | Functions | Classes | API Routes | Imports |
|----------|-----------|---------|------------|---------|
| TypeScript/JS | ✅ | ✅ | ✅ Express, Next.js | ✅ |
| Python | ✅ | ✅ | ✅ FastAPI, Flask | ✅ |
| Go | ✅ | ✅ (structs) | ✅ Chi, Gin | ✅ |

## Project Structure

After running `vdoc init`:

```
your-project/
├── vdocs/
│   ├── _manifest.json     # Smart codebase index
│   ├── authentication.md  # Generated by AI
│   ├── user-management.md # Generated by AI
│   └── api.md             # Generated by AI
└── ... your code (unchanged)
```

## Requirements

- Bash 3.2+ (macOS/Linux default)
- jq (for JSON processing)
- Git (optional, for smart incremental scanning)
- Node.js 18+ (optional, for advanced AST parsing)

## Troubleshooting

<details>
<summary><code>vdoc: command not found</code></summary>

Add to your shell profile (~/.zshrc or ~/.bashrc):
```bash
export PATH="$HOME/.local/bin:$PATH"
```
Then restart your terminal.
</details>

<details>
<summary><code>jq: command not found</code></summary>

```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt install jq
```
</details>

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup.

## License

MIT — see [LICENSE](LICENSE) for details.

---

<p align="center">
  <b>vdoc</b> — Documentation that evolves with your code
</p>
```

### 3.3 Key Messaging Points

**Value Proposition (one line):**
> AI-powered documentation that understands your codebase.

**Security Statement:**
> vdoc is completely read-only. Your code stays exactly as it is.

**How It Works (simple):**
> Scan → Manifest → AI Docs

**Target Audience:**
- Product Managers → Feature understanding
- New Developers → Faster onboarding
- Tech Leads → Documentation sync

### 3.4 CONTRIBUTING.md Updates

```markdown
# Contributing to vdoc

## Architecture Overview

```
vdoc/
├── app/
│   └── vdoc.sh           # CLI entry point
├── core/
│   ├── scan.sh           # File scanning
│   ├── features.sh       # Feature extraction (v3)
│   ├── manifest.sh       # Manifest generation
│   └── presets/          # Language configs
├── tools/
│   └── parse-ast.js      # Tree-sitter parser (optional)
├── adapters/
│   └── {platform}/       # AI platform integrations
└── tests/
    └── *.bats            # Bash unit tests
```

## Development Setup

```bash
git clone https://github.com/sandrinio/vdoc.git
cd vdoc
./install.sh  # Local development install
```

## Running Tests

```bash
# Run all tests
./tests/run.sh

# Run specific test
bats tests/scan.bats
```

## Pull Request Guidelines

1. Create feature branch from `main`
2. Add tests for new functionality
3. Update README if adding user-facing features
4. Run `vdoc quality` on a test project
5. Submit PR with clear description
```

### 3.5 CHANGELOG.md Updates

```markdown
# Changelog

## [3.0.0] - 2026-XX-XX

### Added
- **Feature Detection** — Auto-detect features from code structure
- **API Route Detection** — Express, FastAPI, Next.js, Flask, Go
- **Manifest v3** — New schema with features, functions, endpoints
- **Dependency Graph** — Track what code calls what
- **Multi-language Support** — TypeScript, Python, Go

### Changed
- Documentation now organized by feature, not by file
- Faster init with `--fast` flag (skips hashing)
- Updated instructions for AI platforms

### Fixed
- Init performance (35s → <3s for large projects)

## [2.0.0] - Previous Release
...
```

---

## 4. Notes

- README is the first impression — optimize for scanning
- Security statement is critical for enterprise adoption
- Use expandable sections for troubleshooting (keeps README clean)
- Badges add credibility
- "How It Works" diagram helps visual learners
- Keep code examples copy-pasteable

# EPIC-000: Project Foundation & Stack Definition

## Metadata
| Field | Value |
|-------|-------|
| **Status** | ✅ Complete |
| **Ambiguity Score** | 🟢 Low |
| **Context Source** | PRD Section 13 (Open Design Questions) |
| **Owner** | TBD |
| **Priority** | P0 - Critical (Blocker for all other epics) |
| **Tags** | #foundation, #architecture, #decisions, #setup |
| **Target Date** | TBD |

---

## 1. The Executive Pitch
> Target Audience: Stakeholders, Business Sponsors, Non-Technical Leads

### 1.1 The Problem
Before building vdoc, we must resolve open design questions, establish the repository structure, confirm the tech stack, and set up development infrastructure. Without these decisions, subsequent epics will face blockers and inconsistent implementations.

### 1.2 The Solution
Create a foundational epic that:
- Resolves all open design questions from the PRD
- Establishes repository structure and file conventions
- Confirms tech stack and compatibility requirements
- Sets up development environment and testing approach
- Defines contribution and coding standards

### 1.3 The Value (North Star)
- Zero ambiguity when starting EPIC-001
- Consistent development experience across contributors
- Clear architectural decisions documented for future reference

---

## 2. The Scope Boundaries (AI Guardrails)
> Target Audience: Planner Agent (Critical for preventing hallucinations)

### 2.1 IN-SCOPE (Build This)
- [x] Resolve all 8 open design questions from PRD Section 13
- [x] Create repository structure (core/, adapters/, etc.)
- [x] Define tech stack requirements and compatibility matrix
- [x] Set up development environment (shell, testing tools)
- [x] Create CONTRIBUTING.md with coding standards
- [x] Define testing strategy for bash scripts
- [x] Create initial CI workflow (lint, test)
- [x] Set up issue/PR templates
- [x] Define versioning strategy (semver)
- [x] Create initial README.md

### 2.2 OUT-OF-SCOPE (Do NOT Build This)
- No actual scanner implementation (EPIC-001)
- No installer implementation (EPIC-002)
- No documentation generation logic (EPIC-003)
- No platform adapters (EPIC-002, EPIC-004)

---

## 3. Open Design Decisions (PRD Section 13)

> **CRITICAL:** These must be resolved before proceeding to EPIC-001.

### 3.1 Manifest Location
| Option | Pros | Cons |
|--------|------|------|
| `vdocs/_manifest.json` | Keeps everything contained in vdocs/ | Less discoverable |
| `_manifest.json` (root) | More discoverable, easy for AI to find | Clutters project root |

**Decision:** `vdocs/_manifest.json`
**Rationale:** Keeps all vdoc artifacts contained in one directory. Clean project root.

---

### 3.2 Git Tracking Strategy
| File/Directory | Commit? | Rationale |
|----------------|---------|-----------|
| `vdocs/.vdoc/` (tools) | **Yes** | Teammates get tools without download |
| `vdocs/*.md` (generated docs) | **Yes** | Documentation is the output |
| `vdocs/_manifest.json` | **Yes** | Shared state for updates |
| Platform instruction files | **No** | Gitignored, regenerated per user |
| `scan.sh` output | **No** | Ephemeral, regenerated each run |

**Decision:** Commit tools, docs, and manifest. Gitignore platform-specific files and scan output.

---

### 3.3 Multi-Language Projects
| Option | Description |
|--------|-------------|
| Single preset | Use primary language only |
| Multiple presets | Support `vdoc.config.json` for path-based presets |
| Deferred | Handle in EPIC-006 (Advanced Features) |

**Decision:** Support multi-language from start via `vdoc.config.json`

```json
{
  "languages": [
    { "path": "frontend/", "preset": "typescript" },
    { "path": "backend/", "preset": "python" }
  ]
}
```

If config exists → use path-based presets. If not → auto-detect single language.

---

### 3.4 Incremental Scanning
| Option | Description |
|--------|-------------|
| Full scan always | Simpler, reliable, slower on large codebases |
| Git diff-based | Faster updates, more complex |
| Deferred | Handle in EPIC-006 (Advanced Features) |

**Decision:** Full scan always for Phase 1. Git diff-based deferred to EPIC-006.

---

### 3.5 Doc Template Format
| Option | Description |
|--------|-------------|
| Standardized templates | Consistent output, less flexibility |
| Freeform per section | Flexible, potentially inconsistent |
| Hybrid | Templates with optional overrides |

**Decision:** Hybrid - standardized templates with optional section overrides.

---

### 3.6 Lock File Strategy
| Option | Description |
|--------|-------------|
| File-based + timestamp | `.vdoc.lock` with 10-min stale cleanup |
| Advisory only | Warn but don't block |
| Deferred | Handle in EPIC-006 (Advanced Features) |

**Decision:** File-based with timestamp and 10-minute stale cleanup.

```json
// .vdoc.lock
{
  "started_at": "2026-02-05T14:30:00Z",
  "user": "developer",
  "platform": "claude-code"
}
```

**Logic:**
1. Before update: check if `.vdoc.lock` exists
2. If exists AND < 10 min old → abort with message
3. If exists AND > 10 min old → delete stale lock, proceed
4. Create lock → run update → delete lock

---

### 3.7 Adapter Versioning
| Option | Description |
|--------|-------------|
| Unified version | All adapters share vdoc version |
| Independent semver | Each adapter versioned separately |

**Decision:** Unified version. All adapters share vdoc version number. Adapters are thin wrappers (~20-30 lines) that don't need independent versioning.

---

### 3.8 Quality Variance Handling
| Option | Description |
|--------|-------------|
| Accept variance | Document that results vary by AI model |
| Platform-specific tuning | Customize instructions per platform capability |
| Transparent tiers | Label platforms as "Primary" vs "Supported" |

**Decision:** Accept variance + Transparent tiers.

- Accept that different AI models produce different quality output
- Document in README:
  - **Primary platforms (tested, recommended):** Claude Code, Cursor
  - **Supported platforms (works, results may vary):** Windsurf, Aider, Continue

---

## 4. Technical Stack

### 4.1 Core Requirements
| Component | Technology | Version | Notes |
|-----------|------------|---------|-------|
| Shell | Bash | 4.0+ | Primary scripting |
| POSIX Utilities | find, grep, sed, awk, shasum | Standard | Zero external deps |
| Version Control | Git | 2.0+ | For diff-based features |
| JSON Processing | jq (optional) | Latest | Can fallback to grep/sed |

### 4.2 Compatibility Matrix
| OS | Bash Version | Status |
|----|--------------|--------|
| macOS 12+ | 3.2 (default), 4.0+ (brew) | Requires brew bash for some features |
| Ubuntu 20.04+ | 5.0+ | Full support |
| Windows (WSL2) | 5.0+ | Full support |
| Windows (Git Bash) | 4.4+ | Limited testing |

### 4.3 Development Tools
| Tool | Purpose |
|------|---------|
| shellcheck | Bash linting |
| bats-core | Bash testing framework |
| shfmt | Shell formatting (optional) |

---

## 5. Repository Structure

```
github.com/sandrinio/vdoc/
├── .github/
│   ├── workflows/
│   │   └── ci.yml
│   ├── ISSUE_TEMPLATE/
│   └── PULL_REQUEST_TEMPLATE.md
├── core/
│   ├── instructions.md          # Single source of truth
│   ├── scan.sh                  # Codebase scanner
│   ├── presets/
│   │   ├── typescript.conf
│   │   ├── javascript.conf
│   │   ├── python.conf
│   │   └── default.conf
│   └── templates/
│       └── doc-page.md
├── adapters/
│   ├── claude/
│   │   └── generate.sh
│   ├── cursor/
│   │   └── generate.sh
│   ├── windsurf/
│   │   └── generate.sh
│   ├── aider/
│   │   └── generate.sh
│   └── continue/
│       └── generate.sh
├── install.sh                   # Universal installer
├── tests/
│   ├── test_scan.bats
│   ├── test_install.bats
│   └── fixtures/
├── docs/
│   └── (internal docs, not vdoc output)
├── README.md
├── CONTRIBUTING.md
├── LICENSE
└── CHANGELOG.md
```

---

## 6. Testing Strategy

### 6.1 Unit Tests (bats-core)
- Test each function in `scan.sh` isolation
- Test preset loading and variable parsing
- Test hash computation accuracy
- Test docstring extraction patterns

### 6.2 Integration Tests
- End-to-end scan of fixture projects
- Manifest generation and validation
- Adapter output format verification

### 6.3 Fixtures
```
tests/fixtures/
├── typescript-project/
├── python-project/
├── go-project/
├── mixed-language/
└── edge-cases/
```

---

## 7. Dependencies

### 7.1 Technical Dependencies
- GitHub repository access
- CI/CD runner (GitHub Actions)
- shellcheck, bats-core for testing

### 7.2 Epic Dependencies
- Blocked by: None (foundational)
- Blocks: ALL other epics (001-007)

---

## 8. Linked Stories
| Story ID | Name | Status |
|----------|------|--------|
| STORY-000-A | Resolve open design decisions | ✅ Complete |
| STORY-000-B | Create repository structure | ✅ Complete |
| STORY-000-C | Set up CI workflow (lint + test) | ✅ Complete |
| STORY-000-D | Create CONTRIBUTING.md | ✅ Complete |
| STORY-000-E | Create README.md | ✅ Complete |
| STORY-000-F | Set up bats-core testing | ✅ Complete |
| STORY-000-G | Create test fixtures | ✅ Complete |
| STORY-000-H | Define versioning strategy | ✅ Complete |
| STORY-000-I | Create issue/PR templates | ✅ Complete |

---

## 9. Acceptance Criteria

- [x] All 8 design decisions documented with rationale
- [x] Repository structure created and committed
- [x] CI pipeline passing (shellcheck, bats)
- [x] README.md explains project purpose and quick start
- [x] CONTRIBUTING.md defines coding standards
- [x] At least one test fixture project exists
- [x] Basic bats test suite runs successfully

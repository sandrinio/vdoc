# EPIC-003: Documentation Generation Engine

## Metadata
| Field | Value |
|-------|-------|
| **Status** | ✅ Complete |
| **Ambiguity Score** | 🟡 Medium |
| **Context Source** | Roadmap Phase 1 |
| **Owner** | TBD |
| **Priority** | P0 - Critical |
| **Tags** | #documentation, #ai-workflow, #init, #update |
| **Target Date** | TBD |

---

## 1. The Executive Pitch
> Target Audience: Stakeholders, Business Sponsors, Non-Technical Leads

### 1.1 The Problem
Documentation is either never written, outdated immediately, or requires manual effort to maintain. AI tools can generate docs but lack structured workflows for keeping them current.

### 1.2 The Solution
Define AI-driven workflows for initial documentation generation (Init) and ongoing updates (Update). The AI interprets scanner output, proposes documentation structure, generates pages, and performs diff-aware updates based on file hash changes.

### 1.3 The Value (North Star)
- First-run generates complete documentation in minutes
- Updates only regenerate sections for changed files
- User edits to documentation are preserved during updates

---

## 2. The Scope Boundaries (AI Guardrails)
> Target Audience: Planner Agent (Critical for preventing hallucinations)

### 2.1 IN-SCOPE (Build This)
- [x] Init workflow: detect absence of `_manifest.json`, trigger interactive onboarding
- [x] Scanner execution and output parsing by AI
- [x] Documentation structure proposal based on detected categories
- [x] Interactive confirmation with user before generation
- [x] Documentation page generation from source analysis
- [x] Update workflow: hash comparison against manifest
- [x] Three-bucket sorting: new files, changed files, deleted files
- [x] Diff-aware patching (only modify sections for changed source)
- [x] Tiered description strategy (docstring → inferred → analyzed)
- [x] User-added section handling (explicit paths, "auto", "none")
- [x] Manifest update after generation/update
- [x] Documentation templates in `templates/doc-page.md`

### 2.2 OUT-OF-SCOPE (Do NOT Build This)
- No platform-specific instruction formatting (handled by adapters)
- No CI/CD integration (EPIC-007)
- No quality scoring (EPIC-006)
- No export to external tools (EPIC-007)

---

## 3. Context

### 3.1 User Personas
- **Developer**: Triggers init/update, reviews proposals, confirms generation
- **AI Tool**: Executes workflows, reads sources, generates prose

### 3.2 User Journey - Init (Happy Path)
```mermaid
flowchart LR
    A[No manifest detected] --> B[Run scan.sh]
    B --> C[AI proposes doc structure]
    C --> D[User confirms/adjusts]
    D --> E[AI generates docs]
    E --> F[Write _manifest.json]
```

### 3.3 User Journey - Update (Happy Path)
```mermaid
flowchart LR
    A[User runs vdoc update] --> B[Run scan.sh]
    B --> C[Compare hashes to manifest]
    C --> D[Identify changed files]
    D --> E[Patch affected doc sections]
    E --> F[Update manifest hashes]
```

### 3.4 Technical Requirements

**Tiered Description Strategy:**
| Pass | Method | Token Cost | Coverage |
|------|--------|------------|----------|
| A: Script-extracted | Docstrings from scan.sh | Zero | ~40-60% |
| B: Metadata-inferred | AI derives from filename, category, exports | Minimal | ~25-40% |
| C: Source-analyzed | AI reads actual source code | Full file read | ~10-20% |

**Documentation Taxonomy:**
| Doc Type | Diagram Guidance |
|----------|------------------|
| Project Overview | Optional high-level context diagram |
| Architecture | 2-3 diagrams (system overview, request lifecycle) |
| API Reference | 1 diagram (middleware/request pipeline) |
| Data Model | 1-2 ER diagrams |
| Auth & Authorization | 1-2 sequence diagrams (login, token refresh) |
| Feature Guides | 1 flowchart per feature |
| Configuration | No diagrams by default |

**User-Added Section Modes:**
- `covers: ["path/to/file.ts"]` - Explicit file paths
- `covers: "auto"` - AI searches source index semantically
- `covers: "none"` - AI generates template for manual filling

---

## 4. Dependencies

### 4.1 Technical Dependencies
- EPIC-001: scan.sh and _manifest.json
- EPIC-002: instructions.md and platform integration
- Mermaid syntax for diagrams

### 4.2 Epic Dependencies
- Blocked by: EPIC-001, EPIC-002
- Blocks: EPIC-004 (adapters need workflows defined)

---

## 5. Linked Stories
| Story ID | Name | Points | File |
|----------|------|--------|------|
| STORY-019 | Init workflow | 3 | [STORY-019](STORY-019-init-workflow.md) |
| STORY-020 | Update workflow | 5 | [STORY-020](STORY-020-update-workflow.md) |
| STORY-021 | Three-bucket file sorting | 2 | [STORY-021](STORY-021-three-bucket-sorting.md) |
| STORY-022 | Tiered description strategy | 3 | [STORY-022](STORY-022-tiered-description.md) |
| STORY-023 | Documentation page template | 2 | [STORY-023](STORY-023-doc-page-template.md) |
| STORY-024 | Diagram guidelines | 2 | [STORY-024](STORY-024-diagram-guidelines.md) |
| STORY-025 | User-added section handling | 3 | [STORY-025](STORY-025-user-added-sections.md) |
| STORY-026 | Edit preservation | 3 | [STORY-026](STORY-026-edit-preservation.md) |
| STORY-027 | Interactive proposal format | 2 | [STORY-027](STORY-027-interactive-proposal.md) |

**Total: 25 story points**

### Implementation Order (Recommended)
1. **STORY-027** (Proposal format) - Defines user interaction
2. **STORY-019** (Init workflow) - Core first-run flow
3. **STORY-022** (Tiered description) - Token efficiency
4. **STORY-023** (Doc template) - Page structure
5. **STORY-024** (Diagram guidelines) - Visual standards
6. **STORY-021** (Three-bucket sorting) - Change detection
7. **STORY-020** (Update workflow) - Incremental updates
8. **STORY-025** (User sections) - Customization
9. **STORY-026** (Edit preservation) - User edit safety

### Key Note
Much of this logic is already drafted in `core/instructions.md`. These stories refine, validate, and test the AI-driven workflows.

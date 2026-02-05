# EPIC-001: Core Scanner & Manifest System

## Metadata
| Field | Value |
|-------|-------|
| **Status** | ✅ Complete |
| **Ambiguity Score** | 🟡 Medium |
| **Context Source** | Roadmap Phase 1 |
| **Owner** | TBD |
| **Priority** | P0 - Critical |
| **Tags** | #core, #scanner, #manifest, #bash |
| **Target Date** | TBD |

---

## 1. The Executive Pitch
> Target Audience: Stakeholders, Business Sponsors, Non-Technical Leads

### 1.1 The Problem
Documentation tools require complex dependencies and produce static output that becomes stale immediately. Developers need a way to scan codebases and track documentation state without installing runtimes.

### 1.2 The Solution
Build a pure bash scanner (`scan.sh`) that produces a structured snapshot of any codebase, and a manifest system (`_manifest.json`) that tracks documentation coverage, file hashes, and bidirectional links between source and docs.

### 1.3 The Value (North Star)
- Enable diff-aware documentation updates (only regenerate what changed)
- Provide instant project orientation for any AI tool via manifest
- Zero dependency installation (bash + POSIX only)

---

## 2. The Scope Boundaries (AI Guardrails)
> Target Audience: Planner Agent (Critical for preventing hallucinations)

### 2.1 IN-SCOPE (Build This)
- [x] `scan.sh` - Pure bash scanner using POSIX utilities (find, grep, sed, awk, shasum)
- [x] Pipe-delimited output format: `path | category | hash | docstring`
- [x] Language preset loading system (source .conf files)
- [x] TypeScript/JavaScript preset (`typescript.conf`, `javascript.conf`)
- [x] Python preset (`python.conf`)
- [x] Default fallback preset (`default.conf`)
- [x] `_manifest.json` schema implementation
- [x] Bidirectional linking (source → docs, docs → source)
- [x] SHA-256 hash computation per file (truncated)
- [x] Category assignment via DOC_SIGNALS glob matching
- [x] Docstring extraction using language-specific patterns

### 2.2 OUT-OF-SCOPE (Do NOT Build This)
- No Go/Rust/Java presets (Phase 3 - EPIC-005)
- No incremental/git-diff scanning (Phase 4 - EPIC-006)
- No multi-language project support (Phase 4 - EPIC-006)
- No AI integration - scanner is a standalone tool
- No platform-specific adapters (EPIC-002, EPIC-004)

---

## 3. Context

### 3.1 User Personas
- **Developer**: Runs scanner to get codebase snapshot for documentation
- **AI Tool**: Consumes scanner output and manifest for context

### 3.2 User Journey (Happy Path)
```mermaid
flowchart LR
    A[Run scan.sh] --> B[Load language preset]
    B --> C[Walk file tree]
    C --> D[Compute hashes & extract docstrings]
    D --> E[Output pipe-delimited format]
```

### 3.3 Technical Requirements

**Scanner Output Format:**
```
# vdoc scan output
# generated: 2026-02-05T14:30:00Z
# language: typescript
# files: 47
src/api/users.ts | api_routes | a3f2c1 | User CRUD operations
src/api/auth.ts | api_routes | b7d4e2 | JWT authentication
```

**Manifest Schema (Key Fields):**
- `project`: Project name
- `language`: Detected language
- `last_updated`: ISO timestamp
- `vdoc_version`: Tool version
- `documentation[]`: Array of doc page entries (path, title, covers, audience, description)
- `source_index{}`: Map of source files to metadata (hash, category, description, description_source, documented_in)

**Preset Variables:**
- `EXCLUDE_DIRS`: Directories to skip
- `EXCLUDE_FILES`: File patterns to skip
- `ENTRY_PATTERNS`: Likely entry point files
- `DOCSTRING_PATTERN`: Regex for docstring start
- `DOCSTRING_END`: Regex for docstring end
- `DOC_SIGNALS`: Category-to-glob mappings

---

## 4. Dependencies

### 4.1 Technical Dependencies
- Bash 4.0+
- POSIX utilities: find, grep, sed, awk, shasum
- No external dependencies

### 4.2 Epic Dependencies
- Blocked by: None (foundational epic)
- Blocks: EPIC-002, EPIC-003, EPIC-004, EPIC-005

---

## 5. Linked Stories
| Story ID | Name | Status |
|----------|------|--------|
| STORY-001 | Implement scan.sh core file walker | ✅ Complete |
| STORY-002 | Create preset loading system | ✅ Complete |
| STORY-003 | Implement TypeScript/JavaScript preset | ✅ Complete |
| STORY-004 | Implement Python preset | ✅ Complete |
| STORY-005 | Implement default fallback preset | ✅ Complete |
| STORY-006 | Add docstring extraction logic | ✅ Complete |
| STORY-007 | Add SHA-256 hash computation | ✅ Complete |
| STORY-008 | Implement DOC_SIGNALS category matching | ✅ Complete |
| STORY-009 | Define _manifest.json schema | ✅ Complete |
| STORY-010 | Implement manifest read/write utilities | ✅ Complete |

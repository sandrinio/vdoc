# EPIC-005: Language Presets Expansion

## Metadata
| Field | Value |
|-------|-------|
| **Status** | ✅ Complete |
| **Ambiguity Score** | 🟢 Low |
| **Context Source** | Roadmap Phase 3 |
| **Owner** | TBD |
| **Priority** | P2 - Medium |
| **Tags** | #presets, #go, #rust, #java, #languages |
| **Target Date** | TBD |

---

## 1. The Executive Pitch
> Target Audience: Stakeholders, Business Sponsors, Non-Technical Leads

### 1.1 The Problem
Phase 1 only supports TypeScript/JavaScript and Python. Many enterprise and systems projects use Go, Rust, or Java and cannot use vdoc without language support.

### 1.2 The Solution
Add language presets for Go, Rust, and Java. Improve docstring extraction patterns for each language. Enable custom presets via `vdocs/.vdoc/presets/` that teams can commit and share.

### 1.3 The Value (North Star)
- Support 6+ major language ecosystems
- Teams can add custom presets for proprietary frameworks
- Improved docstring extraction increases Pass A coverage (zero-token descriptions)

---

## 2. The Scope Boundaries (AI Guardrails)
> Target Audience: Planner Agent (Critical for preventing hallucinations)

### 2.1 IN-SCOPE (Build This)
- [x] Go preset (`go.conf`): go.mod detection, vendor exclusion, Go doc comments
- [x] Rust preset (`rust.conf`): Cargo.toml detection, target exclusion, /// doc comments
- [x] Java preset (`java.conf`): pom.xml/build.gradle detection, target/build exclusion, Javadoc
- [x] Improved docstring extraction patterns per language
- [x] Custom preset loading from `vdocs/.vdoc/presets/`
- [x] Preset validation (check required variables)
- [x] Update default.conf as robust fallback
- [x] Documentation for creating custom presets

### 2.2 OUT-OF-SCOPE (Do NOT Build This)
- No multi-language project support (EPIC-006)
- No community preset repository (EPIC-007)
- No automatic language detection improvements beyond file markers

---

## 3. Context

### 3.1 User Personas
- **Go Developer**: Backend services, CLI tools
- **Rust Developer**: Systems programming, performance-critical code
- **Java Developer**: Enterprise applications, Spring/Maven projects
- **Framework Author**: Custom internal framework needing specialized preset

### 3.2 User Journey (Happy Path)
```mermaid
flowchart LR
    A[Run install.sh] --> B[Detect go.mod]
    B --> C[Load go.conf preset]
    C --> D[Scanner uses Go patterns]
    D --> E[Extract Go doc comments]
```

### 3.3 Technical Requirements

**Preset Variables:**
| Variable | Go | Rust | Java |
|----------|-----|------|------|
| EXCLUDE_DIRS | vendor, bin | target, debug, release | target, build, .gradle |
| EXCLUDE_FILES | *_test.go | *.lock | *.class |
| ENTRY_PATTERNS | cmd/*, main.go | src/main.rs, src/lib.rs | src/main/java/**/Application.java |
| DOCSTRING_PATTERN | `^// ` | `^///` | `^\s*/\*\*` |
| DOCSTRING_END | (next non-comment) | (next non-///) | `\*/` |
| DOC_SIGNALS | api:api/**, handlers:handlers/** | api:src/api/**, lib:src/lib/** | controller:**/controller/**, service:**/service/** |

**Detection Files:**
| Language | Detection File |
|----------|----------------|
| Go | go.mod |
| Rust | Cargo.toml |
| Java | pom.xml OR build.gradle |

**Custom Preset Path:** `vdocs/.vdoc/presets/custom-<name>.conf`

---

## 4. Dependencies

### 4.1 Technical Dependencies
- EPIC-001: scan.sh preset loading system
- Knowledge of each language's doc comment conventions

### 4.2 Epic Dependencies
- Blocked by: EPIC-001
- Blocks: EPIC-006 (multi-language needs complete preset library)

---

## 5. Linked Stories
| Story ID | Name | Points | File |
|----------|------|--------|------|
| STORY-040 | Go language preset (incl. docstring extraction) | 3 | [STORY-040](STORY-040-go-preset.md) |
| STORY-041 | Rust language preset (incl. docstring extraction) | 3 | [STORY-041](STORY-041-rust-preset.md) |
| STORY-042 | Java language preset (incl. docstring extraction) | 3 | [STORY-042](STORY-042-java-preset.md) |
| STORY-043 | Custom preset loading | 3 | [STORY-043](STORY-043-custom-preset-loading.md) |
| STORY-044 | Preset validation | 2 | [STORY-044](STORY-044-preset-validation.md) |
| STORY-045 | Enhance default.conf fallback | 2 | [STORY-045](STORY-045-enhance-default-preset.md) |
| STORY-046 | Custom preset documentation | 2 | [STORY-046](STORY-046-preset-documentation.md) |

**Total: 18 story points**

### Implementation Order (Recommended)
1. **STORY-045** (Enhanced default) - Robust fallback first
2. **STORY-040** (Go preset) - First new language
3. **STORY-041** (Rust preset) - Second new language
4. **STORY-042** (Java preset) - Third new language
5. **STORY-043** (Custom loading) - Enable team customization
6. **STORY-044** (Validation) - Catch errors in custom presets
7. **STORY-046** (Documentation) - Explain customization

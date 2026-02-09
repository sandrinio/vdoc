# EPIC-008: Smart Feature Detection

## Metadata
| Field | Value |
|-------|-------|
| **Status** | Draft |
| **Ambiguity Score** | Medium |
| **Context Source** | Performance investigation + research on AST parsing |
| **Owner** | TBD |
| **Priority** | P1 - High |
| **Tags** | #features, #ast, #tree-sitter, #smart-detection |
| **Target Date** | TBD |

---

## 1. The Executive Pitch
> Target Audience: Stakeholders, Business Sponsors, Non-Technical Leads

### 1.1 The Problem

**Current state:** vdoc indexes files, not features.

| Current Approach | Problem |
|-----------------|---------|
| `src/auth.ts` → doc | Developers don't think in files |
| File-by-file scanning | PMs/BAs can't understand |
| Generic categories | No feature grouping |
| 35+ seconds init | Per-file subprocess overhead |

**Target users need feature-based documentation:**
- Product Managers: "What features does this app have?"
- Business Analysts: "How does Authentication work?"
- IT Team Leads: "What are the API endpoints?"
- New Developers: "Where is User Management?"

### 1.2 The Solution

Transform vdoc from **file-centric** to **feature-centric**:

```
BEFORE (file-centric):
  src/api/users.ts         → "User API file"
  src/middleware/auth.ts   → "Auth middleware file"
  src/models/User.ts       → "User model file"

AFTER (feature-centric):
  Authentication           → login(), logout(), validateJWT()
  User Management          → createUser(), getUser(), deleteUser()
  API Endpoints            → /api/users, /api/auth, /api/orders
```

### 1.3 The Value (North Star)

- **Feature discovery**: Auto-detect features from code structure
- **Business-friendly docs**: Documentation organized by capabilities
- **Smarter AI context**: AI understands features, not just files
- **Faster init**: Lightweight context instead of per-file hashing

---

## 2. The Scope Boundaries (AI Guardrails)
> Target Audience: Planner Agent (Critical for preventing hallucinations)

### 2.1 IN-SCOPE (Build This)
- [ ] Create lightweight AST parser integration (tree-sitter or regex-based)
- [ ] Extract features: functions, classes, methods, exports
- [ ] Detect API routes/endpoints from common frameworks
- [ ] Build dependency graph (what calls what)
- [ ] Group files into logical features by clustering
- [ ] New manifest schema v3 with `features` section
- [ ] Feature-based categorization (not just path-based)
- [ ] Fast init mode (file list + categories, no hashing)
- [ ] Keep backward compatibility with v2 manifest

### 2.2 OUT-OF-SCOPE (Do NOT Build This)
- No full IDE-level language server (too complex)
- No real-time file watching (future enhancement)
- No cross-repository feature detection
- No AI-powered feature naming (use code patterns only)
- No graph visualization UI (future enhancement)
- No breaking changes to adapter interface

---

## 3. Current Architecture Analysis

### 3.1 What Exists Today

```
core/scan.sh           # File walker + hash + docstring extraction
  ├── walk_files()     # git ls-files or find
  ├── compute_hash()   # SHA-256 per file (SLOW: subprocess per file)
  ├── categorize_file()# Path glob matching against DOC_SIGNALS
  └── extract_docstring() # Regex on first 50 lines

core/presets/*.conf    # Language-specific patterns
  ├── EXCLUDE_DIRS     # node_modules, dist, etc.
  ├── DOC_SIGNALS      # category:glob mappings
  └── DOCSTRING_PATTERN # Comment block regex

vdocs/_manifest.json   # File-centric index
  └── source_index: { "src/file.ts": { hash, category, description } }
```

### 3.2 Current Limitations

| Component | Limitation | Impact |
|-----------|------------|--------|
| `scan.sh` | Per-file subprocess (shasum, head) | 35+ seconds for 900 files |
| `DOC_SIGNALS` | Path-only categorization | Can't detect features inside files |
| Manifest | File paths as keys | No feature grouping |
| Docstrings | First comment block only | Misses per-function docs |

### 3.3 Files That Need Changes

| File | Change Type | Description |
|------|-------------|-------------|
| `core/scan.sh` | Major refactor | Add feature extraction layer |
| `core/presets/*.conf` | Enhancement | Add feature detection patterns |
| `core/manifest.sh` | Enhancement | Support v3 schema with features |
| `adapters/instructions.md` | Enhancement | Feature-aware update logic |
| `app/vdoc.sh` | Minor | Add `--fast` flag for init |

### 3.4 New Components Needed

| Component | Purpose | Technology |
|-----------|---------|------------|
| `core/parser.sh` | AST parsing wrapper | Calls external parser |
| `tools/parse-ast.js` | Tree-sitter integration | Node.js + web-tree-sitter |
| `core/features.sh` | Feature extraction | Bash + jq |
| `core/presets/features/*.conf` | Per-language feature rules | Config |

---

## 4. Technical Requirements

### 4.1 Feature Detection Strategies

**Strategy 1: Tree-sitter AST Parsing (Recommended)**
```
Source File → tree-sitter → AST JSON → Feature Extraction → Manifest
```
- Pros: Accurate, multi-language, battle-tested
- Cons: Requires Node.js runtime
- Speed: ~1-2ms per file

**Strategy 2: Regex-based Extraction (Fallback)**
```
Source File → grep/sed patterns → Feature List → Manifest
```
- Pros: No dependencies, pure bash
- Cons: Less accurate, language-specific patterns needed
- Speed: ~5-10ms per file

**Strategy 3: Hybrid Approach (Proposed)**
```
If Node.js available:
  Use tree-sitter for accurate parsing
Else:
  Use regex patterns for basic extraction
```

### 4.2 Feature Types to Detect

| Type | Example | Detection Method |
|------|---------|------------------|
| **Function** | `function getUserById()` | AST: function_declaration |
| **Class** | `class UserService` | AST: class_declaration |
| **Method** | `UserService.create()` | AST: method_definition |
| **API Route** | `app.get('/api/users')` | Pattern: Express/FastAPI/etc. |
| **Export** | `export { User }` | AST: export_statement |
| **Component** | `function Button()` | Pattern: React/Vue conventions |
| **Hook** | `function useAuth()` | Pattern: `use*` naming |

### 4.3 Framework-Specific Route Detection

| Framework | Pattern | Example |
|-----------|---------|---------|
| Express | `app.get/post/put/delete()` | `app.get('/users', ...)` |
| Next.js | `pages/api/*.ts` or `app/*/route.ts` | File-based routing |
| FastAPI | `@app.get()` decorator | `@app.get("/users")` |
| Flask | `@app.route()` decorator | `@app.route("/users")` |
| Go/Chi | `r.Get()`, `r.Post()` | `r.Get("/users", handler)` |

### 4.4 Manifest Schema v3

```json
{
  "manifest_version": "3.0",
  "project": "my-app",
  "language": "typescript",
  "last_updated": "2026-02-06T10:00:00Z",

  "features": {
    "Authentication": {
      "type": "feature_group",
      "files": ["src/auth/*", "src/middleware/jwt.ts"],
      "functions": ["login", "logout", "validateJWT", "refreshToken"],
      "endpoints": ["/api/auth/login", "/api/auth/logout"],
      "description": "User authentication and session management"
    },
    "User Management": {
      "type": "feature_group",
      "files": ["src/api/users.ts", "src/models/User.ts"],
      "functions": ["createUser", "getUser", "updateUser", "deleteUser"],
      "endpoints": ["/api/users", "/api/users/:id"],
      "description": "CRUD operations for user accounts"
    }
  },

  "functions": {
    "src/auth/login.ts::login": {
      "type": "function",
      "signature": "(email: string, password: string) => Promise<Token>",
      "description": "Authenticate user with email and password",
      "calls": ["validatePassword", "generateJWT"],
      "called_by": ["POST /api/auth/login"],
      "feature": "Authentication"
    }
  },

  "endpoints": {
    "POST /api/auth/login": {
      "file": "src/api/auth.ts",
      "handler": "loginHandler",
      "feature": "Authentication"
    }
  },

  "dependency_graph": {
    "src/api/users.ts": ["src/models/User.ts", "src/middleware/auth.ts"],
    "src/middleware/auth.ts": ["src/utils/jwt.ts"]
  },

  "source_index": { ... },  // Keep for backward compat
  "quality": { ... }
}
```

### 4.5 Performance Targets

| Metric | Current | Target |
|--------|---------|--------|
| Init (900 files) | 35+ seconds | < 3 seconds |
| Incremental scan | 5-10 seconds | < 1 second |
| Feature extraction | N/A | < 2 seconds |
| Memory usage | Low | Low (streaming) |

---

## 5. Dependencies

### 5.1 Technical Dependencies
- Node.js 18+ (optional, for tree-sitter)
- jq (for JSON processing)
- Bash 3.2+ (macOS default)

### 5.2 Epic Dependencies
- Depends on: EPIC-001 through EPIC-007 (all complete)
- Blocks: Future EPIC for documentation generation

---

## 6. Linked Stories

| Story ID | Name | Status | Complexity |
|----------|------|--------|------------|
| STORY-080 | Create tree-sitter parser integration | Draft | High |
| STORY-081 | Implement function extraction for TypeScript | Draft | Medium |
| STORY-082 | Implement API route detection | Draft | Medium |
| STORY-083 | Build dependency graph | Draft | High |
| STORY-084 | Feature clustering algorithm | Draft | Medium |
| STORY-085 | Manifest schema v3 | Draft | Medium |
| STORY-086 | Fast init mode (skip hashing) | Draft | Low |
| STORY-087 | Multi-language feature extraction | Draft | High |
| STORY-088 | Update instructions.md for features | Draft | Medium |
| STORY-089 | Update README & GitHub documentation | Draft | Low |

---

## 7. Implementation Phases

### Phase 1: Fast Init (Quick Win)
**Goal:** Make `vdoc init` instant by skipping per-file processing

- STORY-086: Skip hashing, just list files + basic categories
- Result: Init drops from 35s to < 1s

### Phase 2: Feature Extraction Foundation
**Goal:** Extract functions/classes from TypeScript

- STORY-080: Tree-sitter integration (or regex fallback)
- STORY-081: TypeScript function/class extraction
- Result: Manifest includes function list per file

### Phase 3: Smart Detection
**Goal:** Detect API routes and group into features

- STORY-082: Framework-specific route detection
- STORY-084: Feature clustering (group related files)
- STORY-085: Manifest v3 schema
- Result: Manifest has `features` section

### Phase 4: Dependency Graph
**Goal:** Understand what calls what

- STORY-083: Import/export analysis
- STORY-087: Multi-language support
- Result: Full dependency graph in manifest

### Phase 5: AI Integration & Documentation
**Goal:** AI generates feature-based docs, users understand the tool

- STORY-088: Update instructions.md
- STORY-089: Update README & GitHub documentation
- Result: AI creates docs like `authentication.md`, not `auth-ts.md`
- Result: GitHub README clearly explains value, installation, security

---

## 8. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Tree-sitter requires Node.js | Adds dependency | Provide regex fallback |
| Framework detection varies | May miss routes | Document supported frameworks |
| Dependency resolution is hard | Wrong call graphs | Start simple, iterate |
| Large codebases slow | Poor UX | Cache AST, incremental parse |

---

## 9. Success Criteria

1. `vdoc init` completes in < 3 seconds
2. Manifest contains feature groups, not just files
3. API endpoints are auto-detected
4. AI generates feature-based documentation
5. Backward compatible with existing manifests

---

## 10. Research References

- [Aider Repo Map](https://aider.chat/2023/10/22/repomap.html) - Tree-sitter for code structure
- [Tree-sitter Tutorial](https://journal.hexmos.com/tree-sitter-tutorial/)
- [AST Route Extraction](https://singhsaksham.medium.com/how-to-extract-api-routes-using-javascript-babel-parser-and-ast-a-step-by-step-guide-ce846c5e590c)
- [Code Intelligence Resources](https://github.com/CGCL-codes/awesome-code-intelligence)

# STORY-040: Create Go Language Preset

## Metadata
| Field | Value |
|-------|-------|
| **Status** | ✅ Complete |
| **Story Points** | 3 |
| **Priority** | P1 - High |
| **Parent Epic** | EPIC-005 |

---

## User Story
**As a** Go developer using vdoc
**I want** automatic detection and scanning of my Go project
**So that** I get properly categorized documentation without manual configuration

---

## Acceptance Criteria

### AC1: Language detection
- [ ] Detect Go projects via `go.mod` file
- [ ] Fall back to `*.go` files if no go.mod
- [ ] Set preset name to "go"

### AC2: Directory exclusions
- [ ] Exclude `vendor/` directory
- [ ] Exclude `bin/`, `pkg/` directories
- [ ] Exclude `testdata/` directories
- [ ] Exclude `.go/` cache directory

### AC3: File exclusions
- [ ] Exclude `*_test.go` files
- [ ] Exclude `*_mock.go` files
- [ ] Exclude generated files (`*.pb.go`, `*_gen.go`)

### AC4: Entry point detection
- [ ] Detect `cmd/*/main.go` patterns
- [ ] Detect `main.go` in root
- [ ] Detect `cmd/main.go`

### AC5: Go doc comment extraction
- [ ] Extract `// Package ...` comments
- [ ] Extract `// FuncName ...` comments (function docs)
- [ ] Handle multi-line `//` comments
- [ ] Pattern: `^//\s*` (single-line comments)

### AC6: Category signals
- [ ] `api`: `api/**`, `handlers/**`, `http/**`
- [ ] `services`: `internal/services/**`, `pkg/services/**`
- [ ] `models`: `models/**`, `internal/models/**`, `pkg/models/**`
- [ ] `middleware`: `middleware/**`, `internal/middleware/**`
- [ ] `config`: `config/**`, `internal/config/**`
- [ ] `cmd`: `cmd/**`

---

## Technical Notes

**Preset File: `core/presets/go.conf`**
```bash
# vdoc Language Preset: Go
# Detection: go.mod

PRESET_NAME="go"
PRESET_VERSION="1.0.0"

# Directories to exclude from scanning
EXCLUDE_DIRS="vendor bin pkg testdata .go"

# File patterns to exclude
EXCLUDE_FILES="*_test.go *_mock.go *.pb.go *_gen.go *_string.go"

# Likely entry point files
ENTRY_PATTERNS="cmd/*/main.go cmd/main.go main.go"

# Go doc comments (// style)
DOCSTRING_PATTERN='^//\s*'
DOCSTRING_END=''  # Single line, no end marker

# Alternative: Extract package doc from first comment block
PACKAGE_DOC_PATTERN='^// Package'

# Category signals
DOC_SIGNALS="
api:api/**
api:handlers/**
api:http/**
api:internal/api/**
api:internal/handlers/**
services:services/**
services:internal/services/**
services:pkg/services/**
models:models/**
models:internal/models/**
models:pkg/models/**
middleware:middleware/**
middleware:internal/middleware/**
config:config/**
config:internal/config/**
cmd:cmd/**
utils:utils/**
utils:internal/utils/**
utils:pkg/utils/**
"
```

**Go Doc Comment Extraction:**
```bash
# Extract first // comment block before package/func declaration
extract_go_docstring() {
    local file="$1"
    # Get first comment block (consecutive // lines)
    awk '/^\/\// { doc = doc $0 "\n"; next } 
         doc && /^(package|func|type|var|const)/ { 
             gsub(/^\/\/\s*/, "", doc); 
             print doc; 
             exit 
         }
         doc { doc = "" }' "$file" | head -1
}
```

**Example Go File:**
```go
// Package users provides user management functionality.
// It handles CRUD operations for user accounts.
package users

// CreateUser creates a new user with the given details.
// Returns the created user or an error if validation fails.
func CreateUser(name, email string) (*User, error) {
    // ...
}
```

Expected extraction: `"Package users provides user management functionality."`

---

## Definition of Done
- [ ] `go.conf` preset created in `core/presets/`
- [ ] Go projects detected via go.mod
- [ ] Vendor and test files excluded
- [ ] Go doc comments extracted correctly
- [ ] Categories map to appropriate doc pages
- [ ] Tested with sample Go project

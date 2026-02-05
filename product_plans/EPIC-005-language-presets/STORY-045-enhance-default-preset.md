# STORY-045: Enhance Default Preset Fallback

## Metadata
| Field | Value |
|-------|-------|
| **Status** | ✅ Complete |
| **Story Points** | 2 |
| **Priority** | P2 - Medium |
| **Parent Epic** | EPIC-005 |

---

## User Story
**As a** developer with an unsupported language
**I want** the default preset to work reasonably well
**So that** I get useful documentation even without a specific preset

---

## Acceptance Criteria

### AC1: Comprehensive exclusions
- [ ] Include exclusions from all language presets
- [ ] Cover common build/cache directories
- [ ] Cover common IDE directories
- [ ] Cover common dependency directories

### AC2: Universal docstring patterns
- [ ] Support C-style `/** */` comments
- [ ] Support `#` comment blocks (shell, Python, Ruby)
- [ ] Support `///` doc comments (Rust, C#)
- [ ] Support `//` comment blocks (Go, C++)

### AC3: Generic category signals
- [ ] Map common directory patterns to categories
- [ ] Support multiple naming conventions
- [ ] Avoid language-specific assumptions

### AC4: Graceful degradation
- [ ] Work without any language markers
- [ ] Scan all source files by extension
- [ ] Provide meaningful output for unknown projects

### AC5: Entry point heuristics
- [ ] Detect common entry file names
- [ ] Support main.*, index.*, app.* patterns
- [ ] Check for README for project context

---

## Technical Notes

**Enhanced Default Preset:**
```bash
# vdoc Language Preset: Default (Universal Fallback)
# Used when no specific language is detected

PRESET_NAME="default"
PRESET_VERSION="2.0.0"

# =============================================================================
# EXCLUSIONS - Union of all language-specific exclusions
# =============================================================================

# Build output directories
BUILD_DIRS="dist build out target bin obj release debug .output"

# Dependency directories
DEPS_DIRS="node_modules vendor .venv venv env .env packages .packages"

# Cache directories
CACHE_DIRS=".cache .turbo .next .nuxt .gradle .cargo .go __pycache__ .pytest_cache .mypy_cache .ruff_cache"

# IDE directories
IDE_DIRS=".idea .vscode .settings .vs .fleet"

# Version control
VCS_DIRS=".git .svn .hg"

# Combined exclusions
EXCLUDE_DIRS="$BUILD_DIRS $DEPS_DIRS $CACHE_DIRS $IDE_DIRS $VCS_DIRS coverage"

# File exclusions (combined from all languages)
EXCLUDE_FILES="*.log *.lock *.min.* *.map *.bak *.swp *~ .DS_Store Thumbs.db"
EXCLUDE_FILES="$EXCLUDE_FILES *.pyc *.pyo *.class *.o *.so *.exe *.dll *.dylib"
EXCLUDE_FILES="$EXCLUDE_FILES *.d.ts *.js.map *.css.map *.pb.go *_gen.go *_test.go"

# =============================================================================
# ENTRY POINTS - Universal patterns
# =============================================================================

ENTRY_PATTERNS="main.* index.* app.* src/main.* src/index.* src/app.*"
ENTRY_PATTERNS="$ENTRY_PATTERNS cmd/main.* Application.* Program.*"

# =============================================================================
# DOCSTRING PATTERNS - Support multiple styles
# =============================================================================

# Primary: C-style block comments (Java, JS, TS, C, C++, Go, Rust)
DOCSTRING_PATTERN='^\s*/\*\*'
DOCSTRING_END='\*/'

# Alternative patterns (checked if primary fails)
ALT_DOCSTRING_PATTERNS=(
    '^///\s*'           # Rust, C# doc comments
    '^//\s*'            # Go doc comments
    '^#\s*'             # Python, Ruby, Shell
    '^"""\s*'           # Python docstrings
    "^'''\s*"           # Python docstrings (alt)
)

# =============================================================================
# CATEGORY SIGNALS - Generic patterns
# =============================================================================

DOC_SIGNALS="
# API/Routes (multiple conventions)
api:**/api/**
api:**/routes/**
api:**/handlers/**
api:**/endpoints/**
api:**/controllers/**
api:**/controller/**
api:**/rest/**

# Models/Data (multiple conventions)
models:**/models/**
models:**/model/**
models:**/entities/**
models:**/entity/**
models:**/schemas/**
models:**/schema/**
models:**/types/**
models:**/dto/**
models:**/domain/**

# Services (multiple conventions)
services:**/services/**
services:**/service/**

# Utilities (multiple conventions)
utils:**/utils/**
utils:**/util/**
utils:**/helpers/**
utils:**/helper/**
utils:**/common/**
utils:**/lib/**
utils:**/shared/**

# Configuration (multiple conventions)
config:**/config/**
config:**/configuration/**
config:**/settings/**
config:*.config.*

# Middleware
middleware:**/middleware/**
middleware:**/middlewares/**
middleware:**/filters/**
middleware:**/interceptors/**

# Components (frontend)
components:**/components/**
components:**/component/**

# Views/Pages
views:**/views/**
views:**/pages/**
views:**/templates/**

# Repository/Data Access
repository:**/repository/**
repository:**/repositories/**
repository:**/dao/**

# Tests (to skip)
tests:**/tests/**
tests:**/test/**
tests:**/__tests__/**
tests:**/spec/**
tests:**/specs/**

# Source root
src:src/**
"
```

**Multi-Pattern Docstring Extraction:**
```bash
extract_docstring() {
    local file="$1"
    local ext="${file##*.}"
    local doc=""
    
    # Try C-style first (most common)
    doc=$(awk '
        /\/\*\*/ { in_doc=1; doc=""; next }
        in_doc && /\*\// { in_doc=0; print doc; exit }
        in_doc { gsub(/^\s*\*\s?/, ""); doc = doc $0 " " }
    ' "$file")
    
    [[ -n "$doc" ]] && echo "$doc" && return
    
    # Try /// style (Rust, C#)
    doc=$(awk '
        /^\/\/\// { gsub(/^\/\/\/\s*/, ""); doc = doc $0 " "; next }
        doc && !/^\/\/\// { print doc; exit }
    ' "$file")
    
    [[ -n "$doc" ]] && echo "$doc" && return
    
    # Try // style (Go)
    doc=$(awk '
        /^\/\// { gsub(/^\/\/\s*/, ""); doc = doc $0 " "; next }
        doc && !/^\/\// { print doc; exit }
    ' "$file")
    
    [[ -n "$doc" ]] && echo "$doc" && return
    
    # Try # style (Python, Ruby, Shell)
    doc=$(awk '
        NR==1 && /^#!/ { next }  # Skip shebang
        /^#/ { gsub(/^#\s*/, ""); doc = doc $0 " "; next }
        doc && !/^#/ { print doc; exit }
    ' "$file")
    
    [[ -n "$doc" ]] && echo "$doc" && return
    
    echo ""  # No docstring found
}
```

---

## Definition of Done
- [ ] default.conf includes all language exclusions
- [ ] Multiple docstring patterns supported
- [ ] Generic category signals comprehensive
- [ ] Unknown projects still scan successfully
- [ ] Tested with mixed/unknown project types

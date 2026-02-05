# STORY-041: Create Rust Language Preset

## Metadata
| Field | Value |
|-------|-------|
| **Status** | ✅ Complete |
| **Story Points** | 3 |
| **Priority** | P1 - High |
| **Parent Epic** | EPIC-005 |

---

## User Story
**As a** Rust developer using vdoc
**I want** automatic detection and scanning of my Rust project
**So that** I get properly categorized documentation without manual configuration

---

## Acceptance Criteria

### AC1: Language detection
- [ ] Detect Rust projects via `Cargo.toml` file
- [ ] Fall back to `*.rs` files if no Cargo.toml
- [ ] Set preset name to "rust"

### AC2: Directory exclusions
- [ ] Exclude `target/` directory (build output)
- [ ] Exclude `debug/`, `release/` directories
- [ ] Exclude `.cargo/` cache directory

### AC3: File exclusions
- [ ] Exclude `*.lock` files
- [ ] Exclude generated files in `target/`

### AC4: Entry point detection
- [ ] Detect `src/main.rs` (binary crate)
- [ ] Detect `src/lib.rs` (library crate)
- [ ] Detect `src/bin/*.rs` (multiple binaries)

### AC5: Rust doc comment extraction
- [ ] Extract `///` documentation comments
- [ ] Extract `//!` module-level docs
- [ ] Handle multi-line `///` blocks
- [ ] Patterns: `^///` and `^//!`

### AC6: Category signals
- [ ] `api`: `src/api/**`, `src/handlers/**`
- [ ] `lib`: `src/lib.rs`, `src/lib/**`
- [ ] `models`: `src/models/**`, `src/types/**`
- [ ] `utils`: `src/utils/**`, `src/helpers/**`
- [ ] `config`: `src/config/**`
- [ ] `bin`: `src/bin/**`, `src/main.rs`

---

## Technical Notes

**Preset File: `core/presets/rust.conf`**
```bash
# vdoc Language Preset: Rust
# Detection: Cargo.toml

PRESET_NAME="rust"
PRESET_VERSION="1.0.0"

# Directories to exclude from scanning
EXCLUDE_DIRS="target debug release .cargo"

# File patterns to exclude
EXCLUDE_FILES="*.lock"

# Likely entry point files
ENTRY_PATTERNS="src/main.rs src/lib.rs src/bin/*.rs"

# Rust doc comments (/// and //!)
DOCSTRING_PATTERN='^///\s*'
MODULE_DOC_PATTERN='^//!\s*'
DOCSTRING_END=''  # Single line style

# Category signals
DOC_SIGNALS="
api:src/api/**
api:src/handlers/**
api:src/routes/**
lib:src/lib.rs
lib:src/lib/**
models:src/models/**
models:src/types/**
models:src/entities/**
utils:src/utils/**
utils:src/helpers/**
utils:src/common/**
config:src/config/**
config:src/settings/**
middleware:src/middleware/**
bin:src/bin/**
tests:tests/**
benches:benches/**
"
```

**Rust Doc Comment Extraction:**
```bash
# Extract /// doc comments before item declaration
extract_rust_docstring() {
    local file="$1"
    # Get first /// comment block
    awk '/^\/\/\// { 
             gsub(/^\/\/\/\s*/, ""); 
             doc = doc $0 " "; 
             next 
         }
         /^\/\/!/ { 
             gsub(/^\/\/!\s*/, ""); 
             doc = doc $0 " "; 
             next 
         }
         doc && /^(pub |fn |struct |enum |trait |mod |type |const |static )/ { 
             print doc; 
             exit 
         }
         doc && !/^\/\// { doc = "" }' "$file" | head -1
}
```

**Example Rust File:**
```rust
//! This module provides user management functionality.
//! It handles CRUD operations for user accounts.

/// Creates a new user with the given details.
/// 
/// # Arguments
/// * `name` - The user's display name
/// * `email` - The user's email address
/// 
/// # Returns
/// A `Result` containing the new `User` or an error.
pub fn create_user(name: &str, email: &str) -> Result<User, Error> {
    // ...
}
```

Expected extraction: `"Creates a new user with the given details."`

---

## Definition of Done
- [ ] `rust.conf` preset created in `core/presets/`
- [ ] Rust projects detected via Cargo.toml
- [ ] Target directory excluded
- [ ] Rust doc comments (/// and //!) extracted correctly
- [ ] Categories map to appropriate doc pages
- [ ] Tested with sample Rust project

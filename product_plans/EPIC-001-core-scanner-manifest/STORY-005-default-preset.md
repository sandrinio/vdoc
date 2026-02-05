# STORY-005: Implement Default Fallback Preset

## Metadata
| Field | Value |
|-------|-------|
| **Parent Epic** | [EPIC-001](EPIC.md) |
| **Status** | ✅ Complete |
| **Ambiguity Score** | 🟢 Low |
| **Actor** | Scanner |
| **Complexity** | Small (1 file, already exists) |

---

## 1. The Spec (The Contract)

### 1.1 User Story
> As a **Developer using an unsupported language**,  
> I want **the scanner to still work with sensible defaults**,  
> So that **I can generate documentation for any project**.

### 1.2 Detailed Requirements
- [ ] Exclude common directories: .git, node_modules, vendor, dist, build, target
- [ ] Exclude common file patterns: *.log, *.lock, *.min.*, *.map
- [ ] Use C-style block comment pattern (/* ... */) as default
- [ ] Provide generic category signals for common structures
- [ ] Work as fallback when no specific preset matches

---

## 2. The Truth (Executable Tests)

### 2.1 Acceptance Criteria (Gherkin)
```gherkin
Feature: Default Preset

  Scenario: Excludes .git directory
    Given default.conf is loaded
    Then EXCLUDE_DIRS contains ".git"

  Scenario: Excludes vendor directories
    Given default.conf is loaded
    Then EXCLUDE_DIRS contains "vendor"

  Scenario: Generic API category
    Given file path is "src/api/handler.go"
    When categorize_file is called
    Then category is "api"

  Scenario: Falls back when no language detected
    Given no tsconfig.json, requirements.txt, etc.
    When detect_language is called
    Then result is "default"
    And default.conf is loaded
```

---

## 3. Technical Context (For Coder Agent)

### 3.1 Affected Files
- `core/presets/default.conf` - Already exists, verify completeness

### 3.2 Default Preset (Verify/Update)
```bash
# vdoc Language Preset: Default (Fallback)
# Used when no specific language is detected

PRESET_NAME="default"
PRESET_VERSION="1.0.0"

# Common directories to exclude (union of all languages)
EXCLUDE_DIRS=".git .svn .hg node_modules vendor dist build target bin obj .cache .idea .vscode __pycache__ .pytest_cache .mypy_cache coverage .next .nuxt .output"

# Common file patterns to exclude
EXCLUDE_FILES="*.log *.lock *.min.* *.map *.bak *.swp *~ .DS_Store Thumbs.db *.pyc *.class *.o *.so"

# Generic entry point patterns
ENTRY_PATTERNS="main.* index.* app.* src/main.* src/index.* src/app.*"

# C-style block comment (works for many languages)
DOCSTRING_PATTERN='^\s*/\*\*'
DOCSTRING_END='\*/'

# Generic category signals
DOC_SIGNALS="
api:**/api/**
api:**/routes/**
api:**/handlers/**
api:**/endpoints/**
models:**/models/**
models:**/entities/**
models:**/schemas/**
utils:**/utils/**
utils:**/helpers/**
utils:**/common/**
utils:**/lib/**
config:**/config/**
config:**/settings/**
services:**/services/**
tests:**/tests/**
tests:**/test/**
src:src/**
"
```

---

## 4. Notes
- Default preset should be comprehensive but not overly restrictive
- C-style comments (/* */) work for C, C++, Java, JavaScript, Go, Rust, etc.
- Generic categories should match common project structures
- Acts as safety net - any project should produce some output

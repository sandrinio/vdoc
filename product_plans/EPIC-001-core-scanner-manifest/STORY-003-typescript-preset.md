# STORY-003: Implement TypeScript/JavaScript Preset

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
> As a **TypeScript/JavaScript Developer**,  
> I want **the scanner to understand my project structure**,  
> So that **it correctly categorizes files and extracts JSDoc comments**.

### 1.2 Detailed Requirements
- [ ] Exclude node_modules, dist, build, .next, coverage
- [ ] Exclude *.min.js, *.bundle.js, *.map, *.lock, *.d.ts
- [ ] Identify entry points: src/index.*, src/app.*, pages/_app.*
- [ ] Extract JSDoc comments (/** ... */)
- [ ] Categorize files via DOC_SIGNALS:
  - api_routes: src/api/**, pages/api/**, app/api/**
  - components: src/components/**, components/**
  - hooks: src/hooks/**, hooks/**
  - utils: src/utils/**, src/lib/**
  - middleware: src/middleware/**, middleware/**
  - types: src/types/**, types/**
  - config: *.config.*, src/config/**

---

## 2. The Truth (Executable Tests)

### 2.1 Acceptance Criteria (Gherkin)
```gherkin
Feature: TypeScript Preset

  Scenario: Excludes node_modules
    Given typescript.conf is loaded
    Then EXCLUDE_DIRS contains "node_modules"

  Scenario: Excludes minified files
    Given typescript.conf is loaded
    Then EXCLUDE_FILES contains "*.min.js"

  Scenario: Categorizes API routes
    Given file path is "src/api/users.ts"
    When categorize_file is called
    Then category is "api_routes"

  Scenario: Categorizes components
    Given file path is "src/components/Button.tsx"
    When categorize_file is called
    Then category is "components"

  Scenario: JSDoc pattern matches
    Given DOCSTRING_PATTERN from typescript.conf
    And file contains "/** User service */"
    When extract_docstring is called
    Then result is "User service"
```

---

## 3. Technical Context (For Coder Agent)

### 3.1 Affected Files
- `core/presets/typescript.conf` - Already exists, verify completeness
- `core/presets/javascript.conf` - Create (similar to TypeScript)

### 3.2 TypeScript Preset (Verify/Update)
```bash
# vdoc Language Preset: TypeScript
# Detection: tsconfig.json

PRESET_NAME="typescript"
PRESET_VERSION="1.0.0"

# Directories to exclude
EXCLUDE_DIRS="node_modules dist build .next .turbo coverage .cache out .output"

# File patterns to exclude
EXCLUDE_FILES="*.min.js *.bundle.js *.map *.lock *.d.ts *.test.ts *.spec.ts"

# Entry point patterns
ENTRY_PATTERNS="src/index.* src/main.* src/app.* pages/_app.* app/layout.* index.*"

# JSDoc pattern
DOCSTRING_PATTERN='^\s*/\*\*'
DOCSTRING_END='\*/'

# Category signals
DOC_SIGNALS="
api_routes:src/api/**
api_routes:pages/api/**
api_routes:app/api/**
components:src/components/**
components:components/**
hooks:src/hooks/**
hooks:hooks/**
utils:src/utils/**
utils:src/lib/**
utils:lib/**
middleware:src/middleware/**
middleware:middleware/**
types:src/types/**
types:types/**
config:*.config.*
config:src/config/**
config:config/**
services:src/services/**
services:services/**
"
```

### 3.3 JavaScript Preset
```bash
# vdoc Language Preset: JavaScript
# Detection: package.json (without tsconfig.json)

PRESET_NAME="javascript"
PRESET_VERSION="1.0.0"

# Same as TypeScript
EXCLUDE_DIRS="node_modules dist build .next coverage .cache"
EXCLUDE_FILES="*.min.js *.bundle.js *.map *.lock"
ENTRY_PATTERNS="src/index.js src/main.js src/app.js index.js"
DOCSTRING_PATTERN='^\s*/\*\*'
DOCSTRING_END='\*/'

# Category signals (same as TypeScript)
DOC_SIGNALS="
api_routes:src/api/**
api_routes:pages/api/**
components:src/components/**
hooks:src/hooks/**
utils:src/utils/**
utils:src/lib/**
config:*.config.*
"
```

---

## 4. Notes
- TypeScript preset already exists - verify and enhance
- JavaScript preset is nearly identical, just different file extensions
- DOC_SIGNALS use glob patterns matched against file paths
- Multiple patterns can map to same category

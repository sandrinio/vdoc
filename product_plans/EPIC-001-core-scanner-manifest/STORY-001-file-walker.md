# STORY-001: Implement scan.sh Core File Walker

## Metadata
| Field | Value |
|-------|-------|
| **Parent Epic** | [EPIC-001](EPIC.md) |
| **Status** | ✅ Complete |
| **Ambiguity Score** | 🟢 Low |
| **Actor** | Developer / AI Tool |
| **Complexity** | Medium (1 file, core logic) |

---

## 1. The Spec (The Contract)

### 1.1 User Story
> As a **Developer**,  
> I want to **run scan.sh to get a snapshot of my codebase**,  
> So that **AI tools can understand my project structure**.

### 1.2 Detailed Requirements
- [ ] Walk directory tree starting from current directory
- [ ] Apply EXCLUDE_DIRS filter (skip node_modules, dist, etc.)
- [ ] Apply EXCLUDE_FILES filter (skip *.min.js, *.lock, etc.)
- [ ] Collect all matching source files
- [ ] Output header with metadata (timestamp, language, file count)
- [ ] Output one line per file in pipe-delimited format
- [ ] Exit with code 0 on success, non-zero on error
- [ ] Validate running from project root (vdocs/.vdoc/ should exist or warn)

---

## 2. The Truth (Executable Tests)

### 2.1 Acceptance Criteria (Gherkin)
```gherkin
Feature: Core File Walker

  Scenario: Scan TypeScript project
    Given a directory with tsconfig.json
    And src/ contains .ts files
    And node_modules/ exists
    When scan.sh is run
    Then output starts with "# vdoc scan output"
    And output contains "# language: typescript"
    And output contains src/*.ts files
    And output does NOT contain node_modules/

  Scenario: Scan empty directory
    Given a directory with no source files
    When scan.sh is run
    Then output contains "# files: 0"
    And exit code is 0

  Scenario: Respects EXCLUDE_DIRS
    Given EXCLUDE_DIRS contains "dist"
    And dist/ contains files
    When scan.sh is run
    Then output does NOT contain dist/

  Scenario: Respects EXCLUDE_FILES
    Given EXCLUDE_FILES contains "*.min.js"
    And src/bundle.min.js exists
    When scan.sh is run
    Then output does NOT contain bundle.min.js
```

---

## 3. Technical Context (For Coder Agent)

### 3.1 Affected Files
- `core/scan.sh` - Main implementation

### 3.2 Implementation
```bash
#!/usr/bin/env bash
set -euo pipefail

VDOC_VERSION="2.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load preset (implemented in STORY-002)
load_preset() { ... }

# Build find exclusion arguments
build_find_excludes() {
    local excludes=""
    for dir in $EXCLUDE_DIRS; do
        excludes="$excludes -path '*/$dir' -prune -o"
    done
    echo "$excludes"
}

# Build file pattern filter
build_file_filter() {
    local filter=""
    for pattern in $EXCLUDE_FILES; do
        filter="$filter ! -name '$pattern'"
    done
    echo "$filter"
}

# Main file walker
walk_files() {
    local exclude_args
    exclude_args=$(build_find_excludes)
    
    # Find all files, excluding directories
    eval "find . $exclude_args -type f -print" | \
        while read -r file; do
            # Skip excluded file patterns
            local name=$(basename "$file")
            local skip=false
            for pattern in $EXCLUDE_FILES; do
                if [[ "$name" == $pattern ]]; then
                    skip=true
                    break
                fi
            done
            $skip || echo "$file"
        done
}

# Output header
print_header() {
    local file_count="$1"
    echo "# vdoc scan output"
    echo "# generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "# language: ${PRESET_NAME:-unknown}"
    echo "# files: $file_count"
}

main() {
    load_preset
    
    local files
    files=$(walk_files)
    local count=$(echo "$files" | grep -c . || echo 0)
    
    print_header "$count"
    
    # Process each file (hash, category, docstring in other stories)
    echo "$files" | while read -r file; do
        # Placeholder: path | category | hash | docstring
        echo "${file#./} | unknown | 000000 | "
    done
}

main "$@"
```

### 3.3 Output Format
```
# vdoc scan output
# generated: 2026-02-05T14:30:00Z
# language: typescript
# files: 47
src/index.ts | unknown | 000000 | 
src/api/users.ts | unknown | 000000 | 
```

---

## 4. Notes
- Uses `find` with `-prune` for efficient directory exclusion
- File patterns use bash glob matching
- Output is deterministic (sorted) for diffing
- Path is relative to project root (strips ./ prefix)

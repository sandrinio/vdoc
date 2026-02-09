# STORY-086: Fast Init Mode (Skip Hashing)

## Metadata
| Field | Value |
|-------|-------|
| **Parent Epic** | [EPIC-008](EPIC.md) |
| **Status** | Draft |
| **Ambiguity Score** | Low |
| **Actor** | Developer |
| **Complexity** | Low |
| **Priority** | P0 - Critical (Quick Win) |

---

## 1. The Spec (The Contract)

### 1.1 User Story
> As a **Developer**,
> I want `vdoc init` to complete instantly,
> So that **I don't wait 35+ seconds to start using vdoc**.

### 1.2 Problem Analysis

**Current flow (SLOW):**
```
vdoc init:
  1. git ls-files         → 0.1s
  2. FOR EACH FILE:       → 35+ seconds total
     - shasum -a 256      → subprocess
     - head -50           → subprocess
     - categorize         → bash
  3. Write manifest       → 0.1s
```

**Root cause:** 921 files × 3 subprocesses = ~2,700 process spawns

### 1.3 Detailed Requirements
- [ ] Add `--fast` flag to `vdoc init` (default for init)
- [ ] Skip `compute_hash()` during fast init
- [ ] Skip `extract_docstring()` during fast init
- [ ] Only collect: file list + basic category (path-based)
- [ ] Manifest has `hash: null` for unprocessed files
- [ ] Full scan available via `vdoc scan --full`

---

## 2. The Truth (Executable Tests)

### 2.1 Acceptance Criteria (Gherkin)
```gherkin
Feature: Fast Init Mode

  Scenario: Init completes quickly
    Given a project with 900+ files
    When vdoc init is run
    Then init completes in under 3 seconds
    And manifest contains file list
    And files have hash: null

  Scenario: Full scan still works
    Given vdoc is initialized
    When vdoc scan --full is run
    Then all files are hashed
    And manifest has actual hash values

  Scenario: Incremental works after full scan
    Given vdoc has run full scan
    When a file changes
    And vdoc scan is run
    Then only changed file is re-hashed
```

---

## 3. Technical Context (For Coder Agent)

### 3.1 Affected Files
- `core/scan.sh` - Add FAST_MODE option
- `app/vdoc.sh` - Pass --fast to scan during init

### 3.2 Implementation

**scan.sh changes:**
```bash
# Add option
FAST_MODE=false

# In argument parsing
--fast)
    FAST_MODE=true
    shift
    ;;

# In process_file()
process_file() {
    local file="$1"

    if $FAST_MODE; then
        # Fast mode: category only, no hash/docstring
        local category
        category=$(categorize_file "$file")
        echo "$file | $category | null | "
        return
    fi

    # Normal mode: full processing
    local hash=$(compute_hash "$file")
    local category=$(categorize_file "$file")
    local docstring=$(extract_docstring "$file")
    echo "$file | $category | $hash | $docstring"
}
```

**vdoc.sh changes:**
```bash
cmd_init() {
    # ...
    # Run fast scan by default
    if bash "${VDOC_DIR}/core/scan.sh" -m -q --fast >/dev/null 2>&1; then
        log_success "Generated _manifest.json"
    fi
}
```

### 3.3 Manifest Output (Fast Mode)

```json
{
  "source_index": {
    "src/auth.ts": {
      "hash": null,
      "category": "api",
      "description": "",
      "description_source": "pending"
    }
  }
}
```

### 3.4 Performance Target

| Mode | 900 files | Process |
|------|-----------|---------|
| Current | 35+ seconds | shasum + head per file |
| Fast | < 1 second | git ls-files + categorize |
| Full | 35+ seconds | Same as current |

---

## 4. Notes

- This is a quick win that doesn't require tree-sitter
- Unblocks users immediately
- Full hashing still available for change detection
- Phase 2 stories will add smart feature detection

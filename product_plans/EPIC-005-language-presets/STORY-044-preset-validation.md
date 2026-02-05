# STORY-044: Add Preset Validation

## Metadata
| Field | Value |
|-------|-------|
| **Status** | ✅ Complete |
| **Story Points** | 2 |
| **Priority** | P2 - Medium |
| **Parent Epic** | EPIC-005 |

---

## User Story
**As a** developer creating custom presets
**I want** validation of my preset configuration
**So that** I catch errors before running the scanner

---

## Acceptance Criteria

### AC1: Required variable validation
- [ ] Check `PRESET_NAME` is defined
- [ ] Check `PRESET_VERSION` is defined
- [ ] Warn if `EXCLUDE_DIRS` is empty
- [ ] Warn if `DOC_SIGNALS` is empty

### AC2: Syntax validation
- [ ] Validate DOC_SIGNALS format: `category:pattern`
- [ ] Check for invalid glob patterns
- [ ] Validate regex patterns compile (DOCSTRING_PATTERN)

### AC3: Path validation
- [ ] Warn if ENTRY_PATTERNS match no files
- [ ] Warn if DOC_SIGNALS patterns match no files
- [ ] Suggest corrections for common typos

### AC4: Validation command
- [ ] `scan.sh --validate-preset <name>`
- [ ] Return non-zero exit code on errors
- [ ] Output detailed validation report

### AC5: Auto-validation on load
- [ ] Validate preset when loading
- [ ] Show warnings but continue if non-fatal
- [ ] Abort with clear message if fatal error

---

## Technical Notes

**Validation Command:**
```bash
./vdocs/.vdoc/scan.sh --validate-preset custom-nextjs
```

**Expected Output:**
```
Validating preset: custom-nextjs

✓ PRESET_NAME: "custom-nextjs"
✓ PRESET_VERSION: "1.0.0"
✓ EXTENDS: "typescript" (found)

Checking EXCLUDE_DIRS...
✓ node_modules (commonly excluded)
✓ .next (Next.js build output)
⚠ Warning: 'dist' in EXCLUDE_DIRS but directory doesn't exist

Checking ENTRY_PATTERNS...
✓ pages/_app.tsx (found: 1 file)
✓ app/layout.tsx (found: 1 file)
⚠ Warning: pages/index.tsx not found

Checking DOC_SIGNALS...
✓ pages:pages/** (matches 15 files)
✓ api_routes:pages/api/** (matches 8 files)
✗ Error: Invalid pattern 'components:[invalid' - unclosed bracket

Checking DOCSTRING_PATTERN...
✓ Regex compiles: ^\s*/\*\*
✓ Regex compiles: \*/

Summary:
- 2 warnings
- 1 error

Preset validation FAILED
```

**Validation Functions:**
```bash
validate_preset() {
    local preset_file="$1"
    local errors=0
    local warnings=0
    
    # Source preset
    source "$preset_file"
    
    # Required variables
    if [[ -z "$PRESET_NAME" ]]; then
        echo "✗ Error: PRESET_NAME not defined"
        ((errors++))
    else
        echo "✓ PRESET_NAME: \"$PRESET_NAME\""
    fi
    
    if [[ -z "$PRESET_VERSION" ]]; then
        echo "✗ Error: PRESET_VERSION not defined"
        ((errors++))
    fi
    
    # Validate DOC_SIGNALS format
    echo "$DOC_SIGNALS" | while read -r signal; do
        [[ -z "$signal" ]] && continue
        if [[ ! "$signal" =~ ^[a-z_]+:.+ ]]; then
            echo "✗ Error: Invalid DOC_SIGNAL format: '$signal'"
            echo "  Expected: category:glob_pattern"
            ((errors++))
        fi
    done
    
    # Validate regex patterns
    if [[ -n "$DOCSTRING_PATTERN" ]]; then
        if ! echo "" | grep -qE "$DOCSTRING_PATTERN" 2>/dev/null; then
            # Check if regex compiles (empty match is OK)
            if ! echo "test" | grep -qE "$DOCSTRING_PATTERN" 2>&1 | grep -q "Invalid"; then
                echo "✓ Regex compiles: $DOCSTRING_PATTERN"
            else
                echo "✗ Error: Invalid regex: $DOCSTRING_PATTERN"
                ((errors++))
            fi
        fi
    fi
    
    # Check file matches
    for pattern in $ENTRY_PATTERNS; do
        local matches
        matches=$(find . -path "./$pattern" 2>/dev/null | wc -l)
        if [[ $matches -eq 0 ]]; then
            echo "⚠ Warning: ENTRY_PATTERN '$pattern' matches no files"
            ((warnings++))
        else
            echo "✓ $pattern (found: $matches files)"
        fi
    done
    
    # Summary
    echo ""
    echo "Summary: $warnings warnings, $errors errors"
    
    if [[ $errors -gt 0 ]]; then
        echo "Preset validation FAILED"
        return 1
    else
        echo "Preset validation PASSED"
        return 0
    fi
}
```

**Common Validation Errors:**
| Error | Cause | Fix |
|-------|-------|-----|
| Missing PRESET_NAME | Variable not defined | Add `PRESET_NAME="my-preset"` |
| Invalid DOC_SIGNAL | Missing colon | Use format `category:pattern` |
| Invalid regex | Bad escape sequence | Test regex with `grep -E` |
| No file matches | Wrong path pattern | Check glob syntax |

---

## Definition of Done
- [ ] `--validate-preset` command implemented
- [ ] Required variables validated
- [ ] DOC_SIGNALS format validated
- [ ] Regex patterns validated
- [ ] File match warnings shown
- [ ] Clear error messages with suggestions
- [ ] Tested with valid and invalid presets

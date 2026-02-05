# STORY-018: Add Installation Validation & Error Handling

## Metadata
| Field | Value |
|-------|-------|
| **Parent Epic** | [EPIC-002](EPIC.md) |
| **Status** | ✅ Complete |
| **Ambiguity Score** | 🟢 Low |
| **Actor** | Developer |
| **Complexity** | Small (1 file) |

---

## 1. The Spec (The Contract)

### 1.1 User Story
> As a **Developer**,  
> I want **clear error messages when installation fails**,  
> So that **I can quickly resolve issues and complete setup**.

### 1.2 Detailed Requirements
- [ ] Validate running from a project root (has files, not filesystem root)
- [ ] Check for write permissions in current directory
- [ ] Validate bash version is 4.0+
- [ ] Check that required source files exist (scan.sh, instructions.md)
- [ ] Handle curl download failures gracefully
- [ ] Provide actionable error messages with solutions
- [ ] Exit with appropriate error codes

---

## 2. The Truth (Executable Tests)

### 2.1 Acceptance Criteria (Gherkin)
```gherkin
Feature: Installation Validation

  Scenario: Reject filesystem root
    Given current directory is "/"
    When install.sh is run
    Then exit code is 1
    And output contains "Cannot install in filesystem root"

  Scenario: Reject empty directory warning
    Given current directory has no files
    When install.sh is run
    Then output contains warning about empty directory
    And installation proceeds (with confirmation)

  Scenario: Check bash version
    Given bash version is 3.x
    When install.sh is run
    Then exit code is 1
    And output contains "Bash 4.0+ required"

  Scenario: Check write permissions
    Given current directory is read-only
    When install.sh is run
    Then exit code is 1
    And output contains "Permission denied"

  Scenario: Missing source files
    Given core/scan.sh does not exist
    When install.sh is run from source
    Then exit code is 1
    And output contains "Missing required file: scan.sh"

  Scenario: Successful validation
    Given all validations pass
    When install.sh is run
    Then installation proceeds
    And no validation errors shown
```

---

## 3. Technical Context (For Coder Agent)

### 3.1 Affected Files
- `install.sh` - Add validation functions

### 3.2 Implementation
```bash
# Exit codes
EXIT_SUCCESS=0
EXIT_INVALID_ARGS=1
EXIT_VALIDATION_FAILED=2
EXIT_PERMISSION_DENIED=3
EXIT_MISSING_FILES=4

validate_environment() {
    # Check bash version
    local bash_major="${BASH_VERSION%%.*}"
    if [[ "$bash_major" -lt 4 ]]; then
        log_error "Bash 4.0+ required (found: $BASH_VERSION)"
        log_error "On macOS: brew install bash"
        exit $EXIT_VALIDATION_FAILED
    fi
    
    # Check not running from root
    if [[ "$(pwd)" == "/" ]]; then
        log_error "Cannot install in filesystem root"
        log_error "Run from your project directory"
        exit $EXIT_VALIDATION_FAILED
    fi
    
    # Check write permissions
    if ! touch ".vdoc-test-write" 2>/dev/null; then
        log_error "Permission denied: cannot write to current directory"
        exit $EXIT_PERMISSION_DENIED
    fi
    rm -f ".vdoc-test-write"
    
    # Warn if directory is empty
    if [[ -z "$(ls -A 2>/dev/null)" ]]; then
        log_warning "Directory appears empty. Is this your project root?"
        read -p "Continue anyway? [y/N] " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && exit $EXIT_SUCCESS
    fi
}

validate_source_files() {
    local source_dir="$1"
    local required_files=(
        "core/scan.sh"
        "core/instructions.md"
        "core/presets/default.conf"
    )
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "${source_dir}/${file}" ]]; then
            log_error "Missing required file: $file"
            log_error "Source directory may be incomplete: $source_dir"
            exit $EXIT_MISSING_FILES
        fi
    done
}

# Trap for cleanup on error
cleanup_on_error() {
    log_error "Installation failed. Cleaning up..."
    # Remove partially created directories
    [[ -d "./vdocs/.vdoc" ]] && rm -rf "./vdocs/.vdoc"
    [[ -d "./vdocs" ]] && rmdir "./vdocs" 2>/dev/null || true
}

trap cleanup_on_error ERR
```

### 3.3 Error Codes
| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Invalid arguments |
| 2 | Validation failed (bash version, root dir, etc.) |
| 3 | Permission denied |
| 4 | Missing required files |

### 3.4 Error Message Format
```
✗ Error: [brief description]
  → [actionable solution]
```

---

## 4. Notes
- Validation runs before any file operations
- Cleanup trap removes partial installations on failure
- Interactive confirmation only when running in terminal (not piped curl)
- Check `[[ -t 0 ]]` to detect interactive mode

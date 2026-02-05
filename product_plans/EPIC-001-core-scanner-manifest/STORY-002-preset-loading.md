# STORY-002: Create Preset Loading System

## Metadata
| Field | Value |
|-------|-------|
| **Parent Epic** | [EPIC-001](EPIC.md) |
| **Status** | ✅ Complete |
| **Ambiguity Score** | 🟢 Low |
| **Actor** | Scanner |
| **Complexity** | Small (1 file) |

---

## 1. The Spec (The Contract)

### 1.1 User Story
> As the **Scanner**,  
> I want to **load language-specific presets**,  
> So that **I can apply correct exclusions and patterns per language**.

### 1.2 Detailed Requirements
- [ ] Auto-detect language from marker files (tsconfig.json, requirements.txt, etc.)
- [ ] Load corresponding preset from presets/ directory
- [ ] Fall back to default.conf if no specific preset matches
- [ ] Support custom presets in project's vdocs/.vdoc/presets/
- [ ] Validate preset has required variables
- [ ] Source preset file to set environment variables

---

## 2. The Truth (Executable Tests)

### 2.1 Acceptance Criteria (Gherkin)
```gherkin
Feature: Preset Loading System

  Scenario: Load TypeScript preset
    Given tsconfig.json exists in project root
    When load_preset is called
    Then PRESET_NAME equals "typescript"
    And EXCLUDE_DIRS contains "node_modules"

  Scenario: Load Python preset
    Given requirements.txt exists in project root
    When load_preset is called
    Then PRESET_NAME equals "python"
    And EXCLUDE_DIRS contains "__pycache__"

  Scenario: Fall back to default
    Given no language marker files exist
    When load_preset is called
    Then PRESET_NAME equals "default"

  Scenario: Custom preset override
    Given vdocs/.vdoc/presets/custom.conf exists
    And custom.conf sets PRESET_NAME="custom"
    When load_preset is called with "custom"
    Then PRESET_NAME equals "custom"

  Scenario: Missing required variable
    Given preset file missing EXCLUDE_DIRS
    When load_preset is called
    Then error message indicates missing variable
```

---

## 3. Technical Context (For Coder Agent)

### 3.1 Affected Files
- `core/scan.sh` - Add `load_preset()` and `detect_language()` functions

### 3.2 Implementation
```bash
# Detect project language from marker files
detect_language() {
    if [[ -f "tsconfig.json" ]]; then
        echo "typescript"
    elif [[ -f "package.json" ]]; then
        echo "javascript"
    elif [[ -f "requirements.txt" ]] || [[ -f "pyproject.toml" ]]; then
        echo "python"
    elif [[ -f "go.mod" ]]; then
        echo "go"
    elif [[ -f "Cargo.toml" ]]; then
        echo "rust"
    elif [[ -f "pom.xml" ]] || [[ -f "build.gradle" ]]; then
        echo "java"
    else
        echo "default"
    fi
}

# Find preset file
find_preset() {
    local language="$1"
    local locations=(
        "./vdocs/.vdoc/presets/${language}.conf"   # Project custom
        "${SCRIPT_DIR}/presets/${language}.conf"    # Installed
    )
    
    for loc in "${locations[@]}"; do
        if [[ -f "$loc" ]]; then
            echo "$loc"
            return 0
        fi
    done
    
    # Fall back to default
    echo "${SCRIPT_DIR}/presets/default.conf"
}

# Validate preset has required variables
validate_preset() {
    local required=(PRESET_NAME EXCLUDE_DIRS DOC_SIGNALS)
    for var in "${required[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            echo "Error: Preset missing required variable: $var" >&2
            return 1
        fi
    done
}

# Load preset
load_preset() {
    local language
    language=$(detect_language)
    
    local preset_file
    preset_file=$(find_preset "$language")
    
    if [[ ! -f "$preset_file" ]]; then
        echo "Error: Preset not found: $preset_file" >&2
        exit 1
    fi
    
    # Source the preset (sets variables)
    # shellcheck source=/dev/null
    source "$preset_file"
    
    validate_preset || exit 1
}
```

### 3.3 Preset Search Order
1. `./vdocs/.vdoc/presets/{language}.conf` (project custom)
2. `{script_dir}/presets/{language}.conf` (installed)
3. `{script_dir}/presets/default.conf` (fallback)

---

## 4. Notes
- Presets are bash-sourceable .conf files
- `source` command loads variables into current environment
- Custom presets allow project-specific overrides
- Required variables: PRESET_NAME, EXCLUDE_DIRS, DOC_SIGNALS

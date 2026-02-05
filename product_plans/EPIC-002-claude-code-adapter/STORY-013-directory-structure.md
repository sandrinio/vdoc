# STORY-013: Create Directory Structure Setup

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
> I want **vdoc to create the necessary directory structure**,  
> So that **all vdoc tools and output are organized in a standard location**.

### 1.2 Detailed Requirements
- [ ] Create `./vdocs/` directory if not exists
- [ ] Create `./vdocs/.vdoc/` directory for tools
- [ ] Create `./vdocs/.vdoc/presets/` directory
- [ ] Create `./vdocs/.vdoc/templates/` directory
- [ ] Copy `core/scan.sh` to `./vdocs/.vdoc/scan.sh`
- [ ] Copy `core/instructions.md` to `./vdocs/.vdoc/instructions.md`
- [ ] Copy all preset files to `./vdocs/.vdoc/presets/`
- [ ] Copy all template files to `./vdocs/.vdoc/templates/`
- [ ] Make `scan.sh` executable
- [ ] Skip copy if files already exist (idempotent)
- [ ] Print status for each operation

---

## 2. The Truth (Executable Tests)

### 2.1 Acceptance Criteria (Gherkin)
```gherkin
Feature: Directory Structure Setup

  Scenario: Fresh install creates all directories
    Given a project with no vdocs/ directory
    When setup_directories is called
    Then ./vdocs/ exists
    And ./vdocs/.vdoc/ exists
    And ./vdocs/.vdoc/presets/ exists
    And ./vdocs/.vdoc/templates/ exists

  Scenario: Core files are copied
    Given vdocs/.vdoc/ directory exists
    When copy_core_files is called
    Then ./vdocs/.vdoc/scan.sh exists
    And ./vdocs/.vdoc/scan.sh is executable
    And ./vdocs/.vdoc/instructions.md exists

  Scenario: Presets are copied
    Given vdocs/.vdoc/presets/ directory exists
    When copy_core_files is called
    Then ./vdocs/.vdoc/presets/typescript.conf exists
    And ./vdocs/.vdoc/presets/python.conf exists
    And ./vdocs/.vdoc/presets/default.conf exists

  Scenario: Templates are copied
    Given vdocs/.vdoc/templates/ directory exists
    When copy_core_files is called
    Then ./vdocs/.vdoc/templates/doc-page.md exists

  Scenario: Idempotent - skip existing
    Given ./vdocs/.vdoc/scan.sh already exists
    When copy_core_files is called
    Then existing file is not overwritten
    And output indicates "already exists"
```

---

## 3. Technical Context (For Coder Agent)

### 3.1 Affected Files
- `install.sh` - Add `setup_directories()` and `copy_core_files()` functions

### 3.2 Implementation
```bash
# Source location (where install.sh lives or was downloaded from)
VDOC_SOURCE_DIR="${VDOC_SOURCE_DIR:-$(dirname "$0")}"

setup_directories() {
    local dirs=(
        "./vdocs"
        "./vdocs/.vdoc"
        "./vdocs/.vdoc/presets"
        "./vdocs/.vdoc/templates"
    )
    
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            log_success "Created $dir"
        else
            log_info "Directory exists: $dir"
        fi
    done
}

copy_core_files() {
    local source_dir="$VDOC_SOURCE_DIR"
    local target_dir="./vdocs/.vdoc"
    
    # Core files
    local files=(
        "core/scan.sh:scan.sh"
        "core/instructions.md:instructions.md"
    )
    
    for mapping in "${files[@]}"; do
        local src="${source_dir}/${mapping%%:*}"
        local dst="${target_dir}/${mapping##*:}"
        
        if [[ ! -f "$dst" ]]; then
            cp "$src" "$dst"
            log_success "Copied ${mapping##*:}"
        else
            log_info "Exists: ${mapping##*:}"
        fi
    done
    
    # Make scan.sh executable
    chmod +x "${target_dir}/scan.sh"
    
    # Copy presets
    for preset in "${source_dir}"/core/presets/*.conf; do
        local name=$(basename "$preset")
        local dst="${target_dir}/presets/${name}"
        if [[ ! -f "$dst" ]]; then
            cp "$preset" "$dst"
            log_success "Copied preset: $name"
        fi
    done
    
    # Copy templates
    for template in "${source_dir}"/core/templates/*; do
        local name=$(basename "$template")
        local dst="${target_dir}/templates/${name}"
        if [[ ! -f "$dst" ]]; then
            cp "$template" "$dst"
            log_success "Copied template: $name"
        fi
    done
}
```

### 3.3 Target Structure
```
project/
└── vdocs/
    └── .vdoc/
        ├── scan.sh           (executable)
        ├── instructions.md
        ├── presets/
        │   ├── typescript.conf
        │   ├── python.conf
        │   └── default.conf
        └── templates/
            └── doc-page.md
```

---

## 4. Notes
- Source directory must be determined (local clone vs curl download)
- For curl install, files need to be bundled or downloaded separately
- Idempotency is important - don't overwrite user customizations

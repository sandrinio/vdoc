# STORY-054: Implement Multi-Language Preset Loading

## Metadata
| Field | Value |
|-------|-------|
| **Parent Epic** | [EPIC-006A](EPIC.md) |
| **Status** | Complete |
| **Ambiguity Score** | 🟢 Low |
| **Actor** | Developer / AI Tool |
| **Complexity** | Medium (routing logic + preset switching) |

---

## 1. The Spec (The Contract)

### 1.1 User Story
> As a **Monorepo Maintainer**,
> I want vdoc to **automatically apply the correct preset per file**,
> So that **TypeScript files use TypeScript patterns and Go files use Go patterns**.

### 1.2 Detailed Requirements
- [ ] Read `vdoc.config.json` at scan start
- [ ] For each file, determine which preset applies based on path
- [ ] **Warn** if file doesn't match any configured path, then use default preset
- [ ] **Fresh source** preset for each switch (safe isolation, no variable leakage)
- [ ] **Validate** overlapping paths at config load, warn user of precedence
- [ ] Apply correct EXCLUDE_FILES, DOCSTRING_PATTERN, DOC_SIGNALS per preset
- [ ] Cache loaded presets to avoid re-reading .conf files
- [ ] Log which preset is used for each directory subtree

### 1.3 Design Decisions (Resolved)

| Decision | Resolution | Rationale |
|----------|------------|-----------|
| **Unmapped files** | Warn + use default | User should know files are falling back; silent default hides config gaps |
| **Preset isolation** | Fresh source each time | Safety over speed; prevents subtle bugs from variable leakage |
| **Overlapping paths** | Document + validate with warning | Longest match wins; warn at config load so user understands precedence |

---

## 2. The Truth (Executable Tests)

### 2.1 Acceptance Criteria (Gherkin)
```gherkin
Feature: Multi-Language Preset Loading

  Scenario: Route TypeScript file to TypeScript preset
    Given vdoc.config.json maps "frontend/" to "typescript"
    And file frontend/src/App.tsx exists
    When vdoc scans frontend/src/App.tsx
    Then typescript.conf preset is loaded
    And docstring pattern matches JSDoc comments
    And .tsx files are included

  Scenario: Route Go file to Go preset
    Given vdoc.config.json maps "backend/" to "go"
    And file backend/api/server.go exists
    When vdoc scans backend/api/server.go
    Then go.conf preset is loaded
    And docstring pattern matches Go doc comments
    And vendor/ is excluded

  Scenario: File outside configured paths uses default
    Given vdoc.config.json has no mapping for "tools/"
    And file tools/script.sh exists
    When vdoc scans tools/script.sh
    Then default.conf preset is loaded

  Scenario: Most specific path wins
    Given vdoc.config.json maps:
      | path | preset |
      | src/ | typescript |
      | src/generated/ | default |
    And file src/generated/types.ts exists
    When vdoc scans src/generated/types.ts
    Then default.conf preset is loaded (more specific)

  Scenario: Preset caching
    Given vdoc.config.json maps "frontend/" to "typescript"
    And frontend/ contains 100 .ts files
    When vdoc scans all files
    Then typescript.conf is loaded only once
    And scan completes without re-reading preset

  Scenario: Warn on unmapped file path
    Given vdoc.config.json maps only "src/" to "typescript"
    And file tools/deploy.sh exists (not under src/)
    When vdoc scans tools/deploy.sh
    Then warning is logged: "tools/deploy.sh: no matching path, using default preset"
    And default.conf preset is applied

  Scenario: Validate overlapping paths at config load
    Given vdoc.config.json maps:
      | path | preset |
      | src/ | typescript |
      | src/generated/ | default |
    When config is loaded
    Then warning is logged: "Overlapping paths: src/generated/ takes precedence over src/"

  Scenario: Fresh preset isolation prevents leakage
    Given typescript.conf sets DOCSTRING_PATTERN="/**"
    And go.conf does NOT set DOCSTRING_PATTERN
    When scanning switches from typescript to go
    Then DOCSTRING_PATTERN is reset (not inherited from typescript)
    And go uses its own default or errors
```

---

## 3. Technical Context (For Coder Agent)

### 3.1 Affected Files
- `core/scan.sh` - Integrate preset routing
- `core/config.sh` - Path matching logic
- `core/preset-cache.sh` (new) - Preset caching

### 3.2 Implementation
```bash
#!/usr/bin/env bash
# core/preset-cache.sh

declare -A PRESET_CACHE

# Reset all preset variables to empty (isolation)
reset_preset_vars() {
    EXCLUDE_DIRS=""
    EXCLUDE_FILES=""
    ENTRY_PATTERNS=""
    DOCSTRING_PATTERN=""
    DOCSTRING_END=""
    DOC_SIGNALS=""
}

# Load preset with fresh isolation
load_preset_isolated() {
    local preset_name="$1"

    # ALWAYS reset first (fresh source for safety)
    reset_preset_vars

    # Check cache for the preset content
    if [[ -n "${PRESET_CACHE[$preset_name]:-}" ]]; then
        eval "${PRESET_CACHE[$preset_name]}"
        return 0
    fi

    local preset_file="core/presets/${preset_name}.conf"
    if [[ ! -f "$preset_file" ]]; then
        echo "ERROR: Preset not found: $preset_file" >&2
        return 1
    fi

    # Load preset
    source "$preset_file"

    # Cache the variable assignments for later
    PRESET_CACHE[$preset_name]=$(declare -p EXCLUDE_DIRS EXCLUDE_FILES \
        ENTRY_PATTERNS DOCSTRING_PATTERN DOCSTRING_END DOC_SIGNALS 2>/dev/null)

    return 0
}

# Validate config for overlapping paths
validate_config_paths() {
    local config="$1"

    local paths=$(echo "$config" | jq -r '.languages[].path' | sort)
    local prev=""

    while read -r path; do
        if [[ -n "$prev" ]] && [[ "$path" == "$prev"* ]]; then
            echo "WARNING: Overlapping paths: $path takes precedence over $prev" >&2
        fi
        prev="$path"
    done <<< "$paths"
}

# Clear cache (for testing)
clear_preset_cache() {
    PRESET_CACHE=()
}
```

### 3.3 Scan Integration
```bash
# In scan.sh main loop

# Load and validate config once
CONFIG=$(load_config)
if [[ -n "$CONFIG" ]]; then
    validate_config_paths "$CONFIG"
fi

# Group files by preset for efficiency
declare -A FILES_BY_PRESET
declare -a UNMAPPED_FILES

while read -r file; do
    preset=$(get_preset_for_path "$file" "$CONFIG")

    if [[ -z "$preset" ]] || [[ "$preset" == "null" ]]; then
        # Warn about unmapped file
        echo "WARNING: $file: no matching path, using default preset" >&2
        UNMAPPED_FILES+=("$file")
        preset="default"
    fi

    FILES_BY_PRESET[$preset]+="$file"$'\n'
done < <(walk_files)

# Summary of unmapped files
if [[ ${#UNMAPPED_FILES[@]} -gt 0 ]]; then
    echo "# Note: ${#UNMAPPED_FILES[@]} files used default preset (no path match)" >&2
fi

# Process each preset group with fresh isolation
for preset in "${!FILES_BY_PRESET[@]}"; do
    echo "# Processing $preset files..."
    load_preset_isolated "$preset"  # Fresh source each time

    while read -r file; do
        [[ -z "$file" ]] && continue
        process_file "$file"
    done <<< "${FILES_BY_PRESET[$preset]}"
done
```

### 3.4 Path Matching Logic
```bash
# Match file to most specific configured path
get_preset_for_path() {
    local file_path="$1"
    local config="$2"

    if [[ -z "$config" ]]; then
        echo "default"
        return
    fi

    # Sort by path length descending (most specific first)
    local preset=$(echo "$config" | jq -r --arg path "$file_path" '
        .languages
        | map(select($path | startswith(.path)))
        | sort_by(-.path | length)
        | .[0].preset // "default"
    ')

    echo "$preset"
}
```

---

## 4. Notes
- Requires STORY-053 (config schema) to be completed first
- Grouping files by preset before processing improves performance
- Consider adding `--verbose` flag to show preset used per file

## 5. Design Decision Log

### Unmapped Files → Warn + Default
Files outside any configured path get a warning so users know their config might be incomplete. Silent fallback would hide gaps; erroring would be too strict for initial adoption.

### Fresh Preset Isolation
Each preset switch resets ALL variables before loading. This prevents subtle bugs where a variable set by preset A leaks into preset B if B doesn't explicitly set it. The performance cost is negligible (reading cached values).

### Overlapping Path Validation
At config load time, we detect overlapping paths (e.g., `src/` and `src/generated/`) and warn the user which takes precedence. Longest match wins. This prevents confusion when files don't use the expected preset.

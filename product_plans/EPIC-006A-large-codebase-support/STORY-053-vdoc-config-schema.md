# STORY-053: Create vdoc.config.json Schema

## Metadata
| Field | Value |
|-------|-------|
| **Parent Epic** | [EPIC-006A](EPIC.md) |
| **Status** | Complete |
| **Ambiguity Score** | 🟢 Low |
| **Actor** | Developer |
| **Complexity** | Low (schema definition + validation) |

---

## 1. The Spec (The Contract)

### 1.1 User Story
> As a **Monorepo Maintainer**,
> I want to **define language presets per directory path**,
> So that **my TypeScript frontend and Go backend are scanned correctly**.

### 1.2 Detailed Requirements
- [ ] Define `vdoc.config.json` schema with JSON Schema validation
- [ ] Support `languages[]` array mapping paths to presets
- [ ] Support `exclude[]` array for additional exclusions
- [ ] Support `settings` object for global overrides
- [ ] Auto-detect config file in project root
- [ ] Validate config on load, error with clear messages
- [ ] Generate schema file for IDE autocomplete

---

## 2. The Truth (Executable Tests)

### 2.1 Acceptance Criteria (Gherkin)
```gherkin
Feature: vdoc.config.json Schema

  Scenario: Valid multi-language config
    Given vdoc.config.json contains:
      """
      {
        "version": "1.0",
        "languages": [
          { "path": "frontend/", "preset": "typescript" },
          { "path": "backend/", "preset": "go" }
        ]
      }
      """
    When vdoc validates the config
    Then validation passes
    And config is loaded successfully

  Scenario: Invalid preset name
    Given vdoc.config.json contains:
      """
      {
        "version": "1.0",
        "languages": [
          { "path": "src/", "preset": "not-a-real-preset" }
        ]
      }
      """
    When vdoc validates the config
    Then validation fails
    And error message contains "Unknown preset: not-a-real-preset"

  Scenario: Missing required version field
    Given vdoc.config.json contains:
      """
      {
        "languages": [{ "path": "src/", "preset": "typescript" }]
      }
      """
    When vdoc validates the config
    Then validation fails
    And error message contains "Missing required field: version"

  Scenario: Overlapping paths warning
    Given vdoc.config.json contains:
      """
      {
        "version": "1.0",
        "languages": [
          { "path": "src/", "preset": "typescript" },
          { "path": "src/api/", "preset": "go" }
        ]
      }
      """
    When vdoc validates the config
    Then validation passes
    And warning contains "Overlapping paths detected"
    And more specific path (src/api/) takes precedence
```

---

## 3. Technical Context (For Coder Agent)

### 3.1 Affected Files
- `core/vdoc.config.schema.json` (new) - JSON Schema definition
- `core/config.sh` (new) - Config loading and validation
- `core/scan.sh` - Integrate config loading

### 3.2 JSON Schema Definition
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://vdoc.dev/schemas/vdoc.config.json",
  "title": "vdoc Configuration",
  "description": "Configuration for vdoc multi-language scanning",
  "type": "object",
  "required": ["version", "languages"],
  "properties": {
    "version": {
      "type": "string",
      "enum": ["1.0"],
      "description": "Config schema version"
    },
    "languages": {
      "type": "array",
      "description": "Path-to-preset mappings",
      "items": {
        "type": "object",
        "required": ["path", "preset"],
        "properties": {
          "path": {
            "type": "string",
            "description": "Directory path (relative to project root)",
            "pattern": "^[^/].*/$"
          },
          "preset": {
            "type": "string",
            "description": "Preset name (typescript, python, go, etc.)"
          },
          "exclude": {
            "type": "array",
            "items": { "type": "string" },
            "description": "Additional exclusions for this path"
          }
        }
      },
      "minItems": 1
    },
    "exclude": {
      "type": "array",
      "items": { "type": "string" },
      "description": "Global directory exclusions",
      "default": []
    },
    "settings": {
      "type": "object",
      "description": "Global settings overrides",
      "properties": {
        "hashAlgorithm": {
          "type": "string",
          "enum": ["sha256", "sha1", "md5"],
          "default": "sha256"
        },
        "docstringMaxLines": {
          "type": "integer",
          "minimum": 1,
          "maximum": 50,
          "default": 10
        }
      }
    }
  }
}
```

### 3.3 Config Loader
```bash
#!/usr/bin/env bash
# core/config.sh

CONFIG_FILE="vdoc.config.json"

# Load and validate config
load_config() {
    local config_path="${1:-$CONFIG_FILE}"

    if [[ ! -f "$config_path" ]]; then
        echo ""  # No config = single-language mode
        return 0
    fi

    # Validate JSON syntax
    if ! jq empty "$config_path" 2>/dev/null; then
        echo "ERROR: Invalid JSON in $config_path" >&2
        return 1
    fi

    # Validate required fields
    local version=$(jq -r '.version // empty' "$config_path")
    if [[ -z "$version" ]]; then
        echo "ERROR: Missing required field: version" >&2
        return 1
    fi

    # Validate presets exist
    jq -r '.languages[].preset' "$config_path" | while read -r preset; do
        if [[ ! -f "core/presets/${preset}.conf" ]]; then
            echo "ERROR: Unknown preset: $preset" >&2
            return 1
        fi
    done

    cat "$config_path"
}

# Get preset for a file path
get_preset_for_path() {
    local file_path="$1"
    local config="$2"

    if [[ -z "$config" ]]; then
        echo ""  # Use auto-detection
        return
    fi

    # Find matching path (most specific wins)
    echo "$config" | jq -r --arg path "$file_path" '
        .languages
        | map(select($path | startswith(.path)))
        | sort_by(.path | length)
        | reverse
        | .[0].preset // empty
    '
}
```

### 3.4 Example Config
```json
{
  "version": "1.0",
  "languages": [
    { "path": "frontend/", "preset": "typescript" },
    { "path": "backend/", "preset": "go" },
    { "path": "scripts/", "preset": "python" },
    { "path": "infra/", "preset": "default", "exclude": ["*.tfstate"] }
  ],
  "exclude": ["vendor/", "node_modules/", "dist/"],
  "settings": {
    "docstringMaxLines": 5
  }
}
```

---

## 4. Notes
- Path patterns must end with `/` to indicate directories
- More specific paths override less specific (longest match wins)
- Single-language projects don't need this config (auto-detection works)
- Schema file enables IDE autocomplete in VS Code, Cursor, etc.

# STORY-043: Implement Custom Preset Loading

## Metadata
| Field | Value |
|-------|-------|
| **Status** | ✅ Complete |
| **Story Points** | 3 |
| **Priority** | P1 - High |
| **Parent Epic** | EPIC-005 |

---

## User Story
**As a** developer with a custom framework
**I want** to create and load custom language presets
**So that** vdoc correctly categorizes my project's unique structure

---

## Acceptance Criteria

### AC1: Custom preset location
- [ ] Load presets from `vdocs/.vdoc/presets/`
- [ ] Support naming: `custom-<name>.conf`
- [ ] Custom presets override built-in presets

### AC2: Preset loading order
- [ ] Check custom presets first
- [ ] Then check built-in presets
- [ ] Fall back to default.conf

### AC3: Preset selection
- [ ] Auto-detect based on marker files
- [ ] Allow explicit preset in config: `vdoc.config.json`
- [ ] CLI override: `--preset=custom-nextjs`

### AC4: Preset inheritance
- [ ] Custom presets can extend built-in presets
- [ ] Syntax: `EXTENDS="typescript"`
- [ ] Child values override parent

### AC5: Error handling
- [ ] Clear error if preset not found
- [ ] Warn if custom preset has syntax errors
- [ ] Suggest corrections for common mistakes

---

## Technical Notes

**Custom Preset Location:**
```
project/
├── vdocs/
│   └── .vdoc/
│       └── presets/
│           ├── custom-nextjs.conf
│           └── custom-internal.conf
└── src/
```

**Custom Preset Example (`custom-nextjs.conf`):**
```bash
# Custom preset for Next.js projects
# Extends TypeScript preset with Next.js-specific patterns

PRESET_NAME="custom-nextjs"
PRESET_VERSION="1.0.0"
EXTENDS="typescript"

# Additional exclusions for Next.js
EXCLUDE_DIRS="${EXCLUDE_DIRS} .next out"

# Next.js-specific entry patterns
ENTRY_PATTERNS="pages/_app.tsx app/layout.tsx pages/index.tsx app/page.tsx"

# Extended category signals for Next.js
DOC_SIGNALS="
${DOC_SIGNALS}
pages:pages/**
app:app/**
api_routes:pages/api/**
api_routes:app/api/**
"
```

**Loading Logic in scan.sh:**
```bash
load_preset() {
    local preset_name="$1"
    local custom_path="vdocs/.vdoc/presets/custom-${preset_name}.conf"
    local builtin_path="${VDOC_HOME}/presets/${preset_name}.conf"
    
    # Check custom presets first
    if [[ -f "$custom_path" ]]; then
        log_verbose "Loading custom preset: $custom_path"
        source "$custom_path"
        
        # Handle inheritance
        if [[ -n "$EXTENDS" ]]; then
            local parent_values
            parent_values=$(load_preset "$EXTENDS")
            # Merge parent with child (child overrides)
            eval "$parent_values"
            source "$custom_path"  # Re-source to override
        fi
        return 0
    fi
    
    # Then check built-in presets
    if [[ -f "$builtin_path" ]]; then
        log_verbose "Loading built-in preset: $builtin_path"
        source "$builtin_path"
        return 0
    fi
    
    # Fall back to default
    log_verbose "Preset '$preset_name' not found, using default"
    source "${VDOC_HOME}/presets/default.conf"
}
```

**Config File Override (`vdoc.config.json`):**
```json
{
  "preset": "custom-nextjs",
  "overrides": {
    "excludeDirs": ["additional-dir"],
    "docSignals": {
      "custom_category": "src/custom/**"
    }
  }
}
```

**CLI Override:**
```bash
./vdocs/.vdoc/scan.sh --preset=custom-nextjs
```

---

## Definition of Done
- [ ] Custom presets load from `vdocs/.vdoc/presets/`
- [ ] Naming convention `custom-*.conf` documented
- [ ] Preset inheritance via `EXTENDS` works
- [ ] Loading order: custom → built-in → default
- [ ] Config file and CLI overrides work
- [ ] Clear error messages for missing/invalid presets
- [ ] Tested with custom preset creation

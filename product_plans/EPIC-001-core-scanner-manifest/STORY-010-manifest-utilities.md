# STORY-010: Implement Manifest Read/Write Utilities

## Metadata
| Field | Value |
|-------|-------|
| **Parent Epic** | [EPIC-001](EPIC.md) |
| **Status** | ✅ Complete |
| **Ambiguity Score** | 🟡 Medium |
| **Actor** | Scanner / AI Tool |
| **Complexity** | Medium (JSON manipulation in bash) |

---

## 1. The Spec (The Contract)

### 1.1 User Story
> As the **Scanner**,  
> I want to **read and write the manifest file**,  
> So that **documentation state persists between runs**.

### 1.2 Detailed Requirements
- [ ] Read existing manifest if present
- [ ] Create new manifest with scan results
- [ ] Update manifest with changed files
- [ ] Preserve user-added documentation entries
- [ ] Generate valid JSON output
- [ ] Handle missing/corrupted manifest gracefully
- [ ] Use jq if available, fallback to pure bash

---

## 2. The Truth (Executable Tests)

### 2.1 Acceptance Criteria (Gherkin)
```gherkin
Feature: Manifest Utilities

  Scenario: Create new manifest
    Given no _manifest.json exists
    When create_manifest is called with scan results
    Then vdocs/_manifest.json is created
    And it contains valid JSON
    And it has correct schema

  Scenario: Read existing manifest
    Given vdocs/_manifest.json exists
    When read_manifest is called
    Then source_index is populated
    And documentation array is populated

  Scenario: Update manifest with changes
    Given existing manifest has file with hash "abc123"
    And scan shows file now has hash "def456"
    When update_manifest is called
    Then source_index entry has new hash "def456"
    And last_updated is updated

  Scenario: Preserve user documentation entries
    Given user added custom documentation entry
    When update_manifest is called
    Then custom entry is preserved

  Scenario: Handle corrupted manifest
    Given _manifest.json contains invalid JSON
    When read_manifest is called
    Then error message is shown
    And option to regenerate is offered
```

---

## 3. Technical Context (For Coder Agent)

### 3.1 Affected Files
- `core/scan.sh` - Add manifest utilities
- Optionally: `core/manifest.sh` - Separate utility script

### 3.2 Implementation
```bash
MANIFEST_PATH="./vdocs/_manifest.json"

# Check if jq is available
has_jq() {
    command -v jq &>/dev/null
}

# Read manifest into variables
read_manifest() {
    if [[ ! -f "$MANIFEST_PATH" ]]; then
        return 1
    fi
    
    # Validate JSON
    if has_jq; then
        if ! jq empty "$MANIFEST_PATH" 2>/dev/null; then
            echo "Error: Invalid JSON in manifest" >&2
            return 2
        fi
    fi
    
    # Read values (using jq or grep/sed fallback)
    if has_jq; then
        MANIFEST_PROJECT=$(jq -r '.project' "$MANIFEST_PATH")
        MANIFEST_LANGUAGE=$(jq -r '.language' "$MANIFEST_PATH")
        MANIFEST_VERSION=$(jq -r '.vdoc_version' "$MANIFEST_PATH")
    else
        # Fallback: basic grep parsing
        MANIFEST_PROJECT=$(grep -o '"project"[[:space:]]*:[[:space:]]*"[^"]*"' "$MANIFEST_PATH" | cut -d'"' -f4)
        MANIFEST_LANGUAGE=$(grep -o '"language"[[:space:]]*:[[:space:]]*"[^"]*"' "$MANIFEST_PATH" | cut -d'"' -f4)
    fi
    
    return 0
}

# Get hash for file from manifest
get_manifest_hash() {
    local file="$1"
    
    if [[ ! -f "$MANIFEST_PATH" ]]; then
        echo ""
        return
    fi
    
    if has_jq; then
        jq -r ".source_index[\"$file\"].hash // empty" "$MANIFEST_PATH"
    else
        # Fallback: grep for the file entry
        grep -A5 "\"$file\"" "$MANIFEST_PATH" 2>/dev/null | \
            grep -o '"hash"[[:space:]]*:[[:space:]]*"[^"]*"' | \
            cut -d'"' -f4
    fi
}

# Create initial manifest from scan
create_manifest() {
    local project_name="$1"
    local language="$2"
    local scan_output="$3"
    
    mkdir -p "$(dirname "$MANIFEST_PATH")"
    
    # Build JSON
    cat > "$MANIFEST_PATH" << EOF
{
  "project": "$project_name",
  "language": "$language",
  "last_updated": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "vdoc_version": "$VDOC_VERSION",
  "documentation": [],
  "source_index": {
EOF

    # Add source entries
    local first=true
    while IFS='|' read -r path category hash docstring; do
        # Trim whitespace
        path=$(echo "$path" | xargs)
        category=$(echo "$category" | xargs)
        hash=$(echo "$hash" | xargs)
        docstring=$(echo "$docstring" | xargs | sed 's/"/\\"/g')
        
        [[ -z "$path" ]] && continue
        
        $first || echo "," >> "$MANIFEST_PATH"
        first=false
        
        cat >> "$MANIFEST_PATH" << EOF
    "$path": {
      "hash": "$hash",
      "category": "$category",
      "description": "$docstring",
      "description_source": "$([ -n "$docstring" ] && echo "docstring" || echo "inferred")",
      "documented_in": []
    }
EOF
    done <<< "$scan_output"
    
    # Close JSON
    cat >> "$MANIFEST_PATH" << EOF
  }
}
EOF
}

# Update manifest with new scan results
update_manifest() {
    local scan_output="$1"
    
    if ! has_jq; then
        echo "Warning: jq not available, cannot update manifest" >&2
        echo "Install jq for full functionality" >&2
        return 1
    fi
    
    local temp_file="${MANIFEST_PATH}.tmp"
    local timestamp
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    
    # Update timestamp
    jq ".last_updated = \"$timestamp\"" "$MANIFEST_PATH" > "$temp_file"
    
    # Update each file entry
    while IFS='|' read -r path category hash docstring; do
        path=$(echo "$path" | xargs)
        [[ -z "$path" ]] && continue
        
        hash=$(echo "$hash" | xargs)
        category=$(echo "$category" | xargs)
        docstring=$(echo "$docstring" | xargs)
        
        # Update or add entry
        jq --arg path "$path" \
           --arg hash "$hash" \
           --arg cat "$category" \
           --arg desc "$docstring" \
           '.source_index[$path] = (.source_index[$path] // {}) + {
              hash: $hash,
              category: $cat,
              description: (if $desc != "" then $desc else .source_index[$path].description // "" end),
              description_source: (if $desc != "" then "docstring" else .source_index[$path].description_source // "inferred" end),
              documented_in: (.source_index[$path].documented_in // [])
           }' "$temp_file" > "${temp_file}.2"
        mv "${temp_file}.2" "$temp_file"
    done <<< "$scan_output"
    
    mv "$temp_file" "$MANIFEST_PATH"
}
```

---

## 4. Notes
- jq is preferred but not required (bash fallback for basic operations)
- Manifest updates preserve user-added fields
- Creating manifest is simpler than updating (full generation)
- AI tools will use manifest for context, not these bash utilities
- These utilities are for scanner integration only

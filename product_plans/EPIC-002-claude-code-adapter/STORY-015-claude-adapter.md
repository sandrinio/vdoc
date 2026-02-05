# STORY-015: Create Claude Code Adapter

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
> As a **Developer using Claude Code**,  
> I want **vdoc to generate a SKILL.md file**,  
> So that **Claude Code can use vdoc commands**.

### 1.2 Detailed Requirements
- [ ] Read `instructions.md` from source or installed location
- [ ] Wrap content with YAML frontmatter for Claude Code
- [ ] Set skill name to "vdoc"
- [ ] Set trigger to "/vdoc"
- [ ] Write output to `~/.claude/skills/vdoc/SKILL.md`
- [ ] Create `~/.claude/skills/vdoc/` directory if not exists
- [ ] Handle both local install and curl install scenarios

---

## 2. The Truth (Executable Tests)

### 2.1 Acceptance Criteria (Gherkin)
```gherkin
Feature: Claude Code Adapter

  Scenario: Generate SKILL.md
    Given instructions.md exists at source location
    When adapters/claude/generate.sh is run
    Then ~/.claude/skills/vdoc/ directory exists
    And ~/.claude/skills/vdoc/SKILL.md exists

  Scenario: SKILL.md has correct frontmatter
    Given SKILL.md was generated
    When I read the file
    Then first line is "---"
    And file contains "name: vdoc"
    And file contains "trigger: /vdoc"
    And file contains closing "---"

  Scenario: SKILL.md includes instructions content
    Given SKILL.md was generated
    When I read the file
    Then it contains "## Identity"
    And it contains "## Workflows"

  Scenario: Idempotent generation
    Given SKILL.md already exists
    When adapters/claude/generate.sh is run
    Then SKILL.md is updated (not duplicated)
```

---

## 3. Technical Context (For Coder Agent)

### 3.1 Affected Files
- `adapters/claude/generate.sh` - Complete implementation

### 3.2 Implementation
```bash
#!/usr/bin/env bash
# Claude Code Adapter
# Transforms instructions.md into SKILL.md format

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Find instructions.md (check multiple locations)
find_instructions() {
    local locations=(
        "./vdocs/.vdoc/instructions.md"     # Installed in project
        "${SCRIPT_DIR}/../../core/instructions.md"  # Source repo
    )
    
    for loc in "${locations[@]}"; do
        if [[ -f "$loc" ]]; then
            echo "$loc"
            return 0
        fi
    done
    
    echo "Error: instructions.md not found" >&2
    return 1
}

generate_skill() {
    local instructions_path
    instructions_path=$(find_instructions)
    
    local output_dir="${HOME}/.claude/skills/vdoc"
    local output_file="${output_dir}/SKILL.md"
    
    # Create directory
    mkdir -p "$output_dir"
    
    # Generate SKILL.md with frontmatter
    cat > "$output_file" << 'FRONTMATTER'
---
name: vdoc
description: Generate and maintain product documentation from source code
trigger: /vdoc
---

FRONTMATTER
    
    # Append instructions content
    cat "$instructions_path" >> "$output_file"
    
    echo "Generated: $output_file"
}

generate_skill
```

### 3.3 Output Format
```yaml
---
name: vdoc
description: Generate and maintain product documentation from source code
trigger: /vdoc
---

# vdoc Instructions
[... rest of instructions.md content ...]
```

### 3.4 Output Location
`~/.claude/skills/vdoc/SKILL.md`

---

## 4. Notes
- Claude Code looks for skills in `~/.claude/skills/`
- The `/vdoc` trigger activates the skill
- Must handle case where user runs from source repo vs installed project
- Placeholder exists at `adapters/claude/generate.sh` - needs implementation

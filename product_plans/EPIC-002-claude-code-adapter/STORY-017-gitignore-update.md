# STORY-017: Add .gitignore Update Logic

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
> I want **platform-specific files automatically added to .gitignore**,  
> So that **I don't accidentally commit local configuration**.

### 1.2 Detailed Requirements
- [ ] Create `.gitignore` if it doesn't exist
- [ ] Add platform-specific instruction file path to `.gitignore`
- [ ] Add `.vdoc.lock` to `.gitignore`
- [ ] Add `.vdoc-scan-output` to `.gitignore`
- [ ] Don't duplicate entries if already present
- [ ] Add vdoc section header comment for clarity
- [ ] Preserve existing `.gitignore` content

---

## 2. The Truth (Executable Tests)

### 2.1 Acceptance Criteria (Gherkin)
```gherkin
Feature: .gitignore Update

  Scenario: Create .gitignore if missing
    Given no .gitignore exists
    When update_gitignore is called for "claude"
    Then .gitignore is created
    And it contains vdoc entries

  Scenario: Add Claude-specific entries
    Given .gitignore exists
    When update_gitignore is called for "claude"
    Then .gitignore contains "# vdoc"
    And .gitignore contains ".vdoc.lock"
    And .gitignore contains ".vdoc-scan-output"

  Scenario: Add Cursor-specific entries
    Given .gitignore exists
    When update_gitignore is called for "cursor"
    Then .gitignore contains ".cursor/rules/vdoc.md"

  Scenario: No duplicate entries
    Given .gitignore already contains ".vdoc.lock"
    When update_gitignore is called
    Then .gitignore has only one ".vdoc.lock" entry

  Scenario: Preserve existing content
    Given .gitignore contains "node_modules/"
    When update_gitignore is called
    Then .gitignore still contains "node_modules/"
```

---

## 3. Technical Context (For Coder Agent)

### 3.1 Affected Files
- `install.sh` - Add `update_gitignore()` function

### 3.2 Implementation
```bash
update_gitignore() {
    local platform="$1"
    local gitignore=".gitignore"
    
    # Platform-specific patterns
    local platform_pattern
    case "$platform" in
        claude)
            # Claude skill is in home dir, not project - nothing to ignore
            platform_pattern=""
            ;;
        cursor)
            platform_pattern=".cursor/rules/vdoc.md"
            ;;
        windsurf)
            platform_pattern=".windsurfrules"
            ;;
        aider)
            platform_pattern=".aider.conf.yml"
            ;;
        continue)
            platform_pattern=".continue/"
            ;;
    esac
    
    # Common patterns to add
    local patterns=(
        "# vdoc - generated files"
        ".vdoc.lock"
        ".vdoc-scan-output"
    )
    
    # Add platform pattern if exists
    [[ -n "$platform_pattern" ]] && patterns+=("$platform_pattern")
    
    # Create .gitignore if missing
    [[ ! -f "$gitignore" ]] && touch "$gitignore"
    
    # Add patterns if not present
    local added=0
    for pattern in "${patterns[@]}"; do
        if ! grep -qxF "$pattern" "$gitignore" 2>/dev/null; then
            echo "$pattern" >> "$gitignore"
            ((added++))
        fi
    done
    
    if [[ $added -gt 0 ]]; then
        log_success "Updated .gitignore ($added entries added)"
    else
        log_info ".gitignore already up to date"
    fi
}
```

### 3.3 Entries by Platform
| Platform | Gitignore Entry |
|----------|-----------------|
| claude | (none - skill is in ~/.claude/) |
| cursor | `.cursor/rules/vdoc.md` |
| windsurf | `.windsurfrules` |
| aider | `.aider.conf.yml` |
| continue | `.continue/` |

### 3.4 Common Entries (all platforms)
```
# vdoc - generated files
.vdoc.lock
.vdoc-scan-output
```

---

## 4. Notes
- Claude Code's SKILL.md is in `~/.claude/` (user home), not project root
- Use `grep -qxF` for exact line matching (not regex)
- Preserve file permissions and line endings

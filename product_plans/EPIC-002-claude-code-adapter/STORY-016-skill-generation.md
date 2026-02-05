# STORY-016: Implement SKILL.md Generation Integration

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
> I want **install.sh to automatically run the Claude adapter**,  
> So that **SKILL.md is generated as part of installation**.

### 1.2 Detailed Requirements
- [ ] Call `adapters/claude/generate.sh` when platform is "claude"
- [ ] Handle adapter script failure gracefully
- [ ] Print success/failure message for SKILL.md generation
- [ ] Show path where SKILL.md was created
- [ ] Provide next-step instruction for using the skill

---

## 2. The Truth (Executable Tests)

### 2.1 Acceptance Criteria (Gherkin)
```gherkin
Feature: SKILL.md Generation Integration

  Scenario: Claude platform triggers adapter
    Given install.sh is run with "claude" argument
    And directory setup is complete
    When platform adapter step runs
    Then adapters/claude/generate.sh is executed
    And SKILL.md is created

  Scenario: Success message shown
    Given adapter ran successfully
    Then output contains "✓ Generated SKILL.md"
    And output contains "~/.claude/skills/vdoc/SKILL.md"

  Scenario: Adapter failure handled
    Given adapter script fails
    Then output contains "✗ Failed to generate SKILL.md"
    And installation continues (non-fatal)
    And exit code is 0 (warning only)

  Scenario: Next steps shown
    Given installation completes successfully
    Then output contains "Next:"
    And output contains "Open Claude Code"
    And output contains "/vdoc"
```

---

## 3. Technical Context (For Coder Agent)

### 3.1 Affected Files
- `install.sh` - Add adapter execution step

### 3.2 Implementation
```bash
run_adapter() {
    local platform="$1"
    local adapter_script
    
    # Determine adapter location
    if [[ -f "./vdocs/.vdoc/adapters/${platform}/generate.sh" ]]; then
        adapter_script="./vdocs/.vdoc/adapters/${platform}/generate.sh"
    elif [[ -f "${VDOC_SOURCE_DIR}/adapters/${platform}/generate.sh" ]]; then
        adapter_script="${VDOC_SOURCE_DIR}/adapters/${platform}/generate.sh"
    else
        log_warning "Adapter not found for: $platform"
        return 1
    fi
    
    # Run adapter
    if bash "$adapter_script"; then
        log_success "Generated platform integration for $platform"
        return 0
    else
        log_warning "Failed to generate platform integration"
        return 1
    fi
}

print_next_steps() {
    local platform="$1"
    
    echo ""
    echo "Next steps:"
    
    case "$platform" in
        claude)
            echo "  1. Open Claude Code in this project"
            echo "  2. Type: /vdoc"
            echo "  3. Or say: \"generate documentation for this project\""
            ;;
        cursor)
            echo "  1. Open Cursor in this project"
            echo "  2. The vdoc rules are now active"
            echo "  3. Ask: \"generate documentation for this project\""
            ;;
        *)
            echo "  1. Open your AI coding tool in this project"
            echo "  2. Ask: \"generate documentation for this project\""
            ;;
    esac
}
```

### 3.3 Main Flow Integration
```bash
main() {
    # ... validation, language detection ...
    
    setup_directories
    copy_core_files
    
    # Run platform adapter
    if run_adapter "$platform"; then
        log_success "Installation complete!"
    else
        log_warning "Installation complete (adapter had issues)"
    fi
    
    # Update gitignore
    update_gitignore "$platform"
    
    # Show next steps
    print_next_steps "$platform"
}
```

---

## 4. Notes
- Adapter failure is non-fatal (user can run manually)
- Next steps are platform-specific
- SKILL.md path varies by platform

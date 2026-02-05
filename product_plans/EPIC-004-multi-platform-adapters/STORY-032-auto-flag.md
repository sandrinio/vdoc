# STORY-032: Implement --auto Flag Detection

## Metadata
| Field | Value |
|-------|-------|
| **Status** | ✅ Complete |
| **Story Points** | 2 |
| **Priority** | P1 - High |
| **Parent Epic** | EPIC-004 |

---

## User Story
**As a** developer with multiple AI tools installed
**I want** vdoc to auto-detect and configure all my tools
**So that** I don't have to run the installer multiple times

---

## Acceptance Criteria

### AC1: Detect installed AI tools
- [ ] Check for `.cursor/` directory → Cursor installed
- [ ] Check for `.continue/` directory → Continue installed
- [ ] Check for `.windsurfrules` file → Windsurf used
- [ ] Check for `.aider*` files → Aider used
- [ ] Check for `~/.claude/` directory → Claude Code installed

### AC2: Run matching adapters
- [ ] For each detected tool, run its adapter
- [ ] Report which adapters were run
- [ ] Continue even if one adapter fails

### AC3: Clean output
- [ ] Show summary of detected tools
- [ ] Show which instruction files were generated
- [ ] Show any warnings/errors per platform

---

## Technical Notes

**Detection Logic:**
```bash
detect_installed_platforms() {
    local platforms=()

    # Claude Code (always check home directory)
    [[ -d "${HOME}/.claude" ]] && platforms+=("claude")

    # Cursor (project-level)
    [[ -d ".cursor" ]] && platforms+=("cursor")

    # Continue (project-level or user-level)
    [[ -d ".continue" ]] || [[ -d "${HOME}/.continue" ]] && platforms+=("continue")

    # Windsurf (project-level)
    [[ -f ".windsurfrules" ]] && platforms+=("windsurf")

    # Aider (project-level)
    [[ -f ".aider.conf.yml" ]] || [[ -d ".aider" ]] && platforms+=("aider")

    echo "${platforms[@]}"
}
```

**Usage:**
```bash
./install.sh --auto
# Or
./install.sh -a
```

**Example Output:**
```
vdoc installer v2.0.0

Detecting installed AI tools...
✓ Found: claude, cursor, continue

Running adapters...
✓ Generated Claude Code integration
✓ Generated Cursor integration
✓ Generated Continue integration

Installation complete for 3 platforms!
```

---

## Definition of Done
- [ ] `--auto` flag implemented in install.sh
- [ ] Correctly detects 5 supported platforms
- [ ] Runs all matching adapters
- [ ] Shows clear summary output
- [ ] Handles partial failures gracefully

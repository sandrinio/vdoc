# STORY-033: Implement Uninstall Command

## Metadata
| Field | Value |
|-------|-------|
| **Status** | ✅ Complete |
| **Story Points** | 2 |
| **Priority** | P2 - Medium |
| **Parent Epic** | EPIC-004 |

---

## User Story
**As a** developer who no longer needs vdoc
**I want** to cleanly remove vdoc from my project
**So that** I don't have leftover files cluttering my codebase

---

## Acceptance Criteria

### AC1: Remove platform-specific files
- [ ] `uninstall claude` removes `~/.claude/skills/vdoc/`
- [ ] `uninstall cursor` removes `.cursor/rules/vdoc.md`
- [ ] `uninstall windsurf` removes vdoc section from `.windsurfrules`
- [ ] `uninstall aider` removes vdoc config entries
- [ ] `uninstall continue` removes vdoc from `.continue/`

### AC2: Preserve user documentation
- [ ] Do NOT delete `vdocs/` directory (contains user docs)
- [ ] Optionally offer `--all` flag to remove everything
- [ ] Warn user about what will be preserved

### AC3: Clean .gitignore entries
- [ ] Remove vdoc-specific entries from .gitignore
- [ ] Preserve other .gitignore entries

### AC4: Confirmation prompt
- [ ] Interactive: ask for confirmation before deleting
- [ ] Non-interactive: require `--yes` flag

---

## Technical Notes

**Usage:**
```bash
./install.sh uninstall <platform>
./install.sh uninstall --all      # Remove everything including vdocs/
./install.sh uninstall -y claude  # Skip confirmation
```

**Example Output:**
```
vdoc uninstaller

This will remove:
  - ~/.claude/skills/vdoc/SKILL.md
  - .gitignore vdoc entries

This will preserve:
  - vdocs/ (your documentation)
  - vdocs/.vdoc/ (shared tools)

Continue? [y/N] y

✓ Removed Claude Code integration
✓ Updated .gitignore

Uninstall complete. Your documentation in vdocs/ was preserved.
To remove everything: ./install.sh uninstall --all
```

**Partial Uninstall (Section Removal):**
For Windsurf, need to remove only the vdoc section:
```bash
# Remove lines between "# vdoc" and next "# " section
sed -i '/^# vdoc/,/^# [^v]/{ /^# [^v]/!d }' .windsurfrules
```

---

## Definition of Done
- [ ] `install.sh uninstall <platform>` works for all 5 platforms
- [ ] `--all` flag removes vdocs/ directory
- [ ] Confirmation prompt in interactive mode
- [ ] `-y` flag skips confirmation
- [ ] Preserves user documentation by default

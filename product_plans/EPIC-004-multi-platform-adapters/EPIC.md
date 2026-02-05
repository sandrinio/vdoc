# EPIC-004: Multi-Platform Adapters

## Metadata
| Field | Value |
|-------|-------|
| **Status** | ✅ Complete |
| **Ambiguity Score** | 🟡 Medium |
| **Context Source** | Roadmap Phase 2 |
| **Owner** | TBD |
| **Priority** | P1 - High |
| **Tags** | #adapters, #cursor, #windsurf, #aider, #continue |
| **Target Date** | TBD |

---

## 1. The Executive Pitch
> Target Audience: Stakeholders, Business Sponsors, Non-Technical Leads

### 1.1 The Problem
Developers use different AI coding tools (Cursor, Windsurf, Aider, Continue). Each tool has its own instruction file format and conventions. Supporting multiple platforms requires duplicating logic.

### 1.2 The Solution
Implement thin adapter scripts for each platform that transform the universal `instructions.md` into platform-specific formats. Add installer features for multi-platform teams: `--auto` detection, uninstall command, and teammate onboarding via `setup.sh`.

### 1.3 The Value (North Star)
- Support 5 major AI coding platforms with single source of truth
- Teams using mixed tools share the same documentation
- Teammates onboard without internet (use existing vdocs/.vdoc/)

---

## 2. The Scope Boundaries (AI Guardrails)
> Target Audience: Planner Agent (Critical for preventing hallucinations)

### 2.1 IN-SCOPE (Build This)
- [x] Cursor adapter: `adapters/cursor/generate.sh` → `.cursor/rules/vdoc.md`
- [x] Windsurf adapter: `adapters/windsurf/generate.sh` → `.windsurfrules`
- [x] Aider adapter: `adapters/aider/generate.sh` → `.aider.conf.yml` conventions
- [x] Continue adapter: `adapters/continue/generate.sh` → `.continue/` config
- [x] `--auto` flag: detect installed tools and generate all adapters
- [x] Uninstall command: `install.sh uninstall <platform>`
- [x] `setup.sh`: Generate adapter from existing vdocs/.vdoc/instructions.md
- [x] Platform-specific permission model handling in instructions
- [x] Testing each adapter with its respective platform

### 2.2 OUT-OF-SCOPE (Do NOT Build This)
- No new language presets (EPIC-005)
- No advanced features like incremental scanning (EPIC-006)
- No CI/CD or export integrations (EPIC-007)
- No support for platforms without script execution

---

## 3. Context

### 3.1 User Personas
- **Multi-Tool Developer**: Uses Cursor at work, Claude Code personally
- **Team Lead**: Sets up vdoc for team with mixed tool preferences
- **New Teammate**: Joins project, uses different tool than original author

### 3.2 User Journey - Multi-Platform Install
```mermaid
flowchart LR
    A[install.sh --auto] --> B[Detect .cursor/, .continue/, etc.]
    B --> C[Run matching adapters]
    C --> D[Generate all instruction files]
    D --> E[Update .gitignore for each]
```

### 3.3 User Journey - Teammate Onboarding
```mermaid
flowchart LR
    A[git clone project] --> B[vdocs/.vdoc/ already present]
    B --> C[Run setup.sh cursor]
    C --> D[Generate .cursor/rules/vdoc.md]
    D --> E[Ready to use - no download]
```

### 3.4 Technical Requirements

**Platform Instruction Formats:**
| Platform | Output Path | Format |
|----------|-------------|--------|
| Claude Code | ~/.claude/skills/vdoc/SKILL.md | YAML frontmatter + markdown |
| Cursor | .cursor/rules/vdoc.md | Markdown rules file |
| Windsurf | .windsurfrules | Section in rules file |
| Aider | .aider.conf.yml | YAML conventions |
| Continue | .continue/config | JSON/YAML config |

**Permission Model Handling:**
| Platform | Script Execution | Instruction Note |
|----------|------------------|------------------|
| Claude Code | Native bash | No special handling |
| Cursor | May prompt user | Explain what scan.sh does before running |
| Windsurf | Approval required | Note scan.sh is read-only and safe |
| Aider | Explicit /run | Guide AI to suggest /run command |
| Continue | Tool approval | Include approval context |

**Adapter Script Template:**
```bash
#!/bin/bash
# adapters/<platform>/generate.sh
# Reads instructions.md, wraps in platform format, writes output
```

---

## 4. Dependencies

### 4.1 Technical Dependencies
- EPIC-002: install.sh infrastructure and instructions.md
- Each platform's CLI/IDE for testing

### 4.2 Epic Dependencies
- Blocked by: EPIC-002, EPIC-003
- Blocks: EPIC-007 (ecosystem features need platform stability)

---

## 5. Linked Stories
| Story ID | Name | Status | File |
|----------|------|--------|------|
| STORY-028 | Create Cursor adapter | Draft | [STORY-028](STORY-028-cursor-adapter.md) |
| STORY-029 | Create Windsurf adapter | Draft | [STORY-029](STORY-029-windsurf-adapter.md) |
| STORY-030 | Create Aider adapter | Draft | [STORY-030](STORY-030-aider-adapter.md) |
| STORY-031 | Create Continue adapter | Draft | [STORY-031](STORY-031-continue-adapter.md) |
| STORY-032 | Implement --auto flag detection | Draft | [STORY-032](STORY-032-auto-flag.md) |
| STORY-033 | Implement uninstall command | Draft | [STORY-033](STORY-033-uninstall-command.md) |
| STORY-034 | Create setup.sh for teammate onboarding | Draft | [STORY-034](STORY-034-setup-sh.md) |
| STORY-035 | Add platform permission notes | Draft | [STORY-035](STORY-035-permission-notes.md) |

### Implementation Order (Recommended)
1. **STORY-028-031** (Adapters) - Can be done in parallel
2. **STORY-035** (Permission notes) - Integrate into adapters
3. **STORY-032** (--auto flag) - Requires adapters complete
4. **STORY-034** (setup.sh) - Requires adapters complete
5. **STORY-033** (Uninstall) - Can be done anytime

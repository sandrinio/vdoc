# STORY-068: Create GitHub README.md

## Metadata
| Field | Value |
|-------|-------|
| **Parent Epic** | [EPIC-007](EPIC.md) |
| **Status** | Draft |
| **Ambiguity Score** | 🟢 Low |
| **Actor** | Open Source Contributor / Developer |
| **Complexity** | Low (documentation only) |

---

## 1. The Spec (The Contract)

### 1.1 User Story
> As a **Developer discovering vdoc on GitHub**,
> I want a **clear, comprehensive README.md**,
> So that **I understand what vdoc does, how to install it, and how to use it within 2 minutes**.

### 1.2 Detailed Requirements

**Required Sections:**
- [ ] **Hero section**: Name, tagline, badges (version, license, platforms)
- [ ] **What is vdoc?**: 2-3 sentence explanation of the problem and solution
- [ ] **Key Features**: Bullet list of value propositions (zero dependencies, multi-platform, update-first, token efficient)
- [ ] **Platform Support**: Table showing all supported AI coding tools with status
- [ ] **Quick Start**: Installation commands for each platform (curl one-liner)
- [ ] **How It Works**: Brief explanation of scanner → manifest → AI workflows
- [ ] **Project Structure**: Directory tree showing repository layout
- [ ] **Requirements**: Bash 4.0+, POSIX utilities, Git 2.0+
- [ ] **Documentation Links**: Links to product spec, contributing guide, changelog
- [ ] **License**: MIT with link to LICENSE file

**Quality Criteria:**
- [ ] Time to first install command: < 30 seconds of reading
- [ ] No jargon without explanation
- [ ] All code blocks have syntax highlighting
- [ ] Install commands are copy-paste ready
- [ ] Platform table shows Primary/Supported status clearly

### 1.3 Design Decisions (Resolved)

| Decision | Resolution | Rationale |
|----------|------------|-----------|
| **Badges** | shields.io style | Industry standard, recognizable |
| **Install first vs explain first** | Explain first (brief) | User needs to know what they're installing |
| **Platform prominence** | Table format | Quick comparison across tools |
| **Quick Start length** | 3-5 lines max | Get user to first success fast |

---

## 2. The Truth (Executable Tests)

### 2.1 Acceptance Criteria (Gherkin)
```gherkin
Feature: GitHub README

  Scenario: Developer finds install command quickly
    Given I open the README.md on GitHub
    When I scroll to Quick Start section
    Then I see a platform-specific curl command within 5 scroll actions
    And the command is in a code block with bash highlighting

  Scenario: Developer understands what vdoc does
    Given I read the first 3 paragraphs
    Then I understand vdoc generates documentation from code
    And I understand it works with multiple AI coding tools
    And I understand it has zero dependencies

  Scenario: Developer identifies their platform
    Given I look at the Platform Support table
    When I find my AI tool (Claude Code, Cursor, Windsurf, Aider, Continue)
    Then I see whether it's Primary or Supported
    And I see the instruction format used

  Scenario: Developer runs successful install
    Given I copy the curl command for my platform
    When I run it in my project directory
    Then the installer completes without errors
    And I see a confirmation with next steps

  Scenario: Documentation links work
    Given I click on Product Specification link
    Then I navigate to vdoc-product-specification.md
    Given I click on Contributing link
    Then I navigate to CONTRIBUTING.md
    Given I click on Changelog link
    Then I navigate to CHANGELOG.md
```

---

## 3. Technical Context (For Coder Agent)

### 3.1 Affected Files
- `README.md` - Main file to create/update

### 3.2 Content Structure

```markdown
# vdoc

**AI-Powered Product Documentation Generator**

[badges: version, license, platforms]

---

## What is vdoc?
[2-3 sentences: problem → solution → value]

## Key Features
- Zero dependencies (bash + POSIX only)
- Multi-platform (Claude Code, Cursor, Windsurf, Aider, Continue)
- Update-first architecture
- Token efficient

## Platform Support
| Platform | Status | Instruction Format |
|----------|--------|-------------------|
| Claude Code | Primary | SKILL.md |
| Cursor | Primary | .cursor/rules/ |
| ... | ... | ... |

## Quick Start
```bash
curl -fsSL vdoc.dev/install | bash -s -- [platform]
```

## How It Works
1. Scanner → 2. Manifest → 3. AI Workflows → 4. Documentation

## Project Structure
[directory tree]

## Documentation
- [Product Spec](link)
- [Contributing](link)
- [Changelog](link)

## Requirements
- Bash 4.0+
- POSIX utilities
- Git 2.0+

## License
MIT
```

### 3.3 Badge Examples
```markdown
![Version](https://img.shields.io/badge/version-2.0.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Platforms](https://img.shields.io/badge/platforms-5-orange)
```

---

## 4. Notes
- Current README.md exists but may need enhancement
- Should be validated by someone unfamiliar with vdoc
- Consider adding a GIF/screenshot of vdoc in action (future enhancement)
- Ensure all external links are valid before merge

## 5. Design Decision Log

### Explain-First Approach
While "Quick Start" sections often come first, vdoc requires context. A user won't install something they don't understand. The 2-3 sentence explanation provides just enough context before the install command.

### Platform Table Over List
A table allows quick visual scanning to find the user's specific tool. Lists require reading each item. Tables also clearly show the status (Primary vs Supported) at a glance.

### No Feature Comparison with Competitors
README focuses on what vdoc IS, not what competitors aren't. Comparison tables date quickly and invite controversy. Let the product speak for itself.

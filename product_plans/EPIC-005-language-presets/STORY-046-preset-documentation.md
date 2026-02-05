# STORY-046: Write Custom Preset Documentation

## Metadata
| Field | Value |
|-------|-------|
| **Status** | ✅ Complete |
| **Story Points** | 2 |
| **Priority** | P2 - Medium |
| **Parent Epic** | EPIC-005 |

---

## User Story
**As a** developer creating custom presets
**I want** clear documentation on preset format and options
**So that** I can create presets for my framework/language

---

## Acceptance Criteria

### AC1: Preset format reference
- [ ] Document all preset variables
- [ ] Explain variable types and formats
- [ ] Show default values

### AC2: Step-by-step guide
- [ ] How to create a new preset
- [ ] How to test the preset
- [ ] How to validate the preset

### AC3: Examples
- [ ] Full preset example with comments
- [ ] Common customization patterns
- [ ] Framework-specific examples (Next.js, Django, Rails)

### AC4: Troubleshooting
- [ ] Common errors and fixes
- [ ] Debugging tips
- [ ] Validation output interpretation

### AC5: Best practices
- [ ] Naming conventions
- [ ] Pattern efficiency
- [ ] When to extend vs. create new

---

## Technical Notes

**Documentation Location:**
`vdocs/.vdoc/docs/custom-presets.md` (also linked from README)

**Documentation Content:**

```markdown
# Creating Custom Presets

Custom presets allow you to tailor vdoc for your project's unique structure.

## Quick Start

1. Create a preset file:
   ```
   vdocs/.vdoc/presets/custom-myframework.conf
   ```

2. Add required variables:
   ```bash
   PRESET_NAME="custom-myframework"
   PRESET_VERSION="1.0.0"
   ```

3. Test your preset:
   ```bash
   ./vdocs/.vdoc/scan.sh --preset=custom-myframework --validate
   ```

## Preset Variables Reference

### Required Variables

| Variable | Type | Description |
|----------|------|-------------|
| `PRESET_NAME` | string | Unique preset identifier |
| `PRESET_VERSION` | semver | Preset version (e.g., "1.0.0") |

### Optional Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `EXTENDS` | string | - | Parent preset to inherit from |
| `EXCLUDE_DIRS` | space-separated | (none) | Directories to skip |
| `EXCLUDE_FILES` | space-separated | (none) | File patterns to skip |
| `ENTRY_PATTERNS` | space-separated | (none) | Entry point file patterns |
| `DOCSTRING_PATTERN` | regex | - | Start of doc comment |
| `DOCSTRING_END` | regex | - | End of doc comment |
| `DOC_SIGNALS` | multiline | - | Category:glob mappings |

### DOC_SIGNALS Format

```bash
DOC_SIGNALS="
category_name:glob_pattern
another_category:**/pattern/**
"
```

- One signal per line
- Format: `category:pattern`
- Use `**` for recursive matching
- Categories become documentation sections

## Extending Built-in Presets

Instead of starting from scratch, extend an existing preset:

```bash
PRESET_NAME="custom-nextjs"
PRESET_VERSION="1.0.0"
EXTENDS="typescript"

# Only add what's different
EXCLUDE_DIRS="${EXCLUDE_DIRS} .next"

DOC_SIGNALS="
${DOC_SIGNALS}
pages:pages/**
app:app/**
"
```

The `${VARIABLE}` syntax includes the parent's value.

## Full Example: Django Preset

```bash
# Custom preset for Django projects
# File: vdocs/.vdoc/presets/custom-django.conf

PRESET_NAME="custom-django"
PRESET_VERSION="1.0.0"
EXTENDS="python"

# Django-specific exclusions
EXCLUDE_DIRS="${EXCLUDE_DIRS} staticfiles media migrations"

# Django entry points
ENTRY_PATTERNS="manage.py **/wsgi.py **/asgi.py"

# Django-specific categories
DOC_SIGNALS="
${DOC_SIGNALS}
views:**/views.py
views:**/views/**
models:**/models.py
models:**/models/**
urls:**/urls.py
admin:**/admin.py
forms:**/forms.py
serializers:**/serializers.py
middleware:**/middleware.py
middleware:**/middleware/**
management:**/management/**
"
```

## Validation

Always validate your preset before use:

```bash
./vdocs/.vdoc/scan.sh --validate-preset custom-django
```

### Understanding Validation Output

- ✓ Green check: Validation passed
- ⚠ Warning: Non-fatal issue, preset will work
- ✗ Error: Fatal issue, preset won't load

### Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| "PRESET_NAME not defined" | Missing required variable | Add `PRESET_NAME="..."` |
| "Invalid DOC_SIGNAL format" | Missing colon | Use `category:pattern` |
| "Pattern matches no files" | Wrong glob pattern | Test pattern with `ls` |
| "Invalid regex" | Bad escape in DOCSTRING_PATTERN | Test with `grep -E` |

## Best Practices

1. **Start with EXTENDS** - Don't reinvent the wheel
2. **Keep patterns specific** - Avoid overly broad globs
3. **Test with --dry-run** - See what files match before scanning
4. **Version your presets** - Track changes over time
5. **Document your categories** - Add comments explaining signals
6. **Commit presets to repo** - Share with your team

## Framework Examples

### Rails
```bash
EXTENDS="ruby"
DOC_SIGNALS="
controllers:**/controllers/**
models:**/models/**
views:**/views/**
helpers:**/helpers/**
jobs:**/jobs/**
mailers:**/mailers/**
"
```

### Spring Boot
```bash
EXTENDS="java"
DOC_SIGNALS="
controller:**/controller/**
service:**/service/**
repository:**/repository/**
entity:**/entity/**
dto:**/dto/**
config:**/config/**
"
```

### FastAPI
```bash
EXTENDS="python"
DOC_SIGNALS="
routers:**/routers/**
schemas:**/schemas/**
models:**/models/**
crud:**/crud/**
deps:**/deps/**
"
```
```

---

## Definition of Done
- [ ] `custom-presets.md` documentation written
- [ ] All variables documented with examples
- [ ] Step-by-step creation guide complete
- [ ] Framework examples included
- [ ] Troubleshooting section covers common issues
- [ ] Linked from main README
- [ ] Tested by following guide to create new preset

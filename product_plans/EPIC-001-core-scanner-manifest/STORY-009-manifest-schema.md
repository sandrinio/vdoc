# STORY-009: Define _manifest.json Schema

## Metadata
| Field | Value |
|-------|-------|
| **Parent Epic** | [EPIC-001](EPIC.md) |
| **Status** | ✅ Complete |
| **Ambiguity Score** | 🟢 Low |
| **Actor** | AI Tool |
| **Complexity** | Small (schema definition) |

---

## 1. The Spec (The Contract)

### 1.1 User Story
> As an **AI Tool**,  
> I want **a well-defined manifest schema**,  
> So that **I can read/write project documentation state consistently**.

### 1.2 Detailed Requirements
- [ ] Define JSON schema for _manifest.json
- [ ] Include project metadata (name, language, version, timestamp)
- [ ] Include documentation array (pages with covers, audience, description)
- [ ] Include source_index (file → metadata mapping)
- [ ] Support bidirectional links (covers ↔ documented_in)
- [ ] Define all field types and constraints

---

## 2. The Truth (Executable Tests)

### 2.1 Acceptance Criteria (Gherkin)
```gherkin
Feature: Manifest Schema

  Scenario: Valid manifest structure
    Given a _manifest.json file
    Then it has "project" string field
    And it has "language" string field
    And it has "last_updated" ISO-8601 timestamp
    And it has "vdoc_version" semver string
    And it has "documentation" array
    And it has "source_index" object

  Scenario: Documentation entry structure
    Given a documentation entry
    Then it has "path" string (relative path)
    And it has "title" string
    And it has "covers" (array | "auto" | "none")
    And it has "audience" string
    And it has "description" string

  Scenario: Source index entry structure
    Given a source_index entry
    Then it has "hash" string (10 hex chars)
    And it has "category" string
    And it has "description" string
    And it has "description_source" enum (docstring|inferred|analyzed)
    And it has "documented_in" array of paths
```

---

## 3. Technical Context (For Coder Agent)

### 3.1 Affected Files
- `core/templates/manifest-schema.json` - JSON Schema definition
- `core/instructions.md` - Already documents schema (verify consistency)

### 3.2 Full Schema Definition
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "vdoc Manifest",
  "type": "object",
  "required": ["project", "language", "last_updated", "vdoc_version", "documentation", "source_index"],
  "properties": {
    "project": {
      "type": "string",
      "description": "Project name (from package.json, pyproject.toml, or directory name)"
    },
    "language": {
      "type": "string",
      "description": "Primary language (typescript, javascript, python, go, rust, java, default)"
    },
    "last_updated": {
      "type": "string",
      "format": "date-time",
      "description": "ISO-8601 timestamp of last update"
    },
    "vdoc_version": {
      "type": "string",
      "pattern": "^\\d+\\.\\d+\\.\\d+$",
      "description": "vdoc version that generated this manifest"
    },
    "documentation": {
      "type": "array",
      "items": {
        "$ref": "#/definitions/DocumentationEntry"
      }
    },
    "source_index": {
      "type": "object",
      "additionalProperties": {
        "$ref": "#/definitions/SourceEntry"
      }
    }
  },
  "definitions": {
    "DocumentationEntry": {
      "type": "object",
      "required": ["path", "title", "covers", "audience", "description"],
      "properties": {
        "path": {
          "type": "string",
          "description": "Relative path to documentation file"
        },
        "title": {
          "type": "string",
          "description": "Human-readable title"
        },
        "covers": {
          "oneOf": [
            { "type": "array", "items": { "type": "string" } },
            { "type": "string", "enum": ["auto", "none"] }
          ],
          "description": "Source files/patterns this doc covers"
        },
        "audience": {
          "type": "string",
          "description": "Target audience for this documentation"
        },
        "description": {
          "type": "string",
          "description": "Brief summary of documentation content"
        }
      }
    },
    "SourceEntry": {
      "type": "object",
      "required": ["hash", "category", "description", "description_source", "documented_in"],
      "properties": {
        "hash": {
          "type": "string",
          "pattern": "^[a-f0-9]{10}$",
          "description": "Truncated SHA-256 hash at last documentation"
        },
        "category": {
          "type": "string",
          "description": "Functional category from DOC_SIGNALS"
        },
        "description": {
          "type": "string",
          "description": "What this file does"
        },
        "description_source": {
          "type": "string",
          "enum": ["docstring", "inferred", "analyzed"],
          "description": "How the description was derived"
        },
        "documented_in": {
          "type": "array",
          "items": { "type": "string" },
          "description": "Doc pages that reference this file"
        }
      }
    }
  }
}
```

### 3.3 Example Manifest
```json
{
  "project": "my-api",
  "language": "typescript",
  "last_updated": "2026-02-05T14:30:00Z",
  "vdoc_version": "2.0.0",
  "documentation": [
    {
      "path": "vdocs/overview.md",
      "title": "Project Overview",
      "covers": ["README.md", "package.json"],
      "audience": "all team members",
      "description": "High-level overview: purpose, tech stack, getting started"
    },
    {
      "path": "vdocs/api-reference.md",
      "title": "API Reference",
      "covers": ["src/api/**/*.ts"],
      "audience": "backend engineers",
      "description": "REST endpoints, request/response formats"
    }
  ],
  "source_index": {
    "src/api/users.ts": {
      "hash": "a3f2c1d4e5",
      "category": "api_routes",
      "description": "User CRUD operations and profile management",
      "description_source": "docstring",
      "documented_in": ["vdocs/api-reference.md"]
    },
    "src/utils/logger.ts": {
      "hash": "b7d4e2f1a0",
      "category": "utils",
      "description": "Logging utility",
      "description_source": "inferred",
      "documented_in": ["vdocs/overview.md"]
    }
  }
}
```

---

## 4. Notes
- Manifest is the contract between scanner, AI, and update workflow
- Bidirectional linking enables efficient updates (file changed → find affected docs)
- `covers` supports globs for flexible file groupings
- `description_source` tracks tiered strategy for transparency

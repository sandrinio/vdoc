# STORY-085: Manifest Schema v3

## Metadata
| Field | Value |
|-------|-------|
| **Parent Epic** | [EPIC-008](EPIC.md) |
| **Status** | Draft |
| **Ambiguity Score** | Low |
| **Actor** | Developer |
| **Complexity** | Medium |
| **Priority** | P1 - High |

---

## 1. The Spec (The Contract)

### 1.1 User Story
> As a **vdoc User**,
> I want the manifest to contain features, functions, and dependencies,
> So that **AI tools can generate feature-based documentation**.

### 1.2 Detailed Requirements
- [ ] Define manifest v3 JSON schema
- [ ] Add `features` section for feature groups
- [ ] Add `functions` section for function details
- [ ] Add `endpoints` section for API routes
- [ ] Add `dependency_graph` section
- [ ] Maintain backward compatibility with v2
- [ ] Add migration from v2 to v3
- [ ] Version detection and auto-upgrade

---

## 2. The Truth (Executable Tests)

### 2.1 Acceptance Criteria (Gherkin)
```gherkin
Feature: Manifest Schema v3

  Scenario: Create v3 manifest
    Given a new vdoc project
    When vdoc scan runs
    Then manifest has version "3.0"
    And manifest contains features section
    And manifest contains functions section

  Scenario: Upgrade v2 to v3
    Given an existing v2 manifest
    When vdoc scan runs
    Then manifest is upgraded to v3
    And source_index is preserved
    And new sections are populated

  Scenario: Backward compatibility
    Given a v3 manifest
    When AI reads source_index
    Then source_index structure matches v2
```

---

## 3. Technical Context (For Coder Agent)

### 3.1 Affected Files
- `core/manifest.sh` - Schema generation
- `core/scan.sh` - Migration logic
- `vdocs/_manifest.json` - Output file

### 3.2 Schema Definition

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "vdoc Manifest v3",
  "type": "object",
  "required": ["manifest_version", "project", "last_updated"],
  "properties": {
    "manifest_version": {
      "type": "string",
      "enum": ["3.0"],
      "description": "Schema version"
    },
    "project": {
      "type": "string",
      "description": "Project name"
    },
    "language": {
      "type": "string",
      "description": "Primary language"
    },
    "last_updated": {
      "type": "string",
      "format": "date-time"
    },
    "features": {
      "$ref": "#/definitions/features"
    },
    "functions": {
      "$ref": "#/definitions/functions"
    },
    "endpoints": {
      "$ref": "#/definitions/endpoints"
    },
    "dependency_graph": {
      "$ref": "#/definitions/dependency_graph"
    },
    "source_index": {
      "$ref": "#/definitions/source_index"
    },
    "quality": {
      "$ref": "#/definitions/quality"
    }
  },
  "definitions": {
    "features": {
      "type": "object",
      "additionalProperties": {
        "type": "object",
        "properties": {
          "type": { "const": "feature_group" },
          "files": { "type": "array", "items": { "type": "string" } },
          "primary_file": { "type": "string" },
          "functions": { "type": "array", "items": { "type": "string" } },
          "endpoints": { "type": "array", "items": { "type": "string" } },
          "description": { "type": "string" },
          "confidence": { "type": "number", "minimum": 0, "maximum": 1 }
        }
      }
    },
    "functions": {
      "type": "object",
      "additionalProperties": {
        "type": "object",
        "properties": {
          "type": { "enum": ["function", "method", "class"] },
          "file": { "type": "string" },
          "line": { "type": "integer" },
          "signature": { "type": "string" },
          "description": { "type": ["string", "null"] },
          "calls": { "type": "array", "items": { "type": "string" } },
          "called_by": { "type": "array", "items": { "type": "string" } },
          "feature": { "type": "string" }
        }
      }
    },
    "endpoints": {
      "type": "object",
      "additionalProperties": {
        "type": "object",
        "properties": {
          "method": { "type": "string" },
          "path": { "type": "string" },
          "file": { "type": "string" },
          "handler": { "type": "string" },
          "line": { "type": "integer" },
          "feature": { "type": "string" },
          "framework": { "type": "string" }
        }
      }
    },
    "dependency_graph": {
      "type": "object",
      "additionalProperties": {
        "type": "object",
        "properties": {
          "imports": { "type": "array", "items": { "type": "string" } },
          "external": { "type": "array", "items": { "type": "string" } },
          "exports": { "type": "array", "items": { "type": "string" } }
        }
      }
    },
    "source_index": {
      "type": "object",
      "description": "Backward compatible with v2",
      "additionalProperties": {
        "type": "object",
        "properties": {
          "hash": { "type": ["string", "null"] },
          "category": { "type": "string" },
          "description": { "type": ["string", "null"] }
        }
      }
    },
    "quality": {
      "type": "object",
      "properties": {
        "overall_score": { "type": "integer" },
        "documented_files": { "type": "integer" },
        "total_files": { "type": "integer" }
      }
    }
  }
}
```

### 3.3 Full Example

```json
{
  "manifest_version": "3.0",
  "project": "my-app",
  "language": "typescript",
  "last_updated": "2026-02-06T12:00:00Z",

  "features": {
    "Authentication": {
      "type": "feature_group",
      "files": [
        "src/auth/login.ts",
        "src/auth/logout.ts",
        "src/middleware/jwt.ts"
      ],
      "primary_file": "src/auth/login.ts",
      "functions": ["login", "logout", "validateJWT", "refreshToken"],
      "endpoints": ["/api/auth/login", "/api/auth/logout", "/api/auth/refresh"],
      "description": "User authentication and session management",
      "confidence": 0.92
    },
    "User Management": {
      "type": "feature_group",
      "files": [
        "src/api/users.ts",
        "src/models/User.ts",
        "src/services/UserService.ts"
      ],
      "primary_file": "src/api/users.ts",
      "functions": ["createUser", "getUser", "updateUser", "deleteUser"],
      "endpoints": ["/api/users", "/api/users/:id"],
      "description": "CRUD operations for user accounts",
      "confidence": 0.88
    }
  },

  "functions": {
    "src/auth/login.ts::login": {
      "type": "function",
      "file": "src/auth/login.ts",
      "line": 15,
      "signature": "login(email: string, password: string): Promise<Token>",
      "description": "Authenticate user with email and password",
      "calls": ["validatePassword", "generateJWT"],
      "called_by": ["POST /api/auth/login"],
      "feature": "Authentication"
    },
    "src/services/UserService.ts::UserService": {
      "type": "class",
      "file": "src/services/UserService.ts",
      "line": 10,
      "description": "Service for user operations",
      "feature": "User Management"
    }
  },

  "endpoints": {
    "POST /api/auth/login": {
      "method": "POST",
      "path": "/api/auth/login",
      "file": "src/api/auth.ts",
      "handler": "loginHandler",
      "line": 25,
      "feature": "Authentication",
      "framework": "express"
    },
    "GET /api/users": {
      "method": "GET",
      "path": "/api/users",
      "file": "src/api/users.ts",
      "handler": "listUsers",
      "line": 12,
      "feature": "User Management",
      "framework": "express"
    },
    "GET /api/users/:id": {
      "method": "GET",
      "path": "/api/users/:id",
      "file": "src/api/users.ts",
      "handler": "getUserById",
      "line": 30,
      "feature": "User Management",
      "framework": "express"
    }
  },

  "dependency_graph": {
    "src/api/users.ts": {
      "imports": ["src/services/UserService.ts", "src/middleware/auth.ts"],
      "external": ["express"],
      "exports": ["listUsers", "getUserById", "createUser"]
    },
    "src/services/UserService.ts": {
      "imports": ["src/models/User.ts", "src/utils/db.ts"],
      "external": [],
      "exports": ["UserService"]
    },
    "src/auth/login.ts": {
      "imports": ["src/utils/jwt.ts", "src/models/User.ts"],
      "external": ["bcrypt"],
      "exports": ["login", "validatePassword"]
    }
  },

  "source_index": {
    "src/api/users.ts": {
      "hash": "a1b2c3d4",
      "category": "api",
      "description": "User API endpoints"
    },
    "src/auth/login.ts": {
      "hash": "e5f6g7h8",
      "category": "auth",
      "description": "Login functionality"
    }
  },

  "quality": {
    "overall_score": 72,
    "documented_files": 18,
    "total_files": 25,
    "documented_features": 4,
    "total_features": 5
  }
}
```

### 3.4 Migration Logic

**core/manifest.sh additions:**
```bash
#!/usr/bin/env bash

MANIFEST_VERSION="3.0"

migrate_manifest() {
    local manifest="$1"

    # Check current version
    local version
    version=$(jq -r '.manifest_version // "2.0"' "$manifest")

    case "$version" in
        "2.0"|"2."*)
            migrate_v2_to_v3 "$manifest"
            ;;
        "3.0")
            # Already v3, no migration needed
            return 0
            ;;
        *)
            log_warning "Unknown manifest version: $version"
            return 1
            ;;
    esac
}

migrate_v2_to_v3() {
    local manifest="$1"

    log_info "Migrating manifest from v2 to v3..."

    # Add new sections with empty defaults
    jq --arg version "$MANIFEST_VERSION" '
        .manifest_version = $version |
        .features = (.features // {}) |
        .functions = (.functions // {}) |
        .endpoints = (.endpoints // {}) |
        .dependency_graph = (.dependency_graph // {})
    ' "$manifest" > "${manifest}.tmp" && mv "${manifest}.tmp" "$manifest"

    log_success "Migrated to manifest v3"
}

create_manifest_v3() {
    local project="$1"
    local language="$2"

    cat << EOF
{
  "manifest_version": "$MANIFEST_VERSION",
  "project": "$project",
  "language": "$language",
  "last_updated": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "features": {},
  "functions": {},
  "endpoints": {},
  "dependency_graph": {},
  "source_index": {},
  "quality": {
    "overall_score": 0,
    "documented_files": 0,
    "total_files": 0
  }
}
EOF
}
```

### 3.5 Validation

```bash
validate_manifest() {
    local manifest="$1"

    # Required fields
    local required=("manifest_version" "project" "last_updated")
    for field in "${required[@]}"; do
        if ! jq -e ".$field" "$manifest" >/dev/null 2>&1; then
            log_error "Missing required field: $field"
            return 1
        fi
    done

    # Version check
    local version
    version=$(jq -r '.manifest_version' "$manifest")
    if [[ "$version" != "3.0" ]] && [[ "$version" != "2."* ]]; then
        log_error "Unsupported manifest version: $version"
        return 1
    fi

    log_success "Manifest validation passed"
    return 0
}
```

---

## 4. Notes

- Keep source_index for backward compatibility with existing adapters
- Features section is the primary data for AI documentation
- Functions section provides drill-down details
- Endpoints section enables API documentation
- Quality section should include feature coverage metrics

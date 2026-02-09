# STORY-088: Update Instructions for Feature-Based Documentation

## Metadata
| Field | Value |
|-------|-------|
| **Parent Epic** | [EPIC-008](EPIC.md) |
| **Status** | Draft |
| **Ambiguity Score** | Low |
| **Actor** | Developer |
| **Complexity** | Medium |
| **Priority** | P2 - Medium |

---

## 1. The Spec (The Contract)

### 1.1 User Story
> As an **AI Tool User**,
> I want the AI instructions updated to use the new feature-based manifest,
> So that **AI generates documentation organized by feature, not by file**.

### 1.2 Detailed Requirements
- [ ] Update instructions.md to reference manifest v3 schema
- [ ] Add guidance for feature-based documentation
- [ ] Update doc creation guidelines to use feature names
- [ ] Add examples of feature-based docs
- [ ] Update quality metrics for feature coverage
- [ ] Maintain backward compatibility with v2 manifests

---

## 2. The Truth (Executable Tests)

### 2.1 Acceptance Criteria (Gherkin)
```gherkin
Feature: Feature-Based Documentation Instructions

  Scenario: AI reads feature manifest
    Given manifest v3 with features section
    When AI follows instructions
    Then AI creates docs named after features
    And docs reference feature functions

  Scenario: Documentation structure
    Given features: "Authentication", "User Management"
    When AI generates documentation
    Then creates authentication.md
    And creates user-management.md
    And NOT auth-ts.md or user-service-ts.md

  Scenario: Backward compatibility
    Given manifest v2 without features
    When AI follows instructions
    Then AI falls back to file-based documentation
```

---

## 3. Technical Context (For Coder Agent)

### 3.1 Affected Files
- `adapters/instructions.md` - Main AI instructions
- `adapters/claude/generate.sh` - Claude adapter
- `adapters/cursor/generate.sh` - Cursor adapter

### 3.2 Updated Instructions Structure

**adapters/instructions.md (additions):**

```markdown
## Feature-Based Documentation (v3)

When the manifest contains a `features` section, organize documentation by feature:

### Reading Features

```json
{
  "features": {
    "Authentication": {
      "files": ["src/auth/login.ts", "src/middleware/jwt.ts"],
      "functions": ["login", "logout", "validateJWT"],
      "endpoints": ["/api/auth/login", "/api/auth/logout"],
      "description": "User authentication and session management"
    }
  }
}
```

### Documentation Structure

For each feature in the manifest, create a documentation file:

| Feature | Documentation File |
|---------|-------------------|
| Authentication | `vdocs/authentication.md` |
| User Management | `vdocs/user-management.md` |
| API Endpoints | `vdocs/api.md` |

### Feature Documentation Template

```markdown
# [Feature Name]

## Overview
[Feature description from manifest or AI-generated summary]

## Functions

### `functionName()`
- **File:** `src/path/to/file.ts:lineNumber`
- **Signature:** `functionName(param: Type): ReturnType`
- **Description:** [From docstring or AI summary]
- **Called by:** [List from dependency_graph]
- **Calls:** [List from dependency_graph]

## API Endpoints

### `POST /api/auth/login`
- **Handler:** `loginHandler`
- **File:** `src/api/auth.ts:25`
- **Description:** Authenticate user and return JWT token

## Related Files
- [src/auth/login.ts](../src/auth/login.ts) - Login implementation
- [src/middleware/jwt.ts](../src/middleware/jwt.ts) - JWT validation
```

### Priority Order

1. **Features section** (if exists): Create feature-based docs
2. **Endpoints section** (if exists): Create API documentation
3. **Source index** (fallback): Create file-based docs

### Feature Coverage Metrics

When updating quality:
- `documented_features`: Features with documentation files
- `total_features`: Total features in manifest
- Feature coverage = documented_features / total_features
```

### 3.3 Documentation Naming Convention

| Feature Name | File Name | Rule |
|--------------|-----------|------|
| Authentication | `authentication.md` | lowercase |
| User Management | `user-management.md` | kebab-case |
| API Endpoints | `api-endpoints.md` | kebab-case |
| E-commerce Cart | `e-commerce-cart.md` | kebab-case |

```javascript
function featureToFilename(featureName) {
  return featureName
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '')
    + '.md';
}
```

### 3.4 Feature Doc Content Guidelines

**MUST Include:**
- Feature overview (from manifest or generated)
- List of functions with signatures
- API endpoints (if any)
- Links to source files

**SHOULD Include:**
- Usage examples
- Related features (from dependency graph)
- Configuration options

**AVOID:**
- Line-by-line code explanations
- Implementation details irrelevant to users
- Duplicating information across feature docs

### 3.5 Example: Authentication Feature Doc

```markdown
# Authentication

## Overview
Handles user authentication including login, logout, and JWT token management.

## Key Functions

### `login(email, password)`
Authenticates a user with email and password credentials.

- **Location:** [src/auth/login.ts:15](../src/auth/login.ts#L15)
- **Parameters:**
  - `email: string` - User's email address
  - `password: string` - User's password
- **Returns:** `Promise<Token>` - JWT token on success
- **Throws:** `AuthError` - Invalid credentials

### `validateJWT(token)`
Validates and decodes a JWT token.

- **Location:** [src/middleware/jwt.ts:30](../src/middleware/jwt.ts#L30)
- **Parameters:**
  - `token: string` - JWT token from Authorization header
- **Returns:** `DecodedToken | null`

## API Endpoints

| Method | Path | Handler | Description |
|--------|------|---------|-------------|
| POST | `/api/auth/login` | `loginHandler` | User login |
| POST | `/api/auth/logout` | `logoutHandler` | User logout |
| POST | `/api/auth/refresh` | `refreshHandler` | Refresh token |

## Related Features
- [User Management](user-management.md) - User accounts
- [API](api.md) - Protected endpoints

## Files
- `src/auth/login.ts` - Login logic
- `src/auth/logout.ts` - Logout logic
- `src/middleware/jwt.ts` - JWT middleware
- `src/utils/password.ts` - Password hashing
```

### 3.6 Backward Compatibility

```markdown
## Manifest Version Detection

Check manifest version before generating documentation:

```javascript
const manifestVersion = manifest.manifest_version || '2.0';

if (manifestVersion.startsWith('3.')) {
  // Use feature-based documentation
  generateFeatureDocs(manifest.features);
} else {
  // Fallback to file-based documentation
  generateFileDocs(manifest.source_index);
}
```

### v2 Manifest Handling
For v2 manifests without features section:
1. Check for `source_index`
2. Group files by directory/category
3. Create docs based on categories
4. Notify user to run `vdoc scan` for feature detection
```

### 3.7 Quality Updates

Add to quality calculation:

```bash
# Feature coverage metrics
calculate_feature_coverage() {
    local manifest="$1"
    local vdocs_dir="$2"

    local total_features
    total_features=$(jq '.features | length' "$manifest")

    local documented=0
    for feature in $(jq -r '.features | keys[]' "$manifest"); do
        local filename
        filename=$(echo "$feature" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g').md

        if [[ -f "$vdocs_dir/$filename" ]]; then
            ((documented++))
        fi
    done

    echo "Documented features: $documented / $total_features"
}
```

---

## 4. Notes

- Feature-based docs are more useful for non-developers
- Keep backward compatibility with v2 manifests
- Feature names should be human-friendly
- Link back to source files for developers who want details
- Consider generating index.md listing all features

# STORY-084: Feature Clustering Algorithm

## Metadata
| Field | Value |
|-------|-------|
| **Parent Epic** | [EPIC-008](EPIC.md) |
| **Status** | Draft |
| **Ambiguity Score** | Medium |
| **Actor** | Developer |
| **Complexity** | Medium |
| **Priority** | P2 - Medium |

---

## 1. The Spec (The Contract)

### 1.1 User Story
> As a **Documentation Reader**,
> I want related code grouped into logical features,
> So that **I can understand the codebase by capability, not by file**.

### 1.2 Detailed Requirements
- [ ] Group related files into feature clusters
- [ ] Use multiple signals: directory structure, imports, naming
- [ ] Auto-suggest feature names based on code patterns
- [ ] Support manual feature overrides in config
- [ ] Output `features` section in manifest
- [ ] Handle files that belong to multiple features

---

## 2. The Truth (Executable Tests)

### 2.1 Acceptance Criteria (Gherkin)
```gherkin
Feature: Feature Clustering

  Scenario: Cluster by directory convention
    Given files in src/auth/ directory
    When vdoc clusters features
    Then an "Authentication" feature is created
    And all auth files are grouped together

  Scenario: Cluster by dependency
    Given fileA imports fileB
    And fileA imports fileC
    When vdoc clusters features
    Then fileA, fileB, fileC are in same cluster

  Scenario: Name feature from code patterns
    Given files containing "User" in names and functions
    When vdoc suggests feature name
    Then "User Management" is suggested
```

---

## 3. Technical Context (For Coder Agent)

### 3.1 Affected Files
- `core/features.sh` - Clustering logic
- `core/presets/features.conf` - Feature naming rules
- `core/manifest.sh` - Features section output

### 3.2 Clustering Signals

**1. Directory-based (Primary):**
```
src/auth/           → "Authentication"
src/users/          → "User Management"
src/api/            → "API"
src/components/     → "UI Components"
pages/api/          → "API Routes"
```

**2. Import-based (Secondary):**
```
Files that share many imports → Same feature
Files that import each other → Same feature
```

**3. Naming-based (Tertiary):**
```
*User*, *Auth*, *Login* → "Authentication"
*Product*, *Cart*, *Order* → "E-commerce"
*Test*, *Spec*            → "Testing"
```

**4. Export-based:**
```
Files exporting similar types → Same feature
API endpoint handlers → "API"
```

### 3.3 Feature Naming Rules

**core/presets/features.conf:**
```bash
# Feature naming conventions
# Pattern → Feature Name

# Directory patterns
FEATURE_DIR_auth="Authentication"
FEATURE_DIR_users="User Management"
FEATURE_DIR_api="API"
FEATURE_DIR_components="UI Components"
FEATURE_DIR_hooks="React Hooks"
FEATURE_DIR_utils="Utilities"
FEATURE_DIR_models="Data Models"
FEATURE_DIR_services="Services"
FEATURE_DIR_middleware="Middleware"
FEATURE_DIR_config="Configuration"

# Naming patterns (code tokens)
FEATURE_TOKEN_user="User Management"
FEATURE_TOKEN_auth="Authentication"
FEATURE_TOKEN_login="Authentication"
FEATURE_TOKEN_product="Product Management"
FEATURE_TOKEN_order="Order Management"
FEATURE_TOKEN_payment="Payments"
FEATURE_TOKEN_cart="Shopping Cart"
```

### 3.4 Clustering Algorithm

```
CLUSTERING ALGORITHM:

1. Initial Grouping (by directory):
   - Group files by their parent directory
   - Apply FEATURE_DIR_* naming

2. Merge by Dependency:
   - For each file pair with shared imports > threshold:
     - If in different clusters, consider merging
   - For each file pair where one imports the other:
     - Place in same cluster (importer's cluster wins)

3. Split Large Clusters:
   - If cluster > MAX_CLUSTER_SIZE:
     - Use naming patterns to split
     - Check for sub-directories

4. Name Refinement:
   - Analyze function/class names in cluster
   - Check for dominant naming patterns
   - Apply FEATURE_TOKEN_* naming

5. Validate:
   - No cluster has > 20 files (warn if so)
   - No orphan files (assign to "Miscellaneous")
```

### 3.5 Implementation

**core/features.sh:**
```bash
#!/usr/bin/env bash
# Feature clustering

cluster_features() {
    local manifest="$1"
    local dep_graph="$2"

    # Step 1: Initial directory-based clusters
    local clusters
    clusters=$(group_by_directory "$manifest")

    # Step 2: Merge by dependency relationships
    clusters=$(merge_by_dependency "$clusters" "$dep_graph")

    # Step 3: Split oversized clusters
    clusters=$(split_large_clusters "$clusters" "$manifest")

    # Step 4: Name features
    clusters=$(name_features "$clusters" "$manifest")

    # Step 5: Output
    echo "$clusters"
}

group_by_directory() {
    local manifest="$1"
    jq -r '.source_index | to_entries[] | .key' "$manifest" | while read -r file; do
        local dir
        dir=$(dirname "$file" | sed 's|^src/||' | cut -d'/' -f1)

        # Look up feature name
        local feature_name
        feature_name=$(get_feature_name_for_dir "$dir")

        echo "$file|$feature_name"
    done | jq -Rs '
        split("\n") | map(select(length > 0)) |
        map(split("|")) |
        group_by(.[1]) |
        map({
            name: .[0][1],
            files: map(.[0])
        })
    '
}

get_feature_name_for_dir() {
    local dir="$1"

    # Check config
    local var="FEATURE_DIR_${dir}"
    if [[ -n "${!var:-}" ]]; then
        echo "${!var}"
        return
    fi

    # Default: Title case the directory name
    echo "$dir" | sed 's/.*/\u&/'
}

merge_by_dependency() {
    local clusters="$1"
    local dep_graph="$2"

    # For each pair of clusters, count cross-imports
    # Merge if > 50% of files import from other cluster
    echo "$clusters" | jq --argjson deps "$dep_graph" '
        # Simplified: merge clusters where primary file imports from another
        .
    '
}

name_features() {
    local clusters="$1"
    local manifest="$2"

    echo "$clusters" | jq '
        map(
            # Analyze filenames for patterns
            .files as $files |
            ($files | map(split("/")[-1]) | join(" ")) as $names |

            # Check for common patterns
            if ($names | test("user|User")) then .name = "User Management"
            elif ($names | test("auth|Auth|login|Login")) then .name = "Authentication"
            elif ($names | test("api|route|Route")) then .name = "API"
            else .
            end
        )
    '
}
```

### 3.6 Manifest Output

```json
{
  "features": {
    "Authentication": {
      "type": "feature_group",
      "files": [
        "src/auth/login.ts",
        "src/auth/logout.ts",
        "src/middleware/jwt.ts",
        "src/utils/password.ts"
      ],
      "primary_file": "src/auth/login.ts",
      "functions": ["login", "logout", "validateJWT", "hashPassword"],
      "endpoints": ["/api/auth/login", "/api/auth/logout"],
      "confidence": 0.85,
      "auto_named": true
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
      "confidence": 0.92,
      "auto_named": true
    }
  }
}
```

### 3.7 Manual Override

**vdocs/.vdoc/features.json:**
```json
{
  "overrides": {
    "src/utils/special.ts": "Core Utilities",
    "src/legacy/*": "Legacy Code"
  },
  "rename": {
    "Auth": "Security & Authentication"
  },
  "ignore": [
    "src/test/**",
    "src/**/*.test.ts"
  ]
}
```

---

## 4. Notes

- Start simple: directory-based clustering
- Add dependency-based refinement incrementally
- Keep cluster sizes reasonable (5-15 files ideal)
- Allow manual overrides for edge cases
- Confidence score helps AI decide when to trust auto-names

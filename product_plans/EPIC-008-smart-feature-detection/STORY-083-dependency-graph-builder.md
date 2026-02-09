# STORY-083: Dependency Graph Builder

## Metadata
| Field | Value |
|-------|-------|
| **Parent Epic** | [EPIC-008](EPIC.md) |
| **Status** | Draft |
| **Ambiguity Score** | Medium |
| **Actor** | Developer |
| **Complexity** | High |
| **Priority** | P2 - Medium |

---

## 1. The Spec (The Contract)

### 1.1 User Story
> As a **Developer**,
> I want vdoc to understand what code calls what,
> So that **documentation shows relationships between components**.

### 1.2 Detailed Requirements
- [ ] Parse import statements to build file dependency graph
- [ ] Track function calls within files
- [ ] Identify which functions call which
- [ ] Detect circular dependencies
- [ ] Output `dependency_graph` section in manifest
- [ ] Support TypeScript/JavaScript imports
- [ ] Support Python imports

---

## 2. The Truth (Executable Tests)

### 2.1 Acceptance Criteria (Gherkin)
```gherkin
Feature: Dependency Graph Building

  Scenario: Build file-level dependency graph
    Given a project with multiple TypeScript files
    When vdoc analyzes imports
    Then manifest contains dependency_graph section
    And each file lists its dependencies

  Scenario: Detect function call relationships
    Given a file where functionA calls functionB
    When vdoc analyzes the file
    Then manifest shows functionA depends on functionB

  Scenario: Handle circular dependencies
    Given fileA imports fileB
    And fileB imports fileA
    When vdoc analyzes the project
    Then circular dependency is detected and flagged
```

---

## 3. Technical Context (For Coder Agent)

### 3.1 Affected Files
- `tools/parse-ast.js` - Add import/call extraction
- `core/features.sh` - Add dependency analysis
- `core/manifest.sh` - Add dependency_graph section

### 3.2 Import Patterns

**TypeScript/JavaScript:**
```typescript
// Named imports
import { UserService } from './services/user';

// Default imports
import express from 'express';

// Namespace imports
import * as utils from './utils';

// Side-effect imports
import './polyfills';

// Dynamic imports
const module = await import('./lazy-module');

// Require (CommonJS)
const fs = require('fs');
```

**Python:**
```python
# Absolute imports
from app.services.user import UserService

# Relative imports
from ..utils import helpers

# Direct imports
import os

# Import with alias
import numpy as np
```

### 3.3 Call Analysis

**Input:**
```typescript
// src/api/users.ts
import { UserService } from '../services/user';
import { validateEmail } from '../utils/validation';

export async function createUser(data: UserData) {
  validateEmail(data.email);        // Call to imported function
  const user = new UserService();
  return user.create(data);         // Method call
}
```

**Output:**
```json
{
  "dependency_graph": {
    "src/api/users.ts": {
      "imports": [
        "src/services/user.ts",
        "src/utils/validation.ts"
      ],
      "exports": ["createUser"],
      "calls": {
        "createUser": {
          "calls": ["validateEmail", "UserService.create"],
          "called_by": []
        }
      }
    }
  }
}
```

### 3.4 Tree-sitter Query (Imports)
```scheme
;; ES6 imports
(import_statement
  source: (string) @import.source
  (import_clause
    (named_imports
      (import_specifier
        name: (identifier) @import.name))))

;; Default import
(import_statement
  source: (string) @import.source
  (import_clause
    (identifier) @import.default))

;; CommonJS require
(call_expression
  function: (identifier) @func (#eq? @func "require")
  arguments: (arguments (string) @require.source))
```

### 3.5 Implementation

**tools/parse-ast.js additions:**
```javascript
function extractImports(node, source) {
  const imports = [];

  function walk(n) {
    if (n.type === 'import_statement') {
      const sourceNode = n.childForFieldName('source');
      const importPath = sourceNode.text.replace(/['"]/g, '');

      imports.push({
        path: importPath,
        isRelative: importPath.startsWith('.'),
        specifiers: extractImportSpecifiers(n)
      });
    }

    for (const child of n.children) {
      walk(child);
    }
  }

  walk(node);
  return imports;
}

function extractCallExpressions(node, source) {
  const calls = [];

  function walk(n) {
    if (n.type === 'call_expression') {
      const callee = n.childForFieldName('function');
      calls.push({
        name: callee.text,
        line: n.startPosition.row + 1,
        type: callee.type === 'member_expression' ? 'method' : 'function'
      });
    }

    for (const child of n.children) {
      walk(child);
    }
  }

  walk(node);
  return calls;
}

function resolveImportPath(importPath, currentFile, projectRoot) {
  if (!importPath.startsWith('.')) {
    // External package
    return { type: 'external', package: importPath };
  }

  const currentDir = path.dirname(currentFile);
  let resolved = path.resolve(currentDir, importPath);

  // Try extensions
  const extensions = ['.ts', '.tsx', '.js', '.jsx', '/index.ts', '/index.js'];
  for (const ext of extensions) {
    const candidate = resolved + ext;
    if (fs.existsSync(path.join(projectRoot, candidate))) {
      return { type: 'internal', path: candidate };
    }
  }

  return { type: 'unresolved', path: importPath };
}
```

**core/graph.sh:**
```bash
#!/usr/bin/env bash
# Dependency graph builder

build_dependency_graph() {
    local project_root="$1"
    local manifest="$2"

    # Get all source files from manifest
    local files
    files=$(jq -r '.source_index | keys[]' "$manifest")

    local graph='{}'

    while IFS= read -r file; do
        local deps
        deps=$(extract_file_dependencies "$project_root/$file")

        graph=$(echo "$graph" | jq --arg file "$file" --argjson deps "$deps" \
            '.[$file] = $deps')
    done <<< "$files"

    # Detect circular dependencies
    local circular
    circular=$(detect_circular_deps "$graph")

    # Update manifest
    jq --argjson graph "$graph" --argjson circular "$circular" \
        '.dependency_graph = $graph | .circular_dependencies = $circular' \
        "$manifest" > "${manifest}.tmp" && mv "${manifest}.tmp" "$manifest"
}

detect_circular_deps() {
    local graph="$1"
    # Tarjan's algorithm for strongly connected components
    # Simplified: just detect direct cycles
    local circular='[]'

    # For each file, check if any dependency imports it back
    for file in $(echo "$graph" | jq -r 'keys[]'); do
        for dep in $(echo "$graph" | jq -r --arg f "$file" '.[$f].imports[]? // empty'); do
            local back_imports
            back_imports=$(echo "$graph" | jq -r --arg d "$dep" '.[$d].imports[]? // empty')
            if echo "$back_imports" | grep -q "^$file$"; then
                circular=$(echo "$circular" | jq --arg a "$file" --arg b "$dep" \
                    '. + [[$a, $b]]')
            fi
        done
    done

    echo "$circular"
}
```

### 3.6 Manifest Output
```json
{
  "dependency_graph": {
    "src/api/users.ts": {
      "imports": ["src/services/user.ts", "src/utils/validation.ts"],
      "external": ["express"]
    },
    "src/services/user.ts": {
      "imports": ["src/models/User.ts", "src/utils/db.ts"],
      "external": []
    }
  },
  "circular_dependencies": [
    ["src/a.ts", "src/b.ts"]
  ]
}
```

---

## 4. Notes

- Start with file-level dependencies (imports)
- Function-level call tracking is Phase 2
- Circular dependency detection helps identify architectural issues
- Consider using TypeScript's compiler API for better resolution
- Cache resolved paths for performance

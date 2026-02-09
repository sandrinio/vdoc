# STORY-081: Feature Extraction Engine (TypeScript)

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
> As a **Developer**,
> I want vdoc to extract functions, classes, and methods from my TypeScript code,
> So that **documentation reflects actual code structure, not just files**.

### 1.2 Detailed Requirements
- [ ] Extract function names, signatures, and docstrings
- [ ] Extract class names and methods
- [ ] Extract exported symbols (named exports, default exports)
- [ ] Extract type definitions (interfaces, types)
- [ ] Map functions to their containing file
- [ ] Use tree-sitter when available, regex fallback otherwise
- [ ] Output structured JSON for manifest consumption

---

## 2. The Truth (Executable Tests)

### 2.1 Acceptance Criteria (Gherkin)
```gherkin
Feature: TypeScript Feature Extraction

  Scenario: Extract functions from a TypeScript file
    Given a TypeScript file with functions
    When vdoc extracts features
    Then output contains function names
    And output contains function signatures
    And output contains JSDoc descriptions

  Scenario: Extract classes and methods
    Given a TypeScript file with classes
    When vdoc extracts features
    Then output contains class names
    And output contains method names for each class

  Scenario: Extract exports
    Given a TypeScript file with named exports
    When vdoc extracts features
    Then output identifies exported symbols
```

---

## 3. Technical Context (For Coder Agent)

### 3.1 Affected Files
- `tools/parse-ast.js` - Parser implementation
- `core/features.sh` - Bash wrapper for feature extraction
- `core/presets/typescript.conf` - TypeScript patterns

### 3.2 Input TypeScript Example
```typescript
/**
 * User authentication service
 */
export class AuthService {
  private jwt: JWT;

  /**
   * Login with email and password
   * @param email - User email
   * @param password - User password
   * @returns JWT token
   */
  async login(email: string, password: string): Promise<Token> {
    // implementation
  }

  logout(): void {
    // implementation
  }
}

export function validateEmail(email: string): boolean {
  return email.includes('@');
}

export type UserRole = 'admin' | 'user' | 'guest';
```

### 3.3 Expected Output
```json
{
  "file": "src/auth/service.ts",
  "language": "typescript",
  "features": {
    "classes": [
      {
        "name": "AuthService",
        "description": "User authentication service",
        "line": 4,
        "exported": true,
        "methods": [
          {
            "name": "login",
            "signature": "login(email: string, password: string): Promise<Token>",
            "description": "Login with email and password",
            "async": true,
            "visibility": "public",
            "line": 13
          },
          {
            "name": "logout",
            "signature": "logout(): void",
            "description": null,
            "async": false,
            "visibility": "public",
            "line": 21
          }
        ]
      }
    ],
    "functions": [
      {
        "name": "validateEmail",
        "signature": "validateEmail(email: string): boolean",
        "description": null,
        "exported": true,
        "line": 27
      }
    ],
    "types": [
      {
        "name": "UserRole",
        "kind": "type_alias",
        "exported": true,
        "line": 31
      }
    ],
    "exports": ["AuthService", "validateEmail", "UserRole"]
  }
}
```

### 3.4 Tree-sitter Query (TypeScript)
```scheme
;; Functions
(function_declaration
  name: (identifier) @function.name
  parameters: (formal_parameters) @function.params
  return_type: (type_annotation)? @function.return_type)

;; Arrow functions (exported)
(lexical_declaration
  (variable_declarator
    name: (identifier) @function.name
    value: (arrow_function)))

;; Classes
(class_declaration
  name: (type_identifier) @class.name
  body: (class_body) @class.body)

;; Methods
(method_definition
  name: (property_identifier) @method.name
  parameters: (formal_parameters) @method.params)

;; Exports
(export_statement) @export

;; Type aliases
(type_alias_declaration
  name: (type_identifier) @type.name)

;; Interfaces
(interface_declaration
  name: (type_identifier) @interface.name)
```

### 3.5 Regex Fallback Patterns
```bash
# Function declarations
FUNC_PATTERN='^\s*(export\s+)?(async\s+)?function\s+(\w+)\s*\((.*?)\)'

# Arrow functions
ARROW_PATTERN='^\s*(export\s+)?(const|let)\s+(\w+)\s*=\s*(async\s+)?\(.*?\)\s*=>'

# Class declarations
CLASS_PATTERN='^\s*(export\s+)?class\s+(\w+)'

# Method definitions (inside class)
METHOD_PATTERN='^\s*(async\s+)?(\w+)\s*\((.*?)\)\s*(:\s*\w+)?\s*\{'

# Type/interface
TYPE_PATTERN='^\s*(export\s+)?(type|interface)\s+(\w+)'
```

### 3.6 Implementation

**tools/parse-ast.js:**
```javascript
const Parser = require('web-tree-sitter');

async function extractFeatures(filePath, source) {
  const parser = new Parser();
  const TypeScript = await Parser.Language.load(
    path.join(__dirname, 'tree-sitter-typescript.wasm')
  );
  parser.setLanguage(TypeScript);

  const tree = parser.parse(source);
  const features = {
    classes: [],
    functions: [],
    types: [],
    exports: []
  };

  // Walk AST and extract features
  walkNode(tree.rootNode, features, source);

  return {
    file: filePath,
    language: 'typescript',
    features
  };
}

function walkNode(node, features, source) {
  switch (node.type) {
    case 'function_declaration':
      features.functions.push(extractFunction(node, source));
      break;
    case 'class_declaration':
      features.classes.push(extractClass(node, source));
      break;
    case 'type_alias_declaration':
    case 'interface_declaration':
      features.types.push(extractType(node, source));
      break;
    case 'export_statement':
      features.exports.push(...extractExports(node, source));
      break;
  }

  for (const child of node.children) {
    walkNode(child, features, source);
  }
}
```

**core/features.sh:**
```bash
#!/usr/bin/env bash
# Feature extraction wrapper

extract_features() {
    local file="$1"
    local ext="${file##*.}"

    # Check if Node.js and parser available
    if command -v node &>/dev/null && [[ -f "${VDOC_DIR}/tools/parse-ast.js" ]]; then
        node "${VDOC_DIR}/tools/parse-ast.js" "$file"
    else
        # Fallback to regex-based extraction
        extract_features_regex "$file" "$ext"
    fi
}

extract_features_regex() {
    local file="$1"
    local ext="$2"
    local content
    content=$(<"$file")

    case "$ext" in
        ts|tsx|js|jsx)
            extract_typescript_regex "$file" "$content"
            ;;
        py)
            extract_python_regex "$file" "$content"
            ;;
        *)
            echo "{\"file\": \"$file\", \"features\": {}}"
            ;;
    esac
}
```

---

## 4. Notes

- Start with TypeScript as primary language
- Tree-sitter provides best accuracy
- Regex fallback ensures broad compatibility
- JSDoc comments should be parsed for descriptions
- Consider caching parsed ASTs for incremental updates

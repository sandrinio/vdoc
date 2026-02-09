# STORY-080: Tree-sitter Parser Integration

## Metadata
| Field | Value |
|-------|-------|
| **Parent Epic** | [EPIC-008](EPIC.md) |
| **Status** | Draft |
| **Ambiguity Score** | Medium |
| **Actor** | Developer |
| **Complexity** | High |
| **Priority** | P1 - High |

---

## 1. The Spec (The Contract)

### 1.1 User Story
> As a **vdoc maintainer**,
> I want a parser that extracts code structure (functions, classes, imports),
> So that **we can detect features instead of just files**.

### 1.2 Detailed Requirements
- [ ] Create `tools/parse-ast.js` using tree-sitter
- [ ] Support TypeScript, JavaScript, Python, Go initially
- [ ] Output JSON with: functions, classes, imports, exports
- [ ] Handle missing Node.js gracefully (regex fallback)
- [ ] Parse single file, output to stdout
- [ ] Performance: < 10ms per file

---

## 2. The Truth (Executable Tests)

### 2.1 Acceptance Criteria (Gherkin)
```gherkin
Feature: AST Parser Integration

  Scenario: Parse TypeScript file
    Given a TypeScript file with functions and classes
    When parse-ast.js is run on the file
    Then output contains function names
    And output contains class names
    And output contains import statements

  Scenario: Handle missing Node.js
    Given Node.js is not installed
    When scan.sh tries to parse a file
    Then it falls back to regex-based extraction
    And scan completes successfully

  Scenario: Performance target
    Given 100 TypeScript files
    When parse-ast.js parses all files
    Then total time is under 1 second
```

---

## 3. Technical Context (For Coder Agent)

### 3.1 Affected Files
- `tools/parse-ast.js` (NEW) - Tree-sitter wrapper
- `core/scan.sh` - Call parser, use output
- `package.json` (NEW) - Dependencies

### 3.2 Implementation

**tools/parse-ast.js:**
```javascript
#!/usr/bin/env node
/**
 * AST Parser using tree-sitter
 * Usage: node parse-ast.js <file> [--language ts|js|py|go]
 * Output: JSON with functions, classes, imports
 */

const Parser = require('web-tree-sitter');
const fs = require('fs');
const path = require('path');

const LANGUAGES = {
  ts: 'tree-sitter-typescript',
  tsx: 'tree-sitter-typescript',
  js: 'tree-sitter-javascript',
  jsx: 'tree-sitter-javascript',
  py: 'tree-sitter-python',
  go: 'tree-sitter-go',
};

async function parseFile(filePath, language) {
  await Parser.init();
  const parser = new Parser();

  // Load language grammar
  const langPath = require.resolve(`${LANGUAGES[language]}/grammar.wasm`);
  const Lang = await Parser.Language.load(langPath);
  parser.setLanguage(Lang);

  // Parse file
  const source = fs.readFileSync(filePath, 'utf8');
  const tree = parser.parse(source);

  // Extract features
  const features = {
    file: filePath,
    language,
    functions: [],
    classes: [],
    imports: [],
    exports: [],
  };

  // Walk AST
  walkTree(tree.rootNode, features, source);

  return features;
}

function walkTree(node, features, source) {
  switch (node.type) {
    case 'function_declaration':
    case 'arrow_function':
    case 'method_definition':
      features.functions.push({
        name: getNodeName(node),
        line: node.startPosition.row + 1,
        signature: getSignature(node, source),
      });
      break;

    case 'class_declaration':
      features.classes.push({
        name: getNodeName(node),
        line: node.startPosition.row + 1,
        methods: [],
      });
      break;

    case 'import_statement':
      features.imports.push({
        module: getImportModule(node, source),
        line: node.startPosition.row + 1,
      });
      break;

    case 'export_statement':
      features.exports.push({
        name: getExportName(node, source),
        line: node.startPosition.row + 1,
      });
      break;
  }

  // Recurse
  for (let i = 0; i < node.childCount; i++) {
    walkTree(node.child(i), features, source);
  }
}

// ... helper functions ...

// Main
const [,, filePath, langFlag, langValue] = process.argv;
const ext = path.extname(filePath).slice(1);
const language = langValue || ext;

parseFile(filePath, language)
  .then(features => console.log(JSON.stringify(features, null, 2)))
  .catch(err => {
    console.error(JSON.stringify({ error: err.message }));
    process.exit(1);
  });
```

**Output example:**
```json
{
  "file": "src/api/users.ts",
  "language": "ts",
  "functions": [
    { "name": "getUserById", "line": 10, "signature": "(id: string) => Promise<User>" },
    { "name": "createUser", "line": 25, "signature": "(data: CreateUserInput) => Promise<User>" }
  ],
  "classes": [
    { "name": "UserService", "line": 5, "methods": ["getUser", "create", "delete"] }
  ],
  "imports": [
    { "module": "../models/User", "line": 1 },
    { "module": "../middleware/auth", "line": 2 }
  ],
  "exports": [
    { "name": "getUserById", "line": 10 },
    { "name": "createUser", "line": 25 }
  ]
}
```

**scan.sh integration:**
```bash
# Check if parser available
has_parser() {
    command -v node &>/dev/null && [[ -f "${SCRIPT_DIR}/../tools/parse-ast.js" ]]
}

# Parse file with tree-sitter (or fallback)
parse_file_ast() {
    local file="$1"

    if has_parser; then
        node "${SCRIPT_DIR}/../tools/parse-ast.js" "$file" 2>/dev/null
    else
        # Regex fallback
        extract_functions_regex "$file"
    fi
}

# Regex fallback for TypeScript/JavaScript
extract_functions_regex() {
    local file="$1"
    local functions=()

    # Match: function name(, export function name(, const name = (
    while IFS= read -r line; do
        if [[ "$line" =~ (function|const|let|var)[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*[\(=] ]]; then
            functions+=("${BASH_REMATCH[2]}")
        fi
    done < "$file"

    # Output as JSON
    printf '{"file":"%s","functions":[' "$file"
    local first=true
    for fn in "${functions[@]}"; do
        $first || printf ','
        printf '{"name":"%s"}' "$fn"
        first=false
    done
    printf ']}\n'
}
```

### 3.3 Dependencies

**package.json:**
```json
{
  "name": "vdoc-parser",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "web-tree-sitter": "^0.20.8",
    "tree-sitter-typescript": "^0.20.0",
    "tree-sitter-javascript": "^0.20.0",
    "tree-sitter-python": "^0.20.0",
    "tree-sitter-go": "^0.20.0"
  }
}
```

### 3.4 Fallback Strategy

```
parse_file():
  IF Node.js + parse-ast.js available:
    → Use tree-sitter (accurate)
  ELSE IF language has regex patterns:
    → Use regex extraction (basic)
  ELSE:
    → Skip feature extraction, file-only mode
```

---

## 4. Notes

- Tree-sitter is fast (~1ms per file) and accurate
- Node.js is common in web projects
- Regex fallback ensures vdoc works everywhere
- WASM grammars are ~500KB per language
- Consider bundling grammars in vdoc distribution

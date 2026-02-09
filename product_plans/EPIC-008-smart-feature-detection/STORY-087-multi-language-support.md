# STORY-087: Multi-Language Feature Extraction

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
> As a **Developer with a polyglot codebase**,
> I want vdoc to extract features from Python, Go, and other languages,
> So that **all my code is documented consistently**.

### 1.2 Detailed Requirements
- [ ] Add Python feature extraction (functions, classes, decorators)
- [ ] Add Go feature extraction (functions, structs, interfaces)
- [ ] Add JavaScript/JSX support (functions, components, hooks)
- [ ] Unify extraction output format across languages
- [ ] Language-specific tree-sitter grammars
- [ ] Language-specific regex fallbacks

---

## 2. The Truth (Executable Tests)

### 2.1 Acceptance Criteria (Gherkin)
```gherkin
Feature: Multi-Language Feature Extraction

  Scenario: Extract Python features
    Given a Python file with classes and functions
    When vdoc extracts features
    Then output contains Python functions with signatures
    And output contains Python classes with methods

  Scenario: Extract Go features
    Given a Go file with functions and structs
    When vdoc extracts features
    Then output contains Go functions
    And output contains Go structs with methods

  Scenario: Unified output format
    Given a mixed TypeScript/Python project
    When vdoc extracts features
    Then all features use the same JSON schema
```

---

## 3. Technical Context (For Coder Agent)

### 3.1 Affected Files
- `tools/parse-ast.js` - Multi-language support
- `tools/grammars/` - Tree-sitter WASM files
- `core/presets/python.conf` - Python patterns
- `core/presets/go.conf` - Go patterns

### 3.2 Language-Specific Patterns

---

### 3.3 Python

**Input:**
```python
from flask import Flask
from typing import Optional

class UserService:
    """Service for user operations."""

    def __init__(self, db: Database):
        self.db = db

    def get_user(self, user_id: int) -> Optional[User]:
        """Get user by ID."""
        return self.db.query(User).get(user_id)

    @staticmethod
    def validate_email(email: str) -> bool:
        return '@' in email

@app.route('/users/<int:id>')
def get_user_endpoint(id: int):
    """API endpoint to get user."""
    return UserService().get_user(id)

def create_user(name: str, email: str) -> User:
    """Create a new user."""
    pass
```

**Tree-sitter Query (Python):**
```scheme
;; Functions
(function_definition
  name: (identifier) @function.name
  parameters: (parameters) @function.params
  return_type: (type)? @function.return_type)

;; Classes
(class_definition
  name: (identifier) @class.name
  body: (block) @class.body)

;; Methods (inside class)
(class_definition
  body: (block
    (function_definition
      name: (identifier) @method.name)))

;; Decorators
(decorated_definition
  (decorator
    (call
      function: (attribute) @decorator.name)))

;; Docstrings
(expression_statement
  (string) @docstring)
```

**Output:**
```json
{
  "file": "src/services/user.py",
  "language": "python",
  "features": {
    "classes": [
      {
        "name": "UserService",
        "description": "Service for user operations.",
        "line": 5,
        "methods": [
          {
            "name": "__init__",
            "signature": "__init__(self, db: Database)",
            "line": 8
          },
          {
            "name": "get_user",
            "signature": "get_user(self, user_id: int) -> Optional[User]",
            "description": "Get user by ID.",
            "line": 11,
            "decorators": []
          },
          {
            "name": "validate_email",
            "signature": "validate_email(email: str) -> bool",
            "line": 15,
            "decorators": ["staticmethod"]
          }
        ]
      }
    ],
    "functions": [
      {
        "name": "get_user_endpoint",
        "signature": "get_user_endpoint(id: int)",
        "description": "API endpoint to get user.",
        "line": 19,
        "decorators": ["@app.route('/users/<int:id>')"]
      },
      {
        "name": "create_user",
        "signature": "create_user(name: str, email: str) -> User",
        "description": "Create a new user.",
        "line": 24
      }
    ]
  }
}
```

---

### 3.4 Go

**Input:**
```go
package users

import "context"

// User represents a user in the system.
type User struct {
    ID    int    `json:"id"`
    Name  string `json:"name"`
    Email string `json:"email"`
}

// UserService handles user operations.
type UserService struct {
    db *Database
}

// GetUser retrieves a user by ID.
func (s *UserService) GetUser(ctx context.Context, id int) (*User, error) {
    return s.db.Find(id)
}

// CreateUser creates a new user.
func CreateUser(name, email string) (*User, error) {
    return &User{Name: name, Email: email}, nil
}

// UserRepository defines the interface for user storage.
type UserRepository interface {
    Find(id int) (*User, error)
    Save(user *User) error
}
```

**Tree-sitter Query (Go):**
```scheme
;; Functions
(function_declaration
  name: (identifier) @function.name
  parameters: (parameter_list) @function.params
  result: (type_identifier)? @function.return_type)

;; Methods (function with receiver)
(method_declaration
  receiver: (parameter_list) @method.receiver
  name: (field_identifier) @method.name
  parameters: (parameter_list) @method.params)

;; Structs
(type_declaration
  (type_spec
    name: (type_identifier) @struct.name
    type: (struct_type)))

;; Interfaces
(type_declaration
  (type_spec
    name: (type_identifier) @interface.name
    type: (interface_type)))

;; Comments
(comment) @comment
```

**Output:**
```json
{
  "file": "pkg/users/service.go",
  "language": "go",
  "features": {
    "structs": [
      {
        "name": "User",
        "description": "User represents a user in the system.",
        "line": 6,
        "fields": ["ID", "Name", "Email"]
      },
      {
        "name": "UserService",
        "description": "UserService handles user operations.",
        "line": 13,
        "fields": ["db"],
        "methods": [
          {
            "name": "GetUser",
            "signature": "(s *UserService) GetUser(ctx context.Context, id int) (*User, error)",
            "description": "GetUser retrieves a user by ID.",
            "line": 18
          }
        ]
      }
    ],
    "functions": [
      {
        "name": "CreateUser",
        "signature": "CreateUser(name, email string) (*User, error)",
        "description": "CreateUser creates a new user.",
        "line": 23
      }
    ],
    "interfaces": [
      {
        "name": "UserRepository",
        "description": "UserRepository defines the interface for user storage.",
        "line": 28,
        "methods": ["Find", "Save"]
      }
    ]
  }
}
```

---

### 3.5 JavaScript/JSX (React)

**Input:**
```jsx
import React, { useState, useEffect } from 'react';

/**
 * Custom hook for user authentication
 */
function useAuth() {
  const [user, setUser] = useState(null);

  useEffect(() => {
    // Check auth status
  }, []);

  return { user, setUser };
}

/**
 * User profile component
 * @param {Object} props - Component props
 */
function UserProfile({ userId }) {
  const { user } = useAuth();

  return (
    <div className="profile">
      <h1>{user?.name}</h1>
    </div>
  );
}

export default UserProfile;
export { useAuth };
```

**Output:**
```json
{
  "file": "src/components/UserProfile.jsx",
  "language": "javascript",
  "features": {
    "hooks": [
      {
        "name": "useAuth",
        "description": "Custom hook for user authentication",
        "line": 6,
        "returns": ["user", "setUser"]
      }
    ],
    "components": [
      {
        "name": "UserProfile",
        "description": "User profile component",
        "line": 18,
        "props": ["userId"],
        "hooks_used": ["useAuth"]
      }
    ],
    "exports": {
      "default": "UserProfile",
      "named": ["useAuth"]
    }
  }
}
```

---

### 3.6 Unified Output Schema

All languages produce output conforming to:

```json
{
  "file": "string",
  "language": "typescript|python|go|javascript",
  "features": {
    "classes": [],      // TypeScript/Python/Java
    "structs": [],      // Go
    "interfaces": [],   // TypeScript/Go
    "functions": [],    // All languages
    "components": [],   // React/Vue
    "hooks": [],        // React
    "types": [],        // TypeScript
    "exports": []       // All languages
  }
}
```

### 3.7 Implementation

**tools/parse-ast.js:**
```javascript
const languages = {
  typescript: {
    wasm: 'tree-sitter-typescript.wasm',
    extract: extractTypeScript
  },
  python: {
    wasm: 'tree-sitter-python.wasm',
    extract: extractPython
  },
  go: {
    wasm: 'tree-sitter-go.wasm',
    extract: extractGo
  },
  javascript: {
    wasm: 'tree-sitter-javascript.wasm',
    extract: extractJavaScript
  }
};

async function extractFeatures(filePath) {
  const ext = path.extname(filePath).slice(1);
  const language = detectLanguage(ext);

  if (!languages[language]) {
    return { file: filePath, language: 'unknown', features: {} };
  }

  const { wasm, extract } = languages[language];
  const parser = await getParser(wasm);
  const source = fs.readFileSync(filePath, 'utf-8');
  const tree = parser.parse(source);

  return {
    file: filePath,
    language,
    features: extract(tree.rootNode, source)
  };
}

function detectLanguage(ext) {
  const map = {
    ts: 'typescript',
    tsx: 'typescript',
    js: 'javascript',
    jsx: 'javascript',
    py: 'python',
    go: 'go'
  };
  return map[ext] || 'unknown';
}
```

---

## 4. Notes

- Start with TypeScript (STORY-081)
- Add Python as second priority (common in AI/ML)
- Go is useful for backend services
- Each language needs its own tree-sitter grammar WASM
- Regex fallback provides basic extraction without Node.js
- Keep output schema consistent across languages

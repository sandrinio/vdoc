# STORY-082: API Route Detection

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
> I want vdoc to auto-detect my API endpoints,
> So that **documentation includes all routes without manual listing**.

### 1.2 Detailed Requirements
- [ ] Detect Express.js routes: `app.get()`, `router.post()`, etc.
- [ ] Detect Next.js API routes: `pages/api/*.ts`, `app/*/route.ts`
- [ ] Detect FastAPI routes: `@app.get()`, `@router.post()`
- [ ] Detect Flask routes: `@app.route()`
- [ ] Detect Go Chi/Gin routes: `r.Get()`, `r.Post()`
- [ ] Extract: method, path, handler function
- [ ] Add endpoints to manifest

---

## 2. The Truth (Executable Tests)

### 2.1 Acceptance Criteria (Gherkin)
```gherkin
Feature: API Route Detection

  Scenario: Detect Express routes
    Given an Express.js file with routes
    When vdoc scans the file
    Then manifest contains detected endpoints
    And each endpoint has method, path, handler

  Scenario: Detect Next.js file-based routes
    Given a Next.js project with pages/api/users.ts
    When vdoc scans the project
    Then manifest contains GET /api/users endpoint
    And manifest contains POST /api/users endpoint

  Scenario: Detect FastAPI routes
    Given a Python file with @app.get("/users")
    When vdoc scans the file
    Then manifest contains GET /users endpoint
```

---

## 3. Technical Context (For Coder Agent)

### 3.1 Affected Files
- `tools/parse-ast.js` - Add route detection
- `core/presets/typescript.conf` - Route patterns
- `core/presets/python.conf` - Route patterns
- `core/presets/go.conf` - Route patterns

### 3.2 Framework Detection Patterns

**Express.js / Node.js:**
```javascript
// Patterns to detect
app.get('/users', handler)
app.post('/users', handler)
router.get('/users/:id', getUser)
router.use('/api', apiRouter)

// AST nodes
call_expression where:
  - callee.property = 'get' | 'post' | 'put' | 'delete' | 'patch'
  - callee.object = 'app' | 'router'
  - arguments[0] = string (path)
```

**Next.js (File-based):**
```
pages/api/users.ts        → GET|POST /api/users
pages/api/users/[id].ts   → GET|POST /api/users/:id
app/api/users/route.ts    → exports: GET, POST, PUT, DELETE
```

**FastAPI (Python):**
```python
# Patterns to detect
@app.get("/users")
@router.post("/users")
@app.get("/users/{user_id}")

# AST nodes
decorated_definition where:
  - decorator.callee = 'get' | 'post' | 'put' | 'delete'
  - decorator.arguments[0] = string (path)
```

**Flask (Python):**
```python
# Patterns to detect
@app.route("/users", methods=["GET", "POST"])
@blueprint.route("/users/<int:id>")

# AST nodes
decorated_definition where:
  - decorator.callee = 'route'
  - decorator.arguments = (path, methods)
```

**Go (Chi/Gin):**
```go
// Patterns to detect
r.Get("/users", listUsers)
r.Post("/users", createUser)
router.GET("/users/:id", getUser)

// AST nodes
call_expression where:
  - function.name = 'Get' | 'Post' | 'Put' | 'Delete'
  - arguments[0] = string (path)
```

### 3.3 Implementation

**parse-ast.js additions:**
```javascript
function detectRoutes(node, features, source, framework) {
  // Express/Node
  if (isExpressRoute(node)) {
    const method = node.callee.property.name.toUpperCase();
    const path = getStringArg(node.arguments[0], source);
    const handler = getHandlerName(node.arguments[1], source);

    features.endpoints.push({
      method,
      path,
      handler,
      line: node.startPosition.row + 1,
      framework: 'express'
    });
  }

  // FastAPI (Python)
  if (isFastAPIDecorator(node)) {
    const method = node.expression.function.name.toUpperCase();
    const path = getStringArg(node.expression.arguments[0], source);

    features.endpoints.push({
      method,
      path,
      handler: getDecoratedFunctionName(node),
      line: node.startPosition.row + 1,
      framework: 'fastapi'
    });
  }
}

// Framework detection heuristics
function detectFramework(features) {
  const imports = features.imports.map(i => i.module);

  if (imports.some(m => m.includes('express'))) return 'express';
  if (imports.some(m => m.includes('fastapi'))) return 'fastapi';
  if (imports.some(m => m.includes('flask'))) return 'flask';
  if (imports.some(m => m.includes('chi') || m.includes('gin'))) return 'go-router';

  return 'unknown';
}
```

**Next.js file-based detection:**
```bash
# In scan.sh
detect_nextjs_routes() {
    local dir="$1"

    # pages/api pattern
    find "$dir/pages/api" -name "*.ts" -o -name "*.js" 2>/dev/null | while read -r file; do
        local route="${file#$dir/pages}"
        route="${route%.ts}"
        route="${route%.js}"
        route="${route/\[/\:}"
        route="${route/\]/}"

        echo "GET|POST $route → $file"
    done

    # app/api pattern (App Router)
    find "$dir/app" -name "route.ts" -o -name "route.js" 2>/dev/null | while read -r file; do
        local route="${file#$dir/app}"
        route="${route%/route.ts}"
        route="${route%/route.js}"

        # Check which methods are exported
        grep -E "export (async )?function (GET|POST|PUT|DELETE|PATCH)" "$file" | while read -r line; do
            method=$(echo "$line" | grep -oE "(GET|POST|PUT|DELETE|PATCH)")
            echo "$method $route → $file"
        done
    done
}
```

### 3.4 Manifest Output

```json
{
  "endpoints": {
    "GET /api/users": {
      "file": "src/api/users.ts",
      "handler": "listUsers",
      "line": 15,
      "framework": "express"
    },
    "POST /api/users": {
      "file": "src/api/users.ts",
      "handler": "createUser",
      "line": 30,
      "framework": "express"
    },
    "GET /api/users/:id": {
      "file": "src/api/users.ts",
      "handler": "getUserById",
      "line": 45,
      "framework": "express"
    }
  }
}
```

### 3.5 Feature Grouping

Routes are automatically grouped into features:
```json
{
  "features": {
    "User Management": {
      "endpoints": [
        "GET /api/users",
        "POST /api/users",
        "GET /api/users/:id",
        "PUT /api/users/:id",
        "DELETE /api/users/:id"
      ]
    },
    "Authentication": {
      "endpoints": [
        "POST /api/auth/login",
        "POST /api/auth/logout",
        "POST /api/auth/refresh"
      ]
    }
  }
}
```

---

## 4. Notes

- Start with Express.js (most common)
- Add frameworks incrementally
- File-based routing (Next.js) is easiest
- Decorator-based routing requires AST
- Consider OpenAPI spec generation later

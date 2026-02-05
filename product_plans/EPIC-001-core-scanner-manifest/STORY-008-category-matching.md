# STORY-008: Implement DOC_SIGNALS Category Matching

## Metadata
| Field | Value |
|-------|-------|
| **Parent Epic** | [EPIC-001](EPIC.md) |
| **Status** | ✅ Complete |
| **Ambiguity Score** | 🟢 Low |
| **Actor** | Scanner |
| **Complexity** | Small (glob matching) |

---

## 1. The Spec (The Contract)

### 1.1 User Story
> As the **Scanner**,  
> I want to **categorize each file based on its path**,  
> So that **AI tools can group related files for documentation**.

### 1.2 Detailed Requirements
- [ ] Parse DOC_SIGNALS from preset (format: "category:glob_pattern")
- [ ] Match file path against each pattern
- [ ] Return first matching category
- [ ] Return "other" if no pattern matches
- [ ] Support ** for recursive matching
- [ ] Support * for single-level matching

---

## 2. The Truth (Executable Tests)

### 2.1 Acceptance Criteria (Gherkin)
```gherkin
Feature: Category Matching

  Scenario: Match API route
    Given DOC_SIGNALS contains "api_routes:src/api/**"
    And file path is "src/api/users.ts"
    When categorize_file is called
    Then result is "api_routes"

  Scenario: Match component
    Given DOC_SIGNALS contains "components:src/components/**"
    And file path is "src/components/Button.tsx"
    When categorize_file is called
    Then result is "components"

  Scenario: Match config file
    Given DOC_SIGNALS contains "config:*.config.*"
    And file path is "webpack.config.js"
    When categorize_file is called
    Then result is "config"

  Scenario: No match returns other
    Given DOC_SIGNALS does not match file path
    And file path is "random/file.txt"
    When categorize_file is called
    Then result is "other"

  Scenario: First match wins
    Given DOC_SIGNALS contains:
      """
      api:src/api/**
      utils:src/**
      """
    And file path is "src/api/users.ts"
    When categorize_file is called
    Then result is "api" (not "utils")
```

---

## 3. Technical Context (For Coder Agent)

### 3.1 Affected Files
- `core/scan.sh` - Add `categorize_file()` function

### 3.2 Implementation
```bash
# Parse DOC_SIGNALS into arrays
parse_doc_signals() {
    # DOC_SIGNALS format:
    # category:pattern
    # category:pattern
    # ...
    
    CATEGORIES=()
    PATTERNS=()
    
    while IFS=: read -r category pattern; do
        # Skip empty lines and comments
        [[ -z "$category" || "$category" == \#* ]] && continue
        # Trim whitespace
        category=$(echo "$category" | xargs)
        pattern=$(echo "$pattern" | xargs)
        [[ -z "$category" || -z "$pattern" ]] && continue
        
        CATEGORIES+=("$category")
        PATTERNS+=("$pattern")
    done <<< "$DOC_SIGNALS"
}

# Convert glob pattern to regex
glob_to_regex() {
    local pattern="$1"
    # Escape special regex chars, then convert glob to regex
    pattern=$(echo "$pattern" | sed 's/\./\\./g')  # . -> \.
    pattern=$(echo "$pattern" | sed 's/\*\*/DOUBLESTAR/g')  # ** -> placeholder
    pattern=$(echo "$pattern" | sed 's/\*/[^/]*/g')  # * -> [^/]*
    pattern=$(echo "$pattern" | sed 's/DOUBLESTAR/.*/g')  # placeholder -> .*
    echo "^${pattern}$"
}

# Categorize a file based on DOC_SIGNALS
categorize_file() {
    local file="$1"
    
    # Ensure signals are parsed
    if [[ ${#CATEGORIES[@]} -eq 0 ]]; then
        parse_doc_signals
    fi
    
    # Try each pattern
    for i in "${!PATTERNS[@]}"; do
        local pattern="${PATTERNS[$i]}"
        local regex
        regex=$(glob_to_regex "$pattern")
        
        if [[ "$file" =~ $regex ]]; then
            echo "${CATEGORIES[$i]}"
            return
        fi
    done
    
    # No match
    echo "other"
}
```

### 3.3 DOC_SIGNALS Format
```bash
DOC_SIGNALS="
api_routes:src/api/**
api_routes:pages/api/**
components:src/components/**
utils:src/utils/**
config:*.config.*
"
```

### 3.4 Glob Pattern Support
| Pattern | Matches |
|---------|---------|
| `src/api/**` | `src/api/users.ts`, `src/api/v1/auth.ts` |
| `src/*.ts` | `src/index.ts`, NOT `src/api/users.ts` |
| `*.config.*` | `webpack.config.js`, `jest.config.ts` |
| `**/*.test.ts` | Any `.test.ts` file at any depth |

---

## 4. Notes
- First matching pattern wins (order matters in DOC_SIGNALS)
- ** matches any path depth (recursive)
- * matches any characters except /
- "other" category for unmatched files
- Categories determine which doc page a file belongs to

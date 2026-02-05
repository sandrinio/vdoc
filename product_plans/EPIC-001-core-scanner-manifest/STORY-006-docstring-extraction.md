# STORY-006: Add Docstring Extraction Logic

## Metadata
| Field | Value |
|-------|-------|
| **Parent Epic** | [EPIC-001](EPIC.md) |
| **Status** | ✅ Complete |
| **Ambiguity Score** | 🟡 Medium |
| **Actor** | Scanner |
| **Complexity** | Medium (regex parsing) |

---

## 1. The Spec (The Contract)

### 1.1 User Story
> As the **Scanner**,  
> I want to **extract the first docstring/comment block from each file**,  
> So that **AI tools get a quick description without reading full source**.

### 1.2 Detailed Requirements
- [ ] Extract first documentation comment from file
- [ ] Support JSDoc style: /** ... */
- [ ] Support Python docstrings: """ ... """ and ''' ... '''
- [ ] Support single-line descriptions: // or # at file top
- [ ] Strip comment markers from extracted text
- [ ] Truncate to first sentence or 100 chars (whichever shorter)
- [ ] Return empty string if no docstring found
- [ ] Handle multiline docstrings (combine into single line)

---

## 2. The Truth (Executable Tests)

### 2.1 Acceptance Criteria (Gherkin)
```gherkin
Feature: Docstring Extraction

  Scenario: Extract JSDoc comment
    Given file contains:
      """
      /**
       * User service for CRUD operations.
       * Handles authentication and authorization.
       */
      export class UserService { }
      """
    When extract_docstring is called
    Then result is "User service for CRUD operations."

  Scenario: Extract Python docstring
    Given file contains:
      """
      \"\"\"User service for CRUD operations.\"\"\"
      class UserService:
          pass
      """
    When extract_docstring is called
    Then result is "User service for CRUD operations."

  Scenario: Extract single-line comment
    Given file contains:
      """
      // User service for CRUD operations
      export class UserService { }
      """
    When extract_docstring is called
    Then result is "User service for CRUD operations"

  Scenario: No docstring found
    Given file contains:
      """
      export class UserService { }
      """
    When extract_docstring is called
    Then result is empty string

  Scenario: Truncate long docstring
    Given file contains a 500 character docstring
    When extract_docstring is called
    Then result is <= 100 characters
    And result ends with "..."
```

---

## 3. Technical Context (For Coder Agent)

### 3.1 Affected Files
- `core/scan.sh` - Add `extract_docstring()` function

### 3.2 Implementation
```bash
# Extract first docstring from file
# Uses preset's DOCSTRING_PATTERN and DOCSTRING_END
extract_docstring() {
    local file="$1"
    local docstring=""
    
    # Read first 50 lines (docstrings should be at top)
    local content
    content=$(head -50 "$file" 2>/dev/null) || return
    
    # Try block comment pattern (JSDoc, etc.)
    if [[ -n "${DOCSTRING_PATTERN:-}" ]]; then
        docstring=$(echo "$content" | sed -n "/${DOCSTRING_PATTERN}/,/${DOCSTRING_END}/p" | head -20)
        
        if [[ -n "$docstring" ]]; then
            # Strip comment markers
            docstring=$(echo "$docstring" | \
                sed 's/^\s*\/\*\*//; s/\*\///; s/^\s*\*//g; s/"""//g; s/'"'''"'//g' | \
                tr '\n' ' ' | \
                sed 's/  */ /g; s/^ *//; s/ *$//')
        fi
    fi
    
    # Try single-line comment if no block comment found
    if [[ -z "$docstring" ]]; then
        # Look for // or # comment at file start
        docstring=$(echo "$content" | grep -m1 '^\s*\(//\|#\)\s*[A-Z]' | \
            sed 's/^\s*\/\/\s*//; s/^\s*#\s*//')
    fi
    
    # Truncate to first sentence or max length
    if [[ -n "$docstring" ]]; then
        # Get first sentence (ends with . ! or ?)
        local first_sentence
        first_sentence=$(echo "$docstring" | sed 's/\([.!?]\).*/\1/')
        
        # Truncate if too long
        if [[ ${#first_sentence} -gt 100 ]]; then
            docstring="${first_sentence:0:97}..."
        else
            docstring="$first_sentence"
        fi
    fi
    
    echo "$docstring"
}
```

### 3.3 Supported Formats
| Language | Pattern | Example |
|----------|---------|---------|
| TypeScript/JavaScript | `/** ... */` | `/** User service */` |
| Python | `""" ... """` | `"""User service"""` |
| Python | `''' ... '''` | `'''User service'''` |
| Generic | `// ...` | `// User service` |
| Generic | `# ...` | `# User service` |

---

## 4. Notes
- Only read first 50 lines for performance
- First sentence extraction prevents overly long descriptions
- Multiline comments are collapsed to single line
- Returns empty string (not error) if no docstring found
- This provides "Pass A" in tiered description strategy

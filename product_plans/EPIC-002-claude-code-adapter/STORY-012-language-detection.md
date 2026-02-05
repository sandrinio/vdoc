# STORY-012: Implement Language Detection

## Metadata
| Field | Value |
|-------|-------|
| **Parent Epic** | [EPIC-002](EPIC.md) |
| **Status** | ✅ Complete |
| **Ambiguity Score** | 🟢 Low |
| **Actor** | Developer |
| **Complexity** | Small (1 file) |

---

## 1. The Spec (The Contract)

### 1.1 User Story
> As a **Developer**,  
> I want **vdoc to automatically detect my project's language**,  
> So that **the correct preset is used without manual configuration**.

### 1.2 Detailed Requirements
- [ ] Detect TypeScript via `tsconfig.json`
- [ ] Detect JavaScript via `package.json` (without tsconfig)
- [ ] Detect Python via `requirements.txt`, `pyproject.toml`, or `setup.py`
- [ ] Detect Go via `go.mod`
- [ ] Detect Rust via `Cargo.toml`
- [ ] Detect Java via `pom.xml` or `build.gradle`
- [ ] Fall back to `default` if no marker files found
- [ ] Support `vdoc.config.json` override for multi-language projects
- [ ] Print detected language to user

---

## 2. The Truth (Executable Tests)

### 2.1 Acceptance Criteria (Gherkin)
```gherkin
Feature: Language Detection

  Scenario: Detect TypeScript
    Given a directory with "tsconfig.json"
    When detect_language is called
    Then result is "typescript"

  Scenario: Detect JavaScript (not TypeScript)
    Given a directory with "package.json"
    And no "tsconfig.json" exists
    When detect_language is called
    Then result is "javascript"

  Scenario: Detect Python via requirements.txt
    Given a directory with "requirements.txt"
    When detect_language is called
    Then result is "python"

  Scenario: Detect Python via pyproject.toml
    Given a directory with "pyproject.toml"
    When detect_language is called
    Then result is "python"

  Scenario: Detect Go
    Given a directory with "go.mod"
    When detect_language is called
    Then result is "go"

  Scenario: Detect Rust
    Given a directory with "Cargo.toml"
    When detect_language is called
    Then result is "rust"

  Scenario: Detect Java via Maven
    Given a directory with "pom.xml"
    When detect_language is called
    Then result is "java"

  Scenario: Detect Java via Gradle
    Given a directory with "build.gradle"
    When detect_language is called
    Then result is "java"

  Scenario: Fall back to default
    Given a directory with no recognized marker files
    When detect_language is called
    Then result is "default"

  Scenario: vdoc.config.json overrides detection
    Given a directory with "vdoc.config.json"
    When detect_language is called
    Then result is "multi" or uses config
```

---

## 3. Technical Context (For Coder Agent)

### 3.1 Affected Files
- `install.sh` - Add `detect_language()` function

### 3.2 Implementation
```bash
detect_language() {
    # Check for config override first
    if [[ -f "vdoc.config.json" ]]; then
        echo "multi"
        return
    fi
    
    # TypeScript (must check before JavaScript)
    if [[ -f "tsconfig.json" ]]; then
        echo "typescript"
        return
    fi
    
    # JavaScript
    if [[ -f "package.json" ]]; then
        echo "javascript"
        return
    fi
    
    # Python
    if [[ -f "requirements.txt" ]] || [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]]; then
        echo "python"
        return
    fi
    
    # Go
    if [[ -f "go.mod" ]]; then
        echo "go"
        return
    fi
    
    # Rust
    if [[ -f "Cargo.toml" ]]; then
        echo "rust"
        return
    fi
    
    # Java
    if [[ -f "pom.xml" ]] || [[ -f "build.gradle" ]]; then
        echo "java"
        return
    fi
    
    # Default fallback
    echo "default"
}
```

### 3.3 Detection Priority
1. `vdoc.config.json` (explicit multi-language)
2. `tsconfig.json` → TypeScript
3. `package.json` → JavaScript
4. `requirements.txt` / `pyproject.toml` / `setup.py` → Python
5. `go.mod` → Go
6. `Cargo.toml` → Rust
7. `pom.xml` / `build.gradle` → Java
8. Fallback → default

---

## 4. Notes
- TypeScript must be checked before JavaScript (tsconfig takes priority)
- Multi-language via `vdoc.config.json` returns "multi" - handled separately
- Detection runs in current working directory

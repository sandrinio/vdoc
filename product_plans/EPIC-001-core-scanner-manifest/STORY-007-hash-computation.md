# STORY-007: Add SHA-256 Hash Computation

## Metadata
| Field | Value |
|-------|-------|
| **Parent Epic** | [EPIC-001](EPIC.md) |
| **Status** | ✅ Complete |
| **Ambiguity Score** | 🟢 Low |
| **Actor** | Scanner |
| **Complexity** | Small (1 function) |

---

## 1. The Spec (The Contract)

### 1.1 User Story
> As the **Scanner**,  
> I want to **compute a hash for each file**,  
> So that **the update workflow can detect which files changed**.

### 1.2 Detailed Requirements
- [ ] Compute SHA-256 hash of file contents
- [ ] Truncate hash to first 10 characters (sufficient for change detection)
- [ ] Use `shasum` or `sha256sum` (cross-platform)
- [ ] Handle binary files gracefully
- [ ] Return consistent format regardless of platform

---

## 2. The Truth (Executable Tests)

### 2.1 Acceptance Criteria (Gherkin)
```gherkin
Feature: Hash Computation

  Scenario: Compute hash of text file
    Given file contains "hello world"
    When compute_hash is called
    Then result is 10 characters
    And result is hexadecimal

  Scenario: Same content same hash
    Given two files with identical content
    When compute_hash is called on both
    Then both hashes are equal

  Scenario: Different content different hash
    Given two files with different content
    When compute_hash is called on both
    Then hashes are different

  Scenario: Hash is deterministic
    Given file content doesn't change
    When compute_hash is called multiple times
    Then all results are identical
```

---

## 3. Technical Context (For Coder Agent)

### 3.1 Affected Files
- `core/scan.sh` - Add `compute_hash()` function

### 3.2 Implementation
```bash
# Compute truncated SHA-256 hash of file
compute_hash() {
    local file="$1"
    local hash=""
    
    # Try shasum (macOS) first, then sha256sum (Linux)
    if command -v shasum &>/dev/null; then
        hash=$(shasum -a 256 "$file" 2>/dev/null | cut -d' ' -f1)
    elif command -v sha256sum &>/dev/null; then
        hash=$(sha256sum "$file" 2>/dev/null | cut -d' ' -f1)
    else
        # Fallback: use cksum (less ideal but universal)
        hash=$(cksum "$file" 2>/dev/null | awk '{print $1}')
    fi
    
    # Truncate to 10 characters
    echo "${hash:0:10}"
}
```

### 3.3 Cross-Platform Support
| Platform | Command | Notes |
|----------|---------|-------|
| macOS | `shasum -a 256` | Built-in |
| Linux | `sha256sum` | coreutils |
| BSD | `sha256` | Different syntax |
| Fallback | `cksum` | CRC, not SHA |

### 3.4 Hash Format
- Full SHA-256: 64 hex characters
- Truncated: 10 hex characters
- Example: `a3f2c1d4e5`

---

## 4. Notes
- 10 characters = 40 bits of entropy, sufficient for change detection
- Not cryptographically significant, just for diffing
- Truncation keeps output compact and readable
- Binary files are handled (hash computed on raw bytes)

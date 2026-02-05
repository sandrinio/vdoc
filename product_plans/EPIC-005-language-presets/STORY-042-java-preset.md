# STORY-042: Create Java Language Preset

## Metadata
| Field | Value |
|-------|-------|
| **Status** | ✅ Complete |
| **Story Points** | 3 |
| **Priority** | P1 - High |
| **Parent Epic** | EPIC-005 |

---

## User Story
**As a** Java developer using vdoc
**I want** automatic detection and scanning of my Java project
**So that** I get properly categorized documentation without manual configuration

---

## Acceptance Criteria

### AC1: Language detection
- [ ] Detect Maven projects via `pom.xml`
- [ ] Detect Gradle projects via `build.gradle` or `build.gradle.kts`
- [ ] Fall back to `*.java` files if neither found
- [ ] Set preset name to "java"

### AC2: Directory exclusions
- [ ] Exclude `target/` directory (Maven build)
- [ ] Exclude `build/` directory (Gradle build)
- [ ] Exclude `.gradle/` cache
- [ ] Exclude `.idea/`, `.settings/` IDE files
- [ ] Exclude `out/` directory

### AC3: File exclusions
- [ ] Exclude `*.class` compiled files
- [ ] Exclude `*Test.java`, `*Tests.java` test files
- [ ] Exclude `*IT.java` integration tests
- [ ] Exclude generated sources

### AC4: Entry point detection
- [ ] Detect `**/Application.java` (Spring Boot)
- [ ] Detect `**/Main.java`
- [ ] Detect `src/main/java/**/App.java`

### AC5: Javadoc extraction
- [ ] Extract `/** ... */` documentation blocks
- [ ] Handle multi-line Javadoc
- [ ] Extract first sentence as summary
- [ ] Pattern: `^\s*/\*\*` to `\*/`

### AC6: Category signals
- [ ] `controller`: `**/controller/**`, `**/rest/**`
- [ ] `services`: `**/service/**`, `**/services/**`
- [ ] `models`: `**/model/**`, `**/entity/**`, `**/dto/**`
- [ ] `repository`: `**/repository/**`, `**/dao/**`
- [ ] `config`: `**/config/**`, `**/configuration/**`
- [ ] `utils`: `**/util/**`, `**/utils/**`, `**/helper/**`

---

## Technical Notes

**Preset File: `core/presets/java.conf`**
```bash
# vdoc Language Preset: Java
# Detection: pom.xml OR build.gradle

PRESET_NAME="java"
PRESET_VERSION="1.0.0"

# Directories to exclude from scanning
EXCLUDE_DIRS="target build .gradle .idea .settings out bin generated-sources"

# File patterns to exclude
EXCLUDE_FILES="*.class *Test.java *Tests.java *IT.java *Spec.java"

# Likely entry point files (Spring Boot convention)
ENTRY_PATTERNS="**/Application.java **/Main.java **/App.java src/main/java/**/Application.java"

# Javadoc comments
DOCSTRING_PATTERN='^\s*/\*\*'
DOCSTRING_END='\*/'

# Category signals (Java package conventions)
DOC_SIGNALS="
controller:**/controller/**
controller:**/rest/**
controller:**/web/**
controller:**/api/**
services:**/service/**
services:**/services/**
models:**/model/**
models:**/entity/**
models:**/entities/**
models:**/dto/**
models:**/domain/**
repository:**/repository/**
repository:**/repositories/**
repository:**/dao/**
config:**/config/**
config:**/configuration/**
utils:**/util/**
utils:**/utils/**
utils:**/helper/**
utils:**/helpers/**
middleware:**/filter/**
middleware:**/interceptor/**
security:**/security/**
"
```

**Javadoc Extraction:**
```bash
# Extract Javadoc comment before class/method declaration
extract_javadoc() {
    local file="$1"
    awk '
        /\/\*\*/ { 
            in_doc = 1; 
            doc = ""; 
            next 
        }
        in_doc && /\*\// { 
            in_doc = 0; 
            next 
        }
        in_doc { 
            gsub(/^\s*\*\s?/, ""); 
            if ($0 !~ /^@/) doc = doc $0 " "; 
        }
        !in_doc && doc && /^\s*(public|private|protected|class|interface|enum)/ { 
            # Get first sentence
            gsub(/\.\s.*$/, ".", doc);
            print doc; 
            exit 
        }
    ' "$file" | head -1
}
```

**Example Java File:**
```java
package com.example.users;

/**
 * Service for managing user accounts.
 * Provides CRUD operations and authentication.
 * 
 * @author Development Team
 * @since 1.0
 */
@Service
public class UserService {
    
    /**
     * Creates a new user with the given details.
     * 
     * @param name the user's display name
     * @param email the user's email address
     * @return the created User entity
     * @throws ValidationException if input is invalid
     */
    public User createUser(String name, String email) {
        // ...
    }
}
```

Expected extraction: `"Service for managing user accounts."`

---

## Definition of Done
- [ ] `java.conf` preset created in `core/presets/`
- [ ] Java projects detected via pom.xml or build.gradle
- [ ] Target/build directories excluded
- [ ] Javadoc comments extracted correctly
- [ ] Spring/Maven conventions mapped to categories
- [ ] Tested with sample Java project

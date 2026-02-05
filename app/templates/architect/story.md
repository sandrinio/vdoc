# STORY-{ID}: {Story Name}

## Metadata
| Field | Value |
|-------|-------|
| **Parent Epic** | [EPIC-{ID}](link) |
| **Status** | Draft / Ready for Bounce / Done |
| **Ambiguity Score** | 🔴 High / 🟡 Medium / 🟢 Low |
| **Actor** | {Persona Name} |
| **Complexity** | Small (1 file) / Medium (2-3 files) / Large (Refactor) |

---

## 1. The Spec (The Contract)

### 1.1 User Story
> As a **{Persona}**,  
> I want to **{Action}**,  
> So that **{Benefit}**.

### 1.2 Detailed Requirements
- [ ] Requirement 1: {Specific behavior}
- [ ] Requirement 2: {Specific data validation}
- [ ] Requirement 3: {UI state}

---

## 2. The Truth (Executable Tests)

### 2.1 Acceptance Criteria (Gherkin)
```gherkin
Feature: {Story Name}

  Scenario: Happy Path
    Given {precondition}
    When {user action}
    Then {system response}
    And {database state change}

  Scenario: Error Case
    Given {precondition}
    When {invalid action}
    Then {error message}
```

---

## 3. Technical Context (For Coder Agent)

### 3.1 Affected Files
- `src/path/to/file.ts` - {what changes}
- `src/path/to/component.tsx` - {what changes}

### 3.2 Data Model
```typescript
interface ExampleType {
  id: string;
  field: string;
}
```

### 3.3 API Contract (if applicable)
```
POST /api/endpoint
Request: { field: string }
Response: { success: boolean, data: ExampleType }
```

---

## 4. Notes
- Design decisions or constraints
- Links to Figma/mockups
- Related documentation

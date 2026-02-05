# STORY-062: Add Quality Metrics to Manifest

## Metadata
| Field | Value |
|-------|-------|
| **Parent Epic** | [EPIC-006B](EPIC.md) |
| **Status** | Complete |
| **Ambiguity Score** | 🟢 Low |
| **Actor** | Developer / AI Tool |
| **Complexity** | Low (schema extension + auto-update) |

---

## 1. The Spec (The Contract)

### 1.1 User Story
> As a **Developer**,
> I want quality metrics **stored in the manifest**,
> So that **I can track trends and CI can read them without re-computing**.

### 1.2 Detailed Requirements
- [x] Add `quality` section to `_manifest.json` schema
- [x] Auto-compute quality after `vdoc update` completes
- [x] Store overall score and all sub-metrics
- [x] Store timestamp of when quality was computed
- [x] Add `--skip-quality` flag to skip computation on update
- [x] Quality section is optional (backwards compatible)
- [ ] Expose quality via `vdoc status` command summary (future: status command)

---

## 2. The Truth (Executable Tests)

### 2.1 Acceptance Criteria (Gherkin)
```gherkin
Feature: Quality Metrics in Manifest

  Scenario: Quality computed after update
    Given vdoc update completes successfully
    When manifest is written
    Then _manifest.json contains "quality" section
    And quality.overall_score exists
    And quality.computed_at is recent timestamp

  Scenario: Skip quality with flag
    Given vdoc update --skip-quality is run
    When manifest is written
    Then _manifest.json does NOT contain "quality" section

  Scenario: Backwards compatibility
    Given old manifest without quality section
    When vdoc status is run
    Then no error occurs
    And output shows "Quality: Not computed"

  Scenario: Status shows quality summary
    Given manifest has quality.overall_score of 78
    When vdoc status is run
    Then output includes "Quality Score: 78/100"

  Scenario: CI reads quality from manifest
    Given manifest has quality section
    When external tool reads _manifest.json
    Then quality.overall_score is accessible
    And quality.coverage.score is accessible
```

---

## 3. Technical Context (For Coder Agent)

### 3.1 Affected Files
- `core/manifest.sh` - Add quality to schema
- `core/scan.sh` - Auto-compute quality after update
- `app/commands/status.sh` - Show quality summary

### 3.2 Manifest Schema Extension
```json
{
  "$schema": "https://vdoc.dev/schemas/manifest.json",
  "project": "my-app",
  "language": "typescript",
  "last_updated": "2026-02-05T14:30:00Z",
  "vdoc_version": "2.0.0",
  "documentation": [...],
  "source_index": {...},
  "quality": {
    "overall_score": 78,
    "coverage": {
      "score": 85,
      "documented_files": 42,
      "total_files": 50,
      "undocumented": ["src/utils/helpers.ts"]
    },
    "freshness": {
      "score": 72,
      "avg_days_stale": 14,
      "stale_docs": []
    },
    "completeness": {
      "score": 80,
      "docs_with_gaps": []
    },
    "weights": {
      "coverage": 40,
      "freshness": 35,
      "completeness": 25
    },
    "computed_at": "2026-02-05T14:30:00Z"
  }
}
```

### 3.3 Implementation
```bash
# In core/scan.sh after successful update

finalize_update() {
    local manifest="$1"
    local skip_quality="${SKIP_QUALITY:-false}"

    if [[ "$skip_quality" != "true" ]]; then
        echo "Computing documentation quality..."
        local quality=$(calculate_quality "$manifest")

        # Merge quality into manifest
        local updated=$(jq --argjson quality "$quality" '.quality = $quality' "$manifest")
        echo "$updated" > "$manifest"

        local score=$(echo "$quality" | jq -r '.overall_score')
        echo "Quality score: $score/100"
    fi
}
```

### 3.4 Status Command Integration
```bash
# In app/commands/status.sh

show_quality_summary() {
    local manifest="$1"

    local quality=$(jq -r '.quality // empty' "$manifest")

    if [[ -z "$quality" ]]; then
        echo "Quality: Not computed (run 'vdoc quality' or 'vdoc update')"
        return
    fi

    local score=$(echo "$quality" | jq -r '.overall_score')
    local computed=$(echo "$quality" | jq -r '.computed_at')

    echo "Quality Score: $score/100 (computed: $computed)"
}
```

### 3.5 Flag Handling
```bash
# In app/vdoc.sh

case "$1" in
    update)
        shift
        while [[ $# -gt 0 ]]; do
            case "$1" in
                --skip-quality) SKIP_QUALITY=true; shift ;;
                --full) FORCE_FULL=true; shift ;;
                *) shift ;;
            esac
        done
        cmd_update
        ;;
esac
```

---

## 4. Notes
- Quality computation adds minimal overhead (~100ms for typical projects)
- `--skip-quality` useful for rapid iterations during development
- CI pipelines can read quality directly from manifest JSON
- Historical tracking (storing previous scores) is out of scope for this story
- Consider adding quality to `.vdoc/docs/index.md` summary in future

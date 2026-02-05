# STORY-060: Implement Quality Scoring Algorithm

## Metadata
| Field | Value |
|-------|-------|
| **Parent Epic** | [EPIC-006B](EPIC.md) |
| **Status** | Complete |
| **Ambiguity Score** | 🟢 Low |
| **Actor** | Developer / AI Tool |
| **Complexity** | Medium (3 metrics + weighting) |

---

## 1. The Spec (The Contract)

### 1.1 User Story
> As an **Engineering Manager**,
> I want a **quality score for my documentation**,
> So that **I can track documentation health over time**.

### 1.2 Detailed Requirements
- [ ] Calculate **coverage score**: % of source files that have documentation
- [ ] Calculate **freshness score**: based on doc age vs source age
- [ ] Calculate **completeness score**: % of doc sections that have content
- [ ] Compute **overall score** as weighted average (40/35/25)
- [ ] Return scores as 0-100 integers
- [ ] List specific files/docs that are dragging down each score
- [ ] Make weights configurable via environment or config

---

## 2. The Truth (Executable Tests)

### 2.1 Acceptance Criteria (Gherkin)
```gherkin
Feature: Quality Scoring Algorithm

  Scenario: Calculate coverage score
    Given source_index has 50 files
    And 40 files have "documented_in" field set
    When coverage score is calculated
    Then coverage score is 80
    And undocumented list contains 10 files

  Scenario: Calculate freshness score - all fresh
    Given all doc files were modified after their source files
    When freshness score is calculated
    Then freshness score is 100

  Scenario: Calculate freshness score - some stale
    Given doc "api.md" covers source modified 30 days after doc
    And doc "auth.md" covers source modified 10 days after doc
    When freshness score is calculated
    Then freshness score is less than 100
    And stale_docs list contains "api.md" with days_stale: 30

  Scenario: Calculate completeness score
    Given doc "api.md" has 5 sections, 4 with content
    And doc "auth.md" has 5 sections, 5 with content
    When completeness score is calculated
    Then completeness for api.md is 80%
    And completeness for auth.md is 100%
    And overall completeness is 90%

  Scenario: Calculate overall weighted score
    Given coverage score is 80
    And freshness score is 70
    And completeness score is 90
    And weights are 40/35/25
    When overall score is calculated
    Then overall score is (80*0.4 + 70*0.35 + 90*0.25) = 79

  Scenario: Custom weights via config
    Given VDOC_QUALITY_WEIGHTS="50,30,20"
    And coverage=80, freshness=70, completeness=90
    When overall score is calculated
    Then overall score is (80*0.5 + 70*0.3 + 90*0.2) = 79
```

---

## 3. Technical Context (For Coder Agent)

### 3.1 Affected Files
- `core/quality.sh` (new) - Scoring algorithm implementation

### 3.2 Implementation
```bash
#!/usr/bin/env bash
# core/quality.sh

# Default weights (must sum to 100)
COVERAGE_WEIGHT="${VDOC_COVERAGE_WEIGHT:-40}"
FRESHNESS_WEIGHT="${VDOC_FRESHNESS_WEIGHT:-35}"
COMPLETENESS_WEIGHT="${VDOC_COMPLETENESS_WEIGHT:-25}"

# Calculate coverage: documented files / total files
calculate_coverage() {
    local manifest="$1"

    local total_files=$(jq '.source_index | keys | length' "$manifest")
    local documented_files=$(jq '[.source_index | to_entries[] | select(.value.documented_in != null)] | length' "$manifest")

    local score=0
    if [[ $total_files -gt 0 ]]; then
        score=$(( (documented_files * 100) / total_files ))
    fi

    # Get undocumented files list
    local undocumented=$(jq -r '[.source_index | to_entries[] | select(.value.documented_in == null) | .key] | .[]' "$manifest")

    cat << EOF
{
  "score": $score,
  "documented_files": $documented_files,
  "total_files": $total_files,
  "undocumented": $(echo "$undocumented" | jq -R -s 'split("\n") | map(select(. != ""))')
}
EOF
}

# Calculate freshness: how recent are docs vs source
calculate_freshness() {
    local manifest="$1"
    local vdoc_dir="$2"

    # For each doc, compare its mtime to the mtime of files it covers
    local stale_docs=()
    local total_staleness=0
    local doc_count=0

    while read -r doc_path; do
        [[ -z "$doc_path" ]] && continue

        local doc_file="$vdoc_dir/$doc_path"
        [[ ! -f "$doc_file" ]] && continue

        local doc_mtime=$(stat -f %m "$doc_file" 2>/dev/null || stat -c %Y "$doc_file")

        # Get files this doc covers
        local covers=$(jq -r --arg doc "$doc_path" '.documentation[] | select(.path == $doc) | .covers[]' "$manifest")

        local max_source_mtime=0
        while read -r source; do
            [[ -z "$source" ]] && continue
            [[ ! -f "$source" ]] && continue
            local source_mtime=$(stat -f %m "$source" 2>/dev/null || stat -c %Y "$source")
            [[ $source_mtime -gt $max_source_mtime ]] && max_source_mtime=$source_mtime
        done <<< "$covers"

        if [[ $max_source_mtime -gt $doc_mtime ]]; then
            local days_stale=$(( (max_source_mtime - doc_mtime) / 86400 ))
            total_staleness=$((total_staleness + days_stale))
            stale_docs+=("{\"path\": \"$doc_path\", \"days_stale\": $days_stale}")
        fi

        doc_count=$((doc_count + 1))
    done < <(jq -r '.documentation[].path' "$manifest")

    # Calculate score (100 = all fresh, decreases with staleness)
    local avg_staleness=0
    [[ $doc_count -gt 0 ]] && avg_staleness=$((total_staleness / doc_count))

    # Score formula: 100 - (avg_staleness * 2), min 0
    local score=$((100 - (avg_staleness * 2)))
    [[ $score -lt 0 ]] && score=0

    cat << EOF
{
  "score": $score,
  "avg_days_stale": $avg_staleness,
  "stale_docs": [$(IFS=,; echo "${stale_docs[*]}")]
}
EOF
}

# Calculate completeness: sections with content / total sections
calculate_completeness() {
    local manifest="$1"
    local vdoc_dir="$2"

    # Required sections for a complete doc
    local required_sections=("overview" "usage" "examples" "api" "error-handling")

    local total_sections=0
    local filled_sections=0
    local docs_with_gaps=()

    while read -r doc_path; do
        [[ -z "$doc_path" ]] && continue

        local doc_file="$vdoc_dir/$doc_path"
        [[ ! -f "$doc_file" ]] && continue

        local missing=()
        for section in "${required_sections[@]}"; do
            total_sections=$((total_sections + 1))
            # Check if section heading exists and has content
            if grep -q "^## .*${section}" "$doc_file" 2>/dev/null; then
                filled_sections=$((filled_sections + 1))
            else
                missing+=("$section")
            fi
        done

        if [[ ${#missing[@]} -gt 0 ]]; then
            docs_with_gaps+=("{\"path\": \"$doc_path\", \"missing\": $(printf '%s\n' "${missing[@]}" | jq -R . | jq -s .)}")
        fi
    done < <(jq -r '.documentation[].path' "$manifest")

    local score=0
    [[ $total_sections -gt 0 ]] && score=$((filled_sections * 100 / total_sections))

    cat << EOF
{
  "score": $score,
  "filled_sections": $filled_sections,
  "total_sections": $total_sections,
  "docs_with_gaps": [$(IFS=,; echo "${docs_with_gaps[*]}")]
}
EOF
}

# Calculate overall weighted score
calculate_overall() {
    local coverage="$1"
    local freshness="$2"
    local completeness="$3"

    local score=$(( (coverage * COVERAGE_WEIGHT + freshness * FRESHNESS_WEIGHT + completeness * COMPLETENESS_WEIGHT) / 100 ))

    echo "$score"
}

# Main quality calculation
calculate_quality() {
    local manifest="$1"
    local vdoc_dir="${2:-.vdoc}"

    local coverage=$(calculate_coverage "$manifest")
    local freshness=$(calculate_freshness "$manifest" "$vdoc_dir")
    local completeness=$(calculate_completeness "$manifest" "$vdoc_dir")

    local coverage_score=$(echo "$coverage" | jq -r '.score')
    local freshness_score=$(echo "$freshness" | jq -r '.score')
    local completeness_score=$(echo "$completeness" | jq -r '.score')

    local overall=$(calculate_overall "$coverage_score" "$freshness_score" "$completeness_score")

    cat << EOF
{
  "overall_score": $overall,
  "coverage": $coverage,
  "freshness": $freshness,
  "completeness": $completeness,
  "weights": {
    "coverage": $COVERAGE_WEIGHT,
    "freshness": $FRESHNESS_WEIGHT,
    "completeness": $COMPLETENESS_WEIGHT
  },
  "computed_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
}
```

### 3.3 Score Interpretation
| Score Range | Interpretation |
|-------------|----------------|
| 90-100 | Excellent - Documentation is comprehensive and current |
| 75-89 | Good - Minor gaps, generally healthy |
| 50-74 | Fair - Significant gaps, needs attention |
| 25-49 | Poor - Major documentation debt |
| 0-24 | Critical - Documentation is severely lacking |

---

## 4. Notes
- Coverage is weighted highest because missing docs are worse than stale docs
- Freshness uses a linear decay formula (adjustable)
- Completeness checks for common section headings
- All scores clamp to 0-100 range
- Required sections list should be configurable in future

# STORY-061: Create vdoc quality CLI Command

## Metadata
| Field | Value |
|-------|-------|
| **Parent Epic** | [EPIC-006B](EPIC.md) |
| **Status** | Complete |
| **Ambiguity Score** | 🟢 Low |
| **Actor** | Developer / Engineering Manager |
| **Complexity** | Low (CLI + formatting) |

---

## 1. The Spec (The Contract)

### 1.1 User Story
> As a **Developer**,
> I want to run `vdoc quality` **to see a documentation health report**,
> So that **I know what needs improvement**.

### 1.2 Detailed Requirements
- [ ] Add `quality` subcommand to vdoc CLI
- [ ] Run quality scoring algorithm from STORY-060
- [ ] Display formatted terminal report by default
- [ ] Support `--json` flag for JSON output
- [ ] Support `--md` flag for markdown output
- [ ] Support `--verbose` flag for detailed file lists
- [ ] Exit code 0 if score >= threshold (default 50)
- [ ] Support `--threshold N` to set pass/fail threshold
- [ ] Color output: green (>75), yellow (50-75), red (<50)

---

## 2. The Truth (Executable Tests)

### 2.1 Acceptance Criteria (Gherkin)
```gherkin
Feature: vdoc quality Command

  Scenario: Default terminal output
    Given manifest exists with documentation
    When vdoc quality is run
    Then output shows overall score
    And output shows coverage, freshness, completeness
    And output is formatted as a table

  Scenario: JSON output
    Given manifest exists with documentation
    When vdoc quality --json is run
    Then output is valid JSON
    And JSON contains overall_score
    And JSON contains coverage, freshness, completeness objects

  Scenario: Markdown output
    Given manifest exists with documentation
    When vdoc quality --md is run
    Then output is valid markdown
    And output contains score table

  Scenario: Verbose shows file details
    Given manifest has undocumented files
    When vdoc quality --verbose is run
    Then output lists each undocumented file
    And output lists each stale doc with days

  Scenario: Exit code based on threshold
    Given overall score is 60
    When vdoc quality --threshold 50 is run
    Then exit code is 0 (pass)
    When vdoc quality --threshold 70 is run
    Then exit code is 1 (fail)

  Scenario: No manifest error
    Given no _manifest.json exists
    When vdoc quality is run
    Then error shows "No manifest found. Run 'vdoc init' first."
    And exit code is 1
```

---

## 3. Technical Context (For Coder Agent)

### 3.1 Affected Files
- `app/vdoc.sh` - Add quality subcommand
- `app/commands/quality.sh` (new) - Quality command implementation

### 3.2 Implementation
```bash
#!/usr/bin/env bash
# app/commands/quality.sh

source "$(dirname "$0")/../../core/quality.sh"

THRESHOLD="${VDOC_QUALITY_THRESHOLD:-50}"
FORMAT="terminal"
VERBOSE=false

# Parse arguments
parse_quality_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --json) FORMAT="json"; shift ;;
            --md|--markdown) FORMAT="markdown"; shift ;;
            --verbose|-v) VERBOSE=true; shift ;;
            --threshold) THRESHOLD="$2"; shift 2 ;;
            *) echo "Unknown option: $1" >&2; exit 1 ;;
        esac
    done
}

# Color helpers
red() { echo -e "\033[31m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }

score_color() {
    local score="$1"
    if [[ $score -ge 75 ]]; then
        green "$score"
    elif [[ $score -ge 50 ]]; then
        yellow "$score"
    else
        red "$score"
    fi
}

# Progress bar
progress_bar() {
    local score="$1"
    local filled=$((score / 10))
    local empty=$((10 - filled))
    printf '%s%s' "$(printf '█%.0s' $(seq 1 $filled))" "$(printf '░%.0s' $(seq 1 $empty))"
}

# Terminal format
format_terminal() {
    local quality="$1"

    local overall=$(echo "$quality" | jq -r '.overall_score')
    local coverage=$(echo "$quality" | jq -r '.coverage.score')
    local freshness=$(echo "$quality" | jq -r '.freshness.score')
    local completeness=$(echo "$quality" | jq -r '.completeness.score')

    local cov_docs=$(echo "$quality" | jq -r '.coverage.documented_files')
    local cov_total=$(echo "$quality" | jq -r '.coverage.total_files')
    local fresh_avg=$(echo "$quality" | jq -r '.freshness.avg_days_stale')
    local gaps=$(echo "$quality" | jq -r '.completeness.docs_with_gaps | length')

    cat << EOF
╔══════════════════════════════════════════╗
║       Documentation Quality Report       ║
╠══════════════════════════════════════════╣
║  Overall Score:  $(score_color "$overall")/100  $(progress_bar "$overall")      ║
╠══════════════════════════════════════════╣
║  Coverage:       ${coverage}%     (${cov_docs}/${cov_total} files)   ║
║  Freshness:      ${freshness}%     (${fresh_avg} days avg)   ║
║  Completeness:   ${completeness}%     (${gaps} docs w/gaps) ║
╚══════════════════════════════════════════╝
EOF

    if [[ "$VERBOSE" == "true" ]]; then
        echo ""
        echo "Top Issues:"

        # Undocumented files
        echo "$quality" | jq -r '.coverage.undocumented[:5][]' 2>/dev/null | while read -r file; do
            echo " • $file - No documentation"
        done

        # Stale docs
        echo "$quality" | jq -r '.freshness.stale_docs[:5][] | " • \(.path) - \(.days_stale) days stale"' 2>/dev/null

        # Incomplete docs
        echo "$quality" | jq -r '.completeness.docs_with_gaps[:5][] | " • \(.path) - Missing: \(.missing | join(", "))"' 2>/dev/null
    fi
}

# JSON format
format_json() {
    local quality="$1"
    echo "$quality" | jq .
}

# Markdown format
format_markdown() {
    local quality="$1"

    local overall=$(echo "$quality" | jq -r '.overall_score')
    local coverage=$(echo "$quality" | jq -r '.coverage.score')
    local freshness=$(echo "$quality" | jq -r '.freshness.score')
    local completeness=$(echo "$quality" | jq -r '.completeness.score')

    cat << EOF
# Documentation Quality Report

**Overall Score: ${overall}/100**

| Metric | Score | Details |
|--------|-------|---------|
| Coverage | ${coverage}% | Files with documentation |
| Freshness | ${freshness}% | Docs up-to-date with source |
| Completeness | ${completeness}% | Docs with all sections |

EOF

    if [[ "$VERBOSE" == "true" ]]; then
        echo "## Issues"
        echo ""
        echo "### Undocumented Files"
        echo "$quality" | jq -r '.coverage.undocumented[]' | sed 's/^/- /'
        echo ""
        echo "### Stale Documentation"
        echo "$quality" | jq -r '.freshness.stale_docs[] | "- \(.path) (\(.days_stale) days)"'
    fi
}

# Main command
cmd_quality() {
    parse_quality_args "$@"

    local manifest="_manifest.json"
    if [[ ! -f "$manifest" ]]; then
        echo "ERROR: No manifest found. Run 'vdoc init' first." >&2
        exit 1
    fi

    local quality=$(calculate_quality "$manifest")

    case "$FORMAT" in
        json) format_json "$quality" ;;
        markdown) format_markdown "$quality" ;;
        terminal) format_terminal "$quality" ;;
    esac

    # Exit code based on threshold
    local score=$(echo "$quality" | jq -r '.overall_score')
    if [[ $score -lt $THRESHOLD ]]; then
        exit 1
    fi
}

cmd_quality "$@"
```

### 3.3 CLI Usage
```bash
# Basic usage
vdoc quality

# JSON output (for CI/scripts)
vdoc quality --json

# Markdown (for reports)
vdoc quality --md > quality-report.md

# Verbose with all issues
vdoc quality --verbose

# CI mode with threshold
vdoc quality --threshold 70 || echo "Quality gate failed!"
```

---

## 4. Notes
- Terminal colors disabled when output is piped
- Exit code 1 enables CI quality gates
- JSON output useful for dashboards and monitoring
- Markdown output useful for PR comments

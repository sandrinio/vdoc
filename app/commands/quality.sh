#!/usr/bin/env bash
# =============================================================================
# vdoc quality Command - Documentation Quality Report
# STORY-061: vdoc quality CLI command
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_DIR="${SCRIPT_DIR}/../../core"

# Source quality module
source "${CORE_DIR}/quality.sh"

# Defaults
MANIFEST_PATH="./vdocs/_manifest.json"
VDOCS_DIR="./vdocs"
THRESHOLD="${VDOC_QUALITY_THRESHOLD:-50}"
FORMAT="terminal"
VERBOSE=false
NO_COLOR=false

# Detect if output is not a terminal
[[ ! -t 1 ]] && NO_COLOR=true

# =============================================================================
# Color Helpers
# =============================================================================

red() {
    if [[ "$NO_COLOR" == "true" ]]; then
        echo "$1"
    else
        echo -e "\033[31m$1\033[0m"
    fi
}

yellow() {
    if [[ "$NO_COLOR" == "true" ]]; then
        echo "$1"
    else
        echo -e "\033[33m$1\033[0m"
    fi
}

green() {
    if [[ "$NO_COLOR" == "true" ]]; then
        echo "$1"
    else
        echo -e "\033[32m$1\033[0m"
    fi
}

bold() {
    if [[ "$NO_COLOR" == "true" ]]; then
        echo "$1"
    else
        echo -e "\033[1m$1\033[0m"
    fi
}

# Color a score based on value
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

# =============================================================================
# Progress Bar
# =============================================================================

progress_bar() {
    local score="$1"
    local filled=$((score / 10))
    local empty=$((10 - filled))

    local bar=""
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="░"; done

    echo "$bar"
}

# =============================================================================
# Output Formatters
# =============================================================================

# Terminal format with box drawing
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

    local score_display
    if [[ "$NO_COLOR" == "true" ]]; then
        score_display="$overall"
    else
        score_display=$(score_color "$overall")
    fi

    cat << EOF
$(bold "Documentation Quality Report")
════════════════════════════════════════════

  Overall Score:  ${score_display}/100  $(progress_bar "$overall")

────────────────────────────────────────────
  Coverage:       ${coverage}%     (${cov_docs}/${cov_total} files documented)
  Freshness:      ${freshness}%     (${fresh_avg} days avg staleness)
  Completeness:   ${completeness}%     (${gaps} docs with gaps)
════════════════════════════════════════════
EOF

    if [[ "$VERBOSE" == "true" ]]; then
        echo ""
        echo "$(bold "Top Issues:")"
        echo ""

        # Undocumented files (top 5)
        local undoc_count
        undoc_count=$(echo "$quality" | jq -r '.coverage.undocumented | length')
        if [[ $undoc_count -gt 0 ]]; then
            echo "  Undocumented Files:"
            echo "$quality" | jq -r '.coverage.undocumented[:5][]' 2>/dev/null | while read -r file; do
                echo "    - $file"
            done
            if [[ $undoc_count -gt 5 ]]; then
                echo "    ... and $((undoc_count - 5)) more"
            fi
            echo ""
        fi

        # Stale docs (top 5)
        local stale_count
        stale_count=$(echo "$quality" | jq -r '.freshness.stale_docs | length')
        if [[ $stale_count -gt 0 ]]; then
            echo "  Stale Documentation:"
            echo "$quality" | jq -r '.freshness.stale_docs[:5][] | "    - \(.path) (\(.days_stale) days stale)"' 2>/dev/null
            if [[ $stale_count -gt 5 ]]; then
                echo "    ... and $((stale_count - 5)) more"
            fi
            echo ""
        fi

        # Incomplete docs (top 5)
        local gaps_count
        gaps_count=$(echo "$quality" | jq -r '.completeness.docs_with_gaps | length')
        if [[ $gaps_count -gt 0 ]]; then
            echo "  Incomplete Documentation:"
            echo "$quality" | jq -r '.completeness.docs_with_gaps[:5][] | "    - \(.path) (missing: \(.missing | join(", ")))"' 2>/dev/null
            if [[ $gaps_count -gt 5 ]]; then
                echo "    ... and $((gaps_count - 5)) more"
            fi
        fi
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

    local cov_docs=$(echo "$quality" | jq -r '.coverage.documented_files')
    local cov_total=$(echo "$quality" | jq -r '.coverage.total_files')
    local computed=$(echo "$quality" | jq -r '.computed_at')

    cat << EOF
# Documentation Quality Report

**Overall Score: ${overall}/100**

*Computed: ${computed}*

| Metric | Score | Details |
|--------|-------|---------|
| Coverage | ${coverage}% | ${cov_docs}/${cov_total} files documented |
| Freshness | ${freshness}% | Based on doc vs source timestamps |
| Completeness | ${completeness}% | Required sections present |

EOF

    if [[ "$VERBOSE" == "true" ]]; then
        echo "## Issues"
        echo ""

        # Undocumented files
        local undoc
        undoc=$(echo "$quality" | jq -r '.coverage.undocumented[]' 2>/dev/null)
        if [[ -n "$undoc" ]]; then
            echo "### Undocumented Files"
            echo ""
            echo "$undoc" | sed 's/^/- /'
            echo ""
        fi

        # Stale docs
        local stale
        stale=$(echo "$quality" | jq -r '.freshness.stale_docs[] | "- \(.path) (\(.days_stale) days stale)"' 2>/dev/null)
        if [[ -n "$stale" ]]; then
            echo "### Stale Documentation"
            echo ""
            echo "$stale"
            echo ""
        fi

        # Incomplete docs
        local incomplete
        incomplete=$(echo "$quality" | jq -r '.completeness.docs_with_gaps[] | "- \(.path) - missing: \(.missing | join(", "))"' 2>/dev/null)
        if [[ -n "$incomplete" ]]; then
            echo "### Incomplete Documentation"
            echo ""
            echo "$incomplete"
        fi
    fi
}

# =============================================================================
# Usage
# =============================================================================

usage() {
    cat << EOF
Usage: $(basename "$0") [options]

Calculate and display documentation quality metrics.

Options:
    -h, --help          Show this help
    -v, --verbose       Show detailed file lists
    --json              Output as JSON
    --md, --markdown    Output as Markdown
    --threshold N       Set pass/fail threshold (default: 50)
    --manifest PATH     Path to manifest (default: ./vdocs/_manifest.json)
    --no-color          Disable colored output

Exit Codes:
    0 - Quality score >= threshold (pass)
    1 - Quality score < threshold (fail) or error

Score Interpretation:
    90-100  Excellent - Documentation is comprehensive and current
    75-89   Good - Minor gaps, generally healthy
    50-74   Fair - Significant gaps, needs attention
    25-49   Poor - Major documentation debt
    0-24    Critical - Documentation is severely lacking

Examples:
    $(basename "$0")                    # Terminal report
    $(basename "$0") --json             # JSON output
    $(basename "$0") -v --threshold 70  # Verbose with threshold
    $(basename "$0") --md > report.md   # Markdown report

EOF
}

# =============================================================================
# Main
# =============================================================================

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            --json)
                FORMAT="json"
                NO_COLOR=true
                shift
                ;;
            --md|--markdown)
                FORMAT="markdown"
                NO_COLOR=true
                shift
                ;;
            --threshold)
                THRESHOLD="$2"
                shift 2
                ;;
            --manifest)
                MANIFEST_PATH="$2"
                shift 2
                ;;
            --no-color)
                NO_COLOR=true
                shift
                ;;
            *)
                echo "ERROR: Unknown option: $1" >&2
                usage >&2
                exit 1
                ;;
        esac
    done

    # Check manifest exists
    if [[ ! -f "$MANIFEST_PATH" ]]; then
        echo "ERROR: No manifest found at $MANIFEST_PATH" >&2
        echo "Run 'vdoc scan -m' or check the path." >&2
        exit 1
    fi

    # Calculate quality
    local quality
    quality=$(calculate_quality "$MANIFEST_PATH" "$VDOCS_DIR")

    if [[ $? -ne 0 ]] || [[ -z "$quality" ]]; then
        echo "ERROR: Failed to calculate quality metrics" >&2
        exit 1
    fi

    # Output in selected format
    case "$FORMAT" in
        json)
            format_json "$quality"
            ;;
        markdown)
            format_markdown "$quality"
            ;;
        terminal)
            format_terminal "$quality"
            ;;
    esac

    # Exit code based on threshold
    local score
    score=$(echo "$quality" | jq -r '.overall_score')

    if [[ $score -lt $THRESHOLD ]]; then
        if [[ "$FORMAT" == "terminal" ]]; then
            echo ""
            red "Quality score ($score) is below threshold ($THRESHOLD)"
        fi
        exit 1
    fi
}

main "$@"

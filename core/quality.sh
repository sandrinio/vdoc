#!/usr/bin/env bash
# =============================================================================
# vdoc Quality Metrics - Documentation Health Scoring
# STORY-060: Quality scoring algorithm
# =============================================================================

# Default weights (must sum to 100)
COVERAGE_WEIGHT="${VDOC_COVERAGE_WEIGHT:-40}"
FRESHNESS_WEIGHT="${VDOC_FRESHNESS_WEIGHT:-35}"
COMPLETENESS_WEIGHT="${VDOC_COMPLETENESS_WEIGHT:-25}"

# Required sections for completeness checking
REQUIRED_SECTIONS=("overview" "usage" "examples")

# =============================================================================
# Coverage Score
# =============================================================================

# Calculate coverage: documented files / total files
# A file is "documented" if it has a non-empty documented_in array
calculate_coverage() {
    local manifest="$1"

    if [[ ! -f "$manifest" ]]; then
        echo '{"score": 0, "documented_files": 0, "total_files": 0, "undocumented": []}'
        return 1
    fi

    # Count total files and documented files using jq
    local stats
    stats=$(jq -r '
        .source_index // {} |
        to_entries |
        {
            total: length,
            documented: [.[] | select(.value.documented_in != null and (.value.documented_in | length) > 0)] | length,
            undocumented: [.[] | select(.value.documented_in == null or (.value.documented_in | length) == 0) | .key]
        }
    ' "$manifest" 2>/dev/null)

    if [[ -z "$stats" ]]; then
        echo '{"score": 0, "documented_files": 0, "total_files": 0, "undocumented": []}'
        return 1
    fi

    local total_files
    local documented_files
    total_files=$(echo "$stats" | jq -r '.total')
    documented_files=$(echo "$stats" | jq -r '.documented')

    # Calculate score (0-100)
    local score=0
    if [[ $total_files -gt 0 ]]; then
        score=$(( (documented_files * 100) / total_files ))
    fi

    # Build result JSON
    jq -n \
        --argjson score "$score" \
        --argjson documented "$documented_files" \
        --argjson total "$total_files" \
        --argjson undocumented "$(echo "$stats" | jq '.undocumented')" \
        '{
            score: $score,
            documented_files: $documented,
            total_files: $total,
            undocumented: $undocumented
        }'
}

# =============================================================================
# Freshness Score
# =============================================================================

# Calculate freshness: how recent are docs vs source files they cover
# Score decreases based on average staleness
calculate_freshness() {
    local manifest="$1"
    local vdocs_dir="${2:-./vdocs}"

    if [[ ! -f "$manifest" ]]; then
        echo '{"score": 100, "avg_days_stale": 0, "stale_docs": []}'
        return
    fi

    # Check if documentation section exists
    local doc_count
    doc_count=$(jq -r '.documentation | length // 0' "$manifest" 2>/dev/null)

    if [[ "$doc_count" -eq 0 ]]; then
        # No docs = 100% fresh (nothing to be stale)
        echo '{"score": 100, "avg_days_stale": 0, "stale_docs": []}'
        return
    fi

    local stale_docs_json="[]"
    local total_staleness=0
    local docs_checked=0
    local now_epoch
    now_epoch=$(date +%s)

    # Process each documentation entry
    while read -r doc_entry; do
        [[ -z "$doc_entry" ]] && continue

        local doc_path
        doc_path=$(echo "$doc_entry" | jq -r '.path')
        [[ -z "$doc_path" ]] && continue

        local doc_file="$vdocs_dir/$doc_path"
        [[ ! -f "$doc_file" ]] && continue

        # Get doc modification time (cross-platform)
        local doc_mtime
        if stat --version 2>&1 | grep -q GNU; then
            doc_mtime=$(stat -c %Y "$doc_file" 2>/dev/null)
        else
            doc_mtime=$(stat -f %m "$doc_file" 2>/dev/null)
        fi
        [[ -z "$doc_mtime" ]] && continue

        # Get files this doc covers
        local covers
        covers=$(echo "$doc_entry" | jq -r '.covers // [] | .[]')

        local max_source_mtime=0
        while read -r source_file; do
            [[ -z "$source_file" ]] && continue
            [[ ! -f "$source_file" ]] && continue

            local source_mtime
            if stat --version 2>&1 | grep -q GNU; then
                source_mtime=$(stat -c %Y "$source_file" 2>/dev/null)
            else
                source_mtime=$(stat -f %m "$source_file" 2>/dev/null)
            fi

            if [[ -n "$source_mtime" ]] && [[ $source_mtime -gt $max_source_mtime ]]; then
                max_source_mtime=$source_mtime
            fi
        done <<< "$covers"

        docs_checked=$((docs_checked + 1))

        # Check if doc is stale (source modified after doc)
        if [[ $max_source_mtime -gt $doc_mtime ]]; then
            local days_stale=$(( (max_source_mtime - doc_mtime) / 86400 ))
            total_staleness=$((total_staleness + days_stale))

            stale_docs_json=$(echo "$stale_docs_json" | jq \
                --arg path "$doc_path" \
                --argjson days "$days_stale" \
                '. + [{"path": $path, "days_stale": $days}]')
        fi
    done < <(jq -c '.documentation[]?' "$manifest" 2>/dev/null)

    # Calculate average staleness and score
    local avg_staleness=0
    if [[ $docs_checked -gt 0 ]]; then
        avg_staleness=$((total_staleness / docs_checked))
    fi

    # Score formula: 100 - (avg_staleness * 2), clamped to 0-100
    # Each day of average staleness costs 2 points
    local score=$((100 - (avg_staleness * 2)))
    [[ $score -lt 0 ]] && score=0
    [[ $score -gt 100 ]] && score=100

    jq -n \
        --argjson score "$score" \
        --argjson avg "$avg_staleness" \
        --argjson stale "$stale_docs_json" \
        '{
            score: $score,
            avg_days_stale: $avg,
            stale_docs: $stale
        }'
}

# =============================================================================
# Completeness Score
# =============================================================================

# Calculate completeness: do doc pages have all required sections?
calculate_completeness() {
    local manifest="$1"
    local vdocs_dir="${2:-./vdocs}"

    if [[ ! -f "$manifest" ]]; then
        echo '{"score": 100, "filled_sections": 0, "total_sections": 0, "docs_with_gaps": []}'
        return
    fi

    local doc_count
    doc_count=$(jq -r '.documentation | length // 0' "$manifest" 2>/dev/null)

    if [[ "$doc_count" -eq 0 ]]; then
        echo '{"score": 100, "filled_sections": 0, "total_sections": 0, "docs_with_gaps": []}'
        return
    fi

    local total_sections=0
    local filled_sections=0
    local docs_with_gaps_json="[]"

    while read -r doc_path; do
        [[ -z "$doc_path" ]] && continue

        local doc_file="$vdocs_dir/$doc_path"
        [[ ! -f "$doc_file" ]] && continue

        local missing_sections="[]"

        for section in "${REQUIRED_SECTIONS[@]}"; do
            total_sections=$((total_sections + 1))

            # Check if section heading exists (case insensitive)
            if grep -qi "^##.*$section" "$doc_file" 2>/dev/null; then
                filled_sections=$((filled_sections + 1))
            else
                missing_sections=$(echo "$missing_sections" | jq --arg s "$section" '. + [$s]')
            fi
        done

        # Add to gaps list if any sections are missing
        local missing_count
        missing_count=$(echo "$missing_sections" | jq 'length')
        if [[ $missing_count -gt 0 ]]; then
            docs_with_gaps_json=$(echo "$docs_with_gaps_json" | jq \
                --arg path "$doc_path" \
                --argjson missing "$missing_sections" \
                '. + [{"path": $path, "missing": $missing}]')
        fi
    done < <(jq -r '.documentation[].path // empty' "$manifest" 2>/dev/null)

    # Calculate score
    local score=100
    if [[ $total_sections -gt 0 ]]; then
        score=$((filled_sections * 100 / total_sections))
    fi

    jq -n \
        --argjson score "$score" \
        --argjson filled "$filled_sections" \
        --argjson total "$total_sections" \
        --argjson gaps "$docs_with_gaps_json" \
        '{
            score: $score,
            filled_sections: $filled,
            total_sections: $total,
            docs_with_gaps: $gaps
        }'
}

# =============================================================================
# Overall Score
# =============================================================================

# Calculate weighted overall score
calculate_overall() {
    local coverage_score="$1"
    local freshness_score="$2"
    local completeness_score="$3"

    local score=$(( (coverage_score * COVERAGE_WEIGHT + freshness_score * FRESHNESS_WEIGHT + completeness_score * COMPLETENESS_WEIGHT) / 100 ))

    # Clamp to 0-100
    [[ $score -lt 0 ]] && score=0
    [[ $score -gt 100 ]] && score=100

    echo "$score"
}

# =============================================================================
# Main Quality Calculation
# =============================================================================

# Calculate all quality metrics and return combined JSON
calculate_quality() {
    local manifest="$1"
    local vdocs_dir="${2:-./vdocs}"

    if [[ ! -f "$manifest" ]]; then
        echo "ERROR: Manifest not found: $manifest" >&2
        return 1
    fi

    # Calculate individual metrics
    local coverage
    local freshness
    local completeness

    coverage=$(calculate_coverage "$manifest")
    freshness=$(calculate_freshness "$manifest" "$vdocs_dir")
    completeness=$(calculate_completeness "$manifest" "$vdocs_dir")

    # Extract scores
    local coverage_score
    local freshness_score
    local completeness_score

    coverage_score=$(echo "$coverage" | jq -r '.score // 0')
    freshness_score=$(echo "$freshness" | jq -r '.score // 100')
    completeness_score=$(echo "$completeness" | jq -r '.score // 100')

    # Calculate overall
    local overall
    overall=$(calculate_overall "$coverage_score" "$freshness_score" "$completeness_score")

    # Build combined result
    jq -n \
        --argjson overall "$overall" \
        --argjson coverage "$coverage" \
        --argjson freshness "$freshness" \
        --argjson completeness "$completeness" \
        --argjson cov_weight "$COVERAGE_WEIGHT" \
        --argjson fresh_weight "$FRESHNESS_WEIGHT" \
        --argjson comp_weight "$COMPLETENESS_WEIGHT" \
        --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        '{
            overall_score: $overall,
            coverage: $coverage,
            freshness: $freshness,
            completeness: $completeness,
            weights: {
                coverage: $cov_weight,
                freshness: $fresh_weight,
                completeness: $comp_weight
            },
            computed_at: $timestamp
        }'
}

# =============================================================================
# CLI Interface
# =============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        coverage)
            if [[ -z "$2" ]]; then
                echo "Usage: $0 coverage <manifest_path>"
                exit 1
            fi
            calculate_coverage "$2"
            ;;
        freshness)
            if [[ -z "$2" ]]; then
                echo "Usage: $0 freshness <manifest_path> [vdocs_dir]"
                exit 1
            fi
            calculate_freshness "$2" "${3:-./vdocs}"
            ;;
        completeness)
            if [[ -z "$2" ]]; then
                echo "Usage: $0 completeness <manifest_path> [vdocs_dir]"
                exit 1
            fi
            calculate_completeness "$2" "${3:-./vdocs}"
            ;;
        calculate|quality)
            if [[ -z "$2" ]]; then
                echo "Usage: $0 calculate <manifest_path> [vdocs_dir]"
                exit 1
            fi
            calculate_quality "$2" "${3:-./vdocs}"
            ;;
        *)
            echo "Usage: $0 {coverage|freshness|completeness|calculate} <manifest_path> [vdocs_dir]"
            echo ""
            echo "Commands:"
            echo "  coverage <manifest>         - Calculate coverage score"
            echo "  freshness <manifest> [dir]  - Calculate freshness score"
            echo "  completeness <manifest> [dir] - Calculate completeness score"
            echo "  calculate <manifest> [dir]  - Calculate all quality metrics"
            echo ""
            echo "Environment:"
            echo "  VDOC_COVERAGE_WEIGHT     - Coverage weight (default: 40)"
            echo "  VDOC_FRESHNESS_WEIGHT    - Freshness weight (default: 35)"
            echo "  VDOC_COMPLETENESS_WEIGHT - Completeness weight (default: 25)"
            exit 1
            ;;
    esac
fi

#!/usr/bin/env bash
# =============================================================================
# vdoc - AI-Powered Documentation Generator
# Unified CLI Entry Point
# STORY-070: Create vdoc unified CLI wrapper
# =============================================================================

set -euo pipefail

VDOC_VERSION="2.0.0"

# =============================================================================
# Resolve Installation Directory
# =============================================================================

# Priority: VDOC_HOME env var > ~/.vdoc > script location
if [[ -n "${VDOC_HOME:-}" ]] && [[ -d "$VDOC_HOME" ]]; then
    VDOC_DIR="$VDOC_HOME"
elif [[ -d "${HOME}/.vdoc" ]]; then
    VDOC_DIR="${HOME}/.vdoc"
else
    # Development mode: use script's parent directory
    VDOC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

# Verify core files exist
if [[ ! -f "${VDOC_DIR}/core/scan.sh" ]]; then
    echo "ERROR: vdoc installation not found at $VDOC_DIR" >&2
    echo "Run the installer: curl -fsSL https://vdoc.dev/install | bash" >&2
    exit 1
fi

# =============================================================================
# Colors & Output
# =============================================================================

if [[ -t 1 ]] && [[ "${TERM:-}" != "dumb" ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    BOLD=''
    NC=''
fi

log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_warning() { echo -e "${YELLOW}!${NC} $1"; }
log_error()   { echo -e "${RED}✗${NC} $1" >&2; }
log_info()    { echo -e "${BLUE}→${NC} $1"; }

# =============================================================================
# Usage & Help
# =============================================================================

usage() {
    cat << EOF
${BOLD}vdoc${NC} - AI-Powered Documentation Generator

${BOLD}USAGE${NC}
    vdoc <command> [options]

${BOLD}COMMANDS${NC}
    init [--ai PLATFORM]    Initialize vdoc in current project
    scan [options]          Scan codebase and update manifest
    quality [options]       Show documentation quality report
    install <platform>      Install AI platform integration
    uninstall <platform>    Remove AI platform integration
    help                    Show this help
    version                 Show version

${BOLD}PLATFORMS${NC}
    claude      Claude Code
    cursor      Cursor
    windsurf    Windsurf
    aider       Aider
    continue    Continue (VS Code)

${BOLD}SCAN OPTIONS${NC}
    --full              Force full scan (ignore incremental)
    --skip-quality      Skip quality metrics calculation
    -v, --verbose       Verbose output

${BOLD}QUALITY OPTIONS${NC}
    --json              Output as JSON
    --md, --markdown    Output as Markdown
    --verbose, -v       Show detailed file lists
    --threshold N       Set pass/fail threshold (default: 50)

${BOLD}EXAMPLES${NC}
    vdoc init --ai claude       Initialize + install Claude integration
    vdoc scan                   Update manifest with code changes
    vdoc scan --full            Force full rescan
    vdoc quality                Show quality report
    vdoc quality --json         JSON output for CI
    vdoc quality --threshold 70 Fail if score < 70
    vdoc install cursor         Add Cursor integration

${BOLD}MORE INFO${NC}
    https://github.com/sandrinio/vdoc

EOF
}

# =============================================================================
# Helper Functions
# =============================================================================

# Find project root (directory with vdocs/ or .git/)
find_project_root() {
    local dir="$PWD"

    while [[ "$dir" != "/" ]]; do
        if [[ -d "$dir/vdocs" ]] || [[ -d "$dir/.git" ]]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done

    # Not found, use current directory
    echo "$PWD"
}

# Ensure we're in a project directory
ensure_project() {
    local project_root
    project_root=$(find_project_root)

    if [[ "$PWD" != "$project_root" ]]; then
        cd "$project_root"
    fi
}

# =============================================================================
# Commands
# =============================================================================

cmd_init() {
    local platform=""
    local force=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --ai|--ai=*)
                if [[ "$1" == --ai=* ]]; then
                    platform="${1#--ai=}"
                else
                    platform="${2:-}"
                    shift
                fi
                shift
                ;;
            --force|-f)
                force=true
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    echo ""
    echo -e "${BOLD}Initializing vdoc...${NC}"
    echo ""

    # Check if already initialized
    if [[ -d "vdocs" ]] && [[ "$force" != "true" ]]; then
        log_warning "vdocs/ already exists"
        log_info "Use --force to reinitialize"

        if [[ -n "$platform" ]]; then
            log_info "Installing $platform integration..."
            cmd_install "$platform"
        fi
        return 0
    fi

    # Create directory structure
    mkdir -p vdocs/.vdoc/presets
    log_success "Created vdocs/ directory"

    # Copy custom preset template if not exists
    if [[ ! -f "vdocs/.vdoc/presets/custom.conf.example" ]]; then
        cat > "vdocs/.vdoc/presets/custom.conf.example" << 'PRESET'
# Custom vdoc Preset
# Copy to custom-mypreset.conf and modify

# Inherit from a base preset
EXTENDS="default"

# Override patterns
# EXCLUDE_DIRS="node_modules vendor dist"
# ENTRY_PATTERNS="*.ts *.tsx"
PRESET
        log_success "Created preset template"
    fi

    # Run initial scan
    log_info "Running initial scan..."
    if bash "${VDOC_DIR}/core/scan.sh" -m -q; then
        log_success "Generated _manifest.json"
    else
        log_warning "Scan completed with warnings"
    fi

    # Install platform if specified
    if [[ -n "$platform" ]]; then
        echo ""
        cmd_install "$platform"
    fi

    # Success message
    echo ""
    log_success "vdoc initialized!"
    echo ""
    echo "Next steps:"
    if [[ -n "$platform" ]]; then
        case "$platform" in
            claude)
                echo "  1. Open Claude Code in this project"
                echo "  2. Say: \"generate documentation for this project\""
                ;;
            cursor)
                echo "  1. Open Cursor in this project"
                echo "  2. Ask: \"generate documentation for this project\""
                ;;
            *)
                echo "  1. Open your AI tool in this project"
                echo "  2. Ask: \"generate documentation for this project\""
                ;;
        esac
    else
        echo "  1. Run: vdoc install <platform>"
        echo "  2. Open your AI tool and generate docs"
    fi
    echo ""
    echo "Documentation will be created in ./vdocs/"
    echo ""
}

cmd_scan() {
    ensure_project

    # Check if initialized
    if [[ ! -d "vdocs" ]]; then
        log_error "vdoc not initialized. Run 'vdoc init' first."
        exit 1
    fi

    # Pass all arguments to scan.sh with -m flag
    bash "${VDOC_DIR}/core/scan.sh" -m "$@"
}

cmd_quality() {
    ensure_project

    # Check if manifest exists
    if [[ ! -f "vdocs/_manifest.json" ]]; then
        log_error "No manifest found. Run 'vdoc init' or 'vdoc scan' first."
        exit 1
    fi

    # Run quality command
    bash "${VDOC_DIR}/app/commands/quality.sh" "$@"
}

cmd_install() {
    local platform="${1:-}"

    if [[ -z "$platform" ]]; then
        log_error "Please specify a platform: claude, cursor, windsurf, aider, continue"
        exit 1
    fi

    # Validate platform
    case "$platform" in
        claude|cursor|windsurf|aider|continue)
            ;;
        *)
            log_error "Unknown platform: $platform"
            echo "Valid platforms: claude, cursor, windsurf, aider, continue" >&2
            exit 1
            ;;
    esac

    ensure_project

    # Ensure vdocs exists
    if [[ ! -d "vdocs" ]]; then
        mkdir -p vdocs/.vdoc/presets
        log_success "Created vdocs/ directory"
    fi

    # Run the platform adapter
    local adapter="${VDOC_DIR}/adapters/${platform}/generate.sh"

    if [[ ! -f "$adapter" ]]; then
        log_error "Adapter not found: $adapter"
        exit 1
    fi

    log_info "Installing $platform integration..."

    if bash "$adapter"; then
        log_success "Installed $platform integration"
    else
        log_error "Failed to install $platform integration"
        exit 1
    fi
}

cmd_uninstall() {
    local platform="${1:-}"

    if [[ -z "$platform" ]]; then
        log_error "Please specify a platform to uninstall"
        exit 1
    fi

    # Use the existing install.sh uninstall command
    bash "${VDOC_DIR}/install.sh" uninstall "$platform" -y
}

cmd_version() {
    echo "vdoc v${VDOC_VERSION}"
    echo ""
    echo "Installation: $VDOC_DIR"

    # Show detected project info if in a project
    if [[ -f "vdocs/_manifest.json" ]]; then
        local project
        project=$(jq -r '.project // "unknown"' vdocs/_manifest.json 2>/dev/null || echo "unknown")
        echo "Project: $project"

        # Show quality score if available
        local score
        score=$(jq -r '.quality.overall_score // empty' vdocs/_manifest.json 2>/dev/null)
        if [[ -n "$score" ]]; then
            echo "Quality: ${score}/100"
        fi
    fi
}

# =============================================================================
# Main
# =============================================================================

main() {
    local command="${1:-help}"

    case "$command" in
        -h|--help|help)
            usage
            ;;
        -v|--version|version)
            cmd_version
            ;;
        init)
            shift
            cmd_init "$@"
            ;;
        scan)
            shift
            cmd_scan "$@"
            ;;
        quality)
            shift
            cmd_quality "$@"
            ;;
        install)
            shift
            cmd_install "$@"
            ;;
        uninstall)
            shift
            cmd_uninstall "$@"
            ;;
        *)
            log_error "Unknown command: $command"
            echo ""
            usage >&2
            exit 1
            ;;
    esac
}

main "$@"

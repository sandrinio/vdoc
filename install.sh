#!/usr/bin/env bash
# vdoc Universal Installer
# Usage: curl -fsSL vdoc.dev/install | bash -s -- <platform>
# Platforms: claude, cursor, windsurf, aider, continue

set -euo pipefail

# =============================================================================
# Configuration
# =============================================================================

VDOC_VERSION="2.0.0"
VDOC_REPO="https://github.com/sandrinio/vdoc"
VALID_PLATFORMS="claude cursor windsurf aider continue"

# Source directory (where this script lives)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Exit codes
EXIT_SUCCESS=0
EXIT_INVALID_ARGS=1
EXIT_VALIDATION_FAILED=2
EXIT_PERMISSION_DENIED=3
EXIT_MISSING_FILES=4

# =============================================================================
# Colors & Logging (STORY-011)
# =============================================================================

# Check if colors are supported
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
log_error()   { echo -e "${RED}✗${NC} $1"; }
log_info()    { echo -e "${BLUE}→${NC} $1"; }

# =============================================================================
# Validation Functions (STORY-018)
# =============================================================================

validate_bash_version() {
    local bash_major="${BASH_VERSION%%.*}"
    # Require bash 3.2+ (macOS default)
    if [[ "$bash_major" -lt 3 ]]; then
        log_error "Bash 3.2+ required (found: $BASH_VERSION)"
        exit $EXIT_VALIDATION_FAILED
    fi
}

validate_not_root_dir() {
    local current_dir
    current_dir="$(pwd)"
    
    if [[ "$current_dir" == "/" ]]; then
        log_error "Cannot install in filesystem root"
        echo "  → Run from your project directory"
        exit $EXIT_VALIDATION_FAILED
    fi
}

validate_write_permissions() {
    if ! touch ".vdoc-test-write" 2>/dev/null; then
        log_error "Permission denied: cannot write to current directory"
        echo "  → Check directory permissions"
        exit $EXIT_PERMISSION_DENIED
    fi
    rm -f ".vdoc-test-write"
}

validate_not_empty_dir() {
    # Only warn in interactive mode
    if [[ -t 0 ]] && [[ -z "$(ls -A 2>/dev/null)" ]]; then
        log_warning "Directory appears empty. Is this your project root?"
        read -p "Continue anyway? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Installation cancelled."
            exit $EXIT_SUCCESS
        fi
    fi
}

validate_source_files() {
    local source_dir="$1"
    local required_files=(
        "core/scan.sh"
        "core/instructions.md"
        "core/presets/default.conf"
    )
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "${source_dir}/${file}" ]]; then
            log_error "Missing required file: $file"
            echo "  → Source directory may be incomplete: $source_dir"
            exit $EXIT_MISSING_FILES
        fi
    done
}

validate_platform() {
    local platform="$1"
    for valid in $VALID_PLATFORMS; do
        [[ "$platform" == "$valid" ]] && return 0
    done
    return 1
}

validate_environment() {
    validate_bash_version
    validate_not_root_dir
    validate_write_permissions
    validate_not_empty_dir
}

# Cleanup on error
cleanup_on_error() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        log_error "Installation failed (exit code: $exit_code)"
        # Remove partially created directories
        if [[ -d "./vdocs/.vdoc" ]] && [[ ! -f "./vdocs/_manifest.json" ]]; then
            rm -rf "./vdocs/.vdoc"
            rmdir "./vdocs" 2>/dev/null || true
            log_info "Cleaned up partial installation"
        fi
    fi
}

trap cleanup_on_error EXIT

# =============================================================================
# Usage & Help (STORY-011)
# =============================================================================

usage() {
    cat << EOF
${BOLD}vdoc installer v${VDOC_VERSION}${NC}

AI-Powered Product Documentation Generator

${BOLD}USAGE${NC}
    $0 <platform>
    $0 [options]

${BOLD}PLATFORMS${NC}
    claude      Claude Code (generates ~/.claude/skills/vdoc/SKILL.md)
    cursor      Cursor (generates .cursor/rules/vdoc.md)
    windsurf    Windsurf (generates .windsurfrules)
    aider       Aider (generates .aider conventions)
    continue    Continue VS Code (generates .continue/ config)

${BOLD}OPTIONS${NC}
    -h, --help      Show this help message
    -v, --version   Show version number
    -a, --auto      Auto-detect and install for all found platforms

${BOLD}COMMANDS${NC}
    uninstall <platform>    Remove platform integration (preserves docs)
    uninstall --all         Remove everything including vdocs/

${BOLD}EXAMPLES${NC}
    # Install for Claude Code
    $0 claude

    # Install for Cursor
    $0 cursor

    # Auto-detect and install for all platforms
    $0 --auto

    # Uninstall Cursor integration
    $0 uninstall cursor

    # Uninstall everything
    $0 uninstall --all -y

${BOLD}MORE INFO${NC}
    Repository: ${VDOC_REPO}

EOF
}

# =============================================================================
# Language Detection (STORY-012)
# =============================================================================

detect_language() {
    # Check for explicit config first
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

# =============================================================================
# Directory Structure Setup (STORY-013)
# =============================================================================

setup_directories() {
    local dirs=(
        "./vdocs"
        "./vdocs/.vdoc"
        "./vdocs/.vdoc/presets"
        "./vdocs/.vdoc/templates"
    )
    
    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            log_success "Created $dir"
        fi
    done
}

copy_core_files() {
    local source_dir="$1"
    local target_dir="./vdocs/.vdoc"
    
    # Copy main files
    local files=(
        "core/scan.sh:scan.sh"
        "core/instructions.md:instructions.md"
        "core/setup.sh:setup.sh"
    )

    for mapping in "${files[@]}"; do
        local src="${source_dir}/${mapping%%:*}"
        local dst="${target_dir}/${mapping##*:}"

        if [[ -f "$src" ]]; then
            if [[ ! -f "$dst" ]]; then
                cp "$src" "$dst"
                log_success "Copied ${mapping##*:}"
            else
                log_info "Exists: ${mapping##*:}"
            fi
        fi
    done

    # Make scripts executable
    chmod +x "${target_dir}/scan.sh"
    [[ -f "${target_dir}/setup.sh" ]] && chmod +x "${target_dir}/setup.sh"
    
    # Copy presets
    for preset in "${source_dir}"/core/presets/*.conf; do
        local name
        name=$(basename "$preset")
        local dst="${target_dir}/presets/${name}"
        if [[ ! -f "$dst" ]]; then
            cp "$preset" "$dst"
            log_success "Copied preset: $name"
        fi
    done
    
    # Copy templates
    for template in "${source_dir}"/core/templates/*; do
        local name
        name=$(basename "$template")
        local dst="${target_dir}/templates/${name}"
        if [[ ! -f "$dst" ]]; then
            cp "$template" "$dst"
            log_success "Copied template: $name"
        fi
    done
}

# =============================================================================
# Platform Detection (STORY-032)
# =============================================================================

detect_installed_platforms() {
    local platforms=()

    # Claude Code (check home directory)
    if [[ -d "${HOME}/.claude" ]]; then
        platforms+=("claude")
    fi

    # Cursor (project-level)
    if [[ -d ".cursor" ]]; then
        platforms+=("cursor")
    fi

    # Continue (project-level or user-level)
    if [[ -d ".continue" ]] || [[ -d "${HOME}/.continue" ]]; then
        platforms+=("continue")
    fi

    # Windsurf (project-level)
    if [[ -f ".windsurfrules" ]]; then
        platforms+=("windsurf")
    fi

    # Aider (project-level)
    if [[ -f ".aider.conf.yml" ]] || [[ -d ".aider" ]]; then
        platforms+=("aider")
    fi

    # If no platforms detected, default to claude (most common)
    if [[ ${#platforms[@]} -eq 0 ]]; then
        platforms+=("claude")
    fi

    echo "${platforms[@]}"
}

# =============================================================================
# Platform Adapters (STORY-015, STORY-016)
# =============================================================================

run_adapter() {
    local platform="$1"
    local source_dir="$2"
    local adapter_script="${source_dir}/adapters/${platform}/generate.sh"
    
    if [[ ! -f "$adapter_script" ]]; then
        log_warning "Adapter not found: $adapter_script"
        return 1
    fi
    
    # Run adapter
    if bash "$adapter_script"; then
        log_success "Generated ${platform} integration"
        return 0
    else
        log_warning "Adapter had issues (non-fatal)"
        return 1
    fi
}

# =============================================================================
# Gitignore Update (STORY-017)
# =============================================================================

update_gitignore() {
    local platform="$1"
    local gitignore=".gitignore"
    
    # Platform-specific patterns
    local platform_pattern=""
    case "$platform" in
        claude)
            # Claude skill is in ~/.claude/, not project - nothing project-specific
            platform_pattern=""
            ;;
        cursor)
            platform_pattern=".cursor/rules/vdoc.md"
            ;;
        windsurf)
            platform_pattern=".windsurfrules"
            ;;
        aider)
            platform_pattern=".aider.conf.yml"
            ;;
        continue)
            platform_pattern=".continue/"
            ;;
    esac
    
    # Common patterns
    local patterns=(
        ""
        "# vdoc - generated files"
        ".vdoc.lock"
        ".vdoc-scan-output"
    )
    
    # Add platform pattern if exists
    [[ -n "$platform_pattern" ]] && patterns+=("$platform_pattern")
    
    # Create .gitignore if missing
    [[ ! -f "$gitignore" ]] && touch "$gitignore"
    
    # Add patterns if not present
    local added=0
    for pattern in "${patterns[@]}"; do
        [[ -z "$pattern" ]] && continue
        if ! grep -qxF "$pattern" "$gitignore" 2>/dev/null; then
            echo "$pattern" >> "$gitignore"
            ((added++)) || true
        fi
    done
    
    if [[ $added -gt 0 ]]; then
        log_success "Updated .gitignore (+$added entries)"
    else
        log_info ".gitignore already up to date"
    fi
}

# =============================================================================
# Uninstall (STORY-033)
# =============================================================================

uninstall_platform() {
    local platform="$1"
    local removed=0

    case "$platform" in
        claude)
            if [[ -d "${HOME}/.claude/skills/vdoc" ]]; then
                rm -rf "${HOME}/.claude/skills/vdoc"
                log_success "Removed: ~/.claude/skills/vdoc/"
                ((removed++)) || true
            fi
            ;;
        cursor)
            if [[ -f ".cursor/rules/vdoc.md" ]]; then
                rm -f ".cursor/rules/vdoc.md"
                log_success "Removed: .cursor/rules/vdoc.md"
                ((removed++)) || true
                # Remove empty rules directory
                rmdir ".cursor/rules" 2>/dev/null || true
            fi
            ;;
        windsurf)
            if [[ -f ".windsurfrules" ]]; then
                # Remove vdoc section from .windsurfrules
                local vdoc_marker="# vdoc Documentation Generator"
                local vdoc_end_marker="# END vdoc"
                if grep -q "$vdoc_marker" ".windsurfrules" 2>/dev/null; then
                    sed "/${vdoc_marker}/,/${vdoc_end_marker}/d" ".windsurfrules" > ".windsurfrules.tmp"
                    mv ".windsurfrules.tmp" ".windsurfrules"
                    # Remove file if empty (only whitespace)
                    if [[ ! -s ".windsurfrules" ]] || ! grep -q '[^[:space:]]' ".windsurfrules"; then
                        rm -f ".windsurfrules"
                    fi
                    log_success "Removed: vdoc section from .windsurfrules"
                    ((removed++)) || true
                fi
            fi
            ;;
        aider)
            if [[ -f ".aider/conventions/vdoc.md" ]]; then
                rm -f ".aider/conventions/vdoc.md"
                rmdir ".aider/conventions" 2>/dev/null || true
                log_success "Removed: .aider/conventions/vdoc.md"
                ((removed++)) || true
            fi
            # Remove vdoc entry from config
            if [[ -f ".aider.conf.yml" ]] && grep -q "conventions/vdoc.md" ".aider.conf.yml" 2>/dev/null; then
                grep -v "conventions/vdoc.md" ".aider.conf.yml" | grep -v "# vdoc" > ".aider.conf.yml.tmp"
                mv ".aider.conf.yml.tmp" ".aider.conf.yml"
                log_success "Updated: .aider.conf.yml"
            fi
            ;;
        continue)
            if [[ -f ".continue/prompts/vdoc.md" ]]; then
                rm -f ".continue/prompts/vdoc.md"
                rmdir ".continue/prompts" 2>/dev/null || true
                log_success "Removed: .continue/prompts/vdoc.md"
                ((removed++)) || true
            fi
            # Note: We don't remove config.json as user may have other settings
            if [[ -f ".continue/config.json" ]] && grep -q '"vdoc"' ".continue/config.json" 2>/dev/null; then
                log_info "Note: Remove 'vdoc' entry from .continue/config.json manually"
            fi
            ;;
    esac

    return 0
}

remove_gitignore_entries() {
    local gitignore=".gitignore"
    [[ ! -f "$gitignore" ]] && return

    local patterns=(
        "# vdoc - generated files"
        ".vdoc.lock"
        ".vdoc-scan-output"
        ".cursor/rules/vdoc.md"
        ".windsurfrules"
        ".aider.conf.yml"
        ".continue/"
    )

    local temp_file="${gitignore}.tmp"
    cp "$gitignore" "$temp_file"

    for pattern in "${patterns[@]}"; do
        grep -vxF "$pattern" "$temp_file" > "${temp_file}.2" 2>/dev/null || true
        mv "${temp_file}.2" "$temp_file"
    done

    if ! diff -q "$gitignore" "$temp_file" >/dev/null 2>&1; then
        mv "$temp_file" "$gitignore"
        log_success "Cleaned .gitignore"
    else
        rm -f "$temp_file"
    fi
}

run_uninstall() {
    local platform=""
    local remove_all=false
    local force=false

    # Parse all uninstall arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --all)
                remove_all=true
                shift
                ;;
            -y|--yes)
                force=true
                shift
                ;;
            -*)
                log_error "Unknown option: $1"
                exit 1
                ;;
            *)
                if [[ -z "$platform" ]]; then
                    platform="$1"
                fi
                shift
                ;;
        esac
    done

    echo ""
    echo -e "${BOLD}vdoc uninstaller${NC}"
    echo ""

    if $remove_all; then
        echo "This will remove:"
        echo "  - All platform integrations"
        echo "  - vdocs/.vdoc/ (shared tools)"
        echo "  - vdocs/ (your documentation)"
        echo ""

        if ! $force; then
            read -p "Are you sure? [y/N] " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo "Uninstall cancelled."
                exit 0
            fi
        fi

        # Remove all platforms
        for p in claude cursor windsurf aider continue; do
            uninstall_platform "$p" || true
        done

        # Remove vdocs directory
        if [[ -d "vdocs" ]]; then
            rm -rf "vdocs"
            log_success "Removed: vdocs/"
        fi

        remove_gitignore_entries
        echo ""
        log_success "Complete uninstall finished"
    else
        # Single platform uninstall
        if [[ -z "$platform" ]]; then
            log_error "Please specify a platform to uninstall"
            echo "  Usage: $0 uninstall <platform>"
            echo "  Usage: $0 uninstall --all"
            exit 1
        fi

        if ! validate_platform "$platform"; then
            log_error "Unknown platform: $platform"
            exit 1
        fi

        echo "This will remove:"
        case "$platform" in
            claude)   echo "  - ~/.claude/skills/vdoc/" ;;
            cursor)   echo "  - .cursor/rules/vdoc.md" ;;
            windsurf) echo "  - vdoc section from .windsurfrules" ;;
            aider)    echo "  - .aider/conventions/vdoc.md" ;;
            continue) echo "  - .continue/prompts/vdoc.md" ;;
        esac
        echo ""
        echo "This will preserve:"
        echo "  - vdocs/ (your documentation)"
        echo "  - vdocs/.vdoc/ (shared tools)"
        echo ""

        if ! $force; then
            read -p "Continue? [y/N] " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo "Uninstall cancelled."
                exit 0
            fi
        fi

        uninstall_platform "$platform"
        echo ""
        log_success "Uninstall complete"
        echo "Your documentation in vdocs/ was preserved."
    fi
}

# =============================================================================
# Next Steps (STORY-016)
# =============================================================================

print_next_steps() {
    local platform="$1"
    
    echo ""
    echo -e "${BOLD}Next steps:${NC}"
    echo ""
    
    case "$platform" in
        claude)
            echo "  1. Open Claude Code in this project"
            echo "  2. Type: /vdoc"
            echo "     Or say: \"generate documentation for this project\""
            ;;
        cursor)
            echo "  1. Open Cursor in this project"
            echo "  2. The vdoc rules are now active"
            echo "  3. Ask: \"generate documentation for this project\""
            ;;
        windsurf)
            echo "  1. Open Windsurf in this project"
            echo "  2. Ask Cascade: \"generate documentation for this project\""
            ;;
        aider)
            echo "  1. Run aider in this project"
            echo "  2. Say: \"generate documentation for this project\""
            ;;
        continue)
            echo "  1. Open VS Code with Continue in this project"
            echo "  2. Ask: \"generate documentation for this project\""
            ;;
    esac
    
    echo ""
    echo "  Documentation will be created in ./vdocs/"
    echo ""
}

# =============================================================================
# Main (STORY-011)
# =============================================================================

main() {
    local auto_mode=false
    local platforms=()

    # Handle flags and commands first
    case "${1:-}" in
        -h|--help)
            usage
            exit $EXIT_SUCCESS
            ;;
        -v|--version)
            echo "vdoc v${VDOC_VERSION}"
            exit $EXIT_SUCCESS
            ;;
        -a|--auto)
            auto_mode=true
            ;;
        uninstall)
            shift
            run_uninstall "$@"
            exit $EXIT_SUCCESS
            ;;
        "")
            usage
            exit $EXIT_INVALID_ARGS
            ;;
    esac

    # Header
    echo ""
    echo -e "${BOLD}vdoc installer v${VDOC_VERSION}${NC}"
    echo ""

    # Validate environment
    validate_environment

    # Validate source files
    validate_source_files "$SCRIPT_DIR"

    # Determine platforms to install
    if $auto_mode; then
        log_info "Detecting installed AI tools..."
        # shellcheck disable=SC2207
        platforms=($(detect_installed_platforms))
        log_success "Found: ${platforms[*]}"
        echo ""
    else
        local platform="$1"
        # Validate platform
        if ! validate_platform "$platform"; then
            log_error "Unknown platform: $platform"
            echo "  → Valid platforms: $VALID_PLATFORMS"
            exit $EXIT_INVALID_ARGS
        fi
        platforms=("$platform")
    fi

    # Detect language
    local language
    language=$(detect_language)
    log_success "Detected language: ${language}"

    # Setup directories
    setup_directories

    # Copy core files
    copy_core_files "$SCRIPT_DIR"

    # Run adapters for each platform
    local successful_platforms=()
    for platform in "${platforms[@]}"; do
        if run_adapter "$platform" "$SCRIPT_DIR"; then
            successful_platforms+=("$platform")
            update_gitignore "$platform"
        fi
    done

    # Success message
    echo ""
    if [[ ${#successful_platforms[@]} -gt 0 ]]; then
        if $auto_mode && [[ ${#successful_platforms[@]} -gt 1 ]]; then
            log_success "Installation complete for ${#successful_platforms[@]} platforms!"
            echo ""
            echo -e "${BOLD}Installed for:${NC} ${successful_platforms[*]}"
        else
            log_success "Installation complete!"
        fi
    else
        log_error "No platforms were installed successfully"
        exit 1
    fi

    # Print next steps (for single platform or first in auto mode)
    print_next_steps "${successful_platforms[0]}"
}

main "$@"

#!/usr/bin/env bash
# =============================================================================
# vdoc Global Installer
# STORY-071: Create global installer script
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/sandrinio/vdoc/main/scripts/install-global.sh | bash
#   curl -fsSL https://vdoc.dev/install | bash
#
# Options:
#   --version X.X.X   Install specific version
#   --uninstall       Remove vdoc
#   --help            Show help
# =============================================================================

set -euo pipefail

# Configuration
VDOC_VERSION="${VDOC_VERSION:-latest}"
VDOC_REPO="${VDOC_REPO:-sandrinio/vdoc}"
VDOC_HOME="${VDOC_HOME:-$HOME/.vdoc}"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"

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
# Parse Arguments
# =============================================================================

UNINSTALL=false
SHOW_HELP=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --version)
            VDOC_VERSION="${2:-latest}"
            shift 2
            ;;
        --version=*)
            VDOC_VERSION="${1#--version=}"
            shift
            ;;
        --uninstall)
            UNINSTALL=true
            shift
            ;;
        --help|-h)
            SHOW_HELP=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# =============================================================================
# Help
# =============================================================================

if $SHOW_HELP; then
    cat << EOF
${BOLD}vdoc installer${NC}

${BOLD}USAGE${NC}
    curl -fsSL https://vdoc.dev/install | bash
    curl -fsSL https://vdoc.dev/install | bash -s -- [OPTIONS]

${BOLD}OPTIONS${NC}
    --version X.X.X   Install specific version (default: latest)
    --uninstall       Remove vdoc from system
    --help            Show this help

${BOLD}ENVIRONMENT${NC}
    VDOC_HOME         Installation directory (default: ~/.vdoc)
    BIN_DIR           Binary directory (default: ~/.local/bin)

${BOLD}EXAMPLES${NC}
    # Install latest
    curl -fsSL https://vdoc.dev/install | bash

    # Install specific version
    curl -fsSL https://vdoc.dev/install | bash -s -- --version 2.0.0

    # Uninstall
    curl -fsSL https://vdoc.dev/install | bash -s -- --uninstall

EOF
    exit 0
fi

# =============================================================================
# Uninstall
# =============================================================================

if $UNINSTALL; then
    echo ""
    echo -e "${BOLD}Uninstalling vdoc...${NC}"
    echo ""

    # Remove installation directory
    if [[ -d "$VDOC_HOME" ]]; then
        rm -rf "$VDOC_HOME"
        log_success "Removed $VDOC_HOME"
    else
        log_info "No installation found at $VDOC_HOME"
    fi

    # Remove symlink
    if [[ -L "$BIN_DIR/vdoc" ]]; then
        rm -f "$BIN_DIR/vdoc"
        log_success "Removed $BIN_DIR/vdoc"
    elif [[ -f "$BIN_DIR/vdoc" ]]; then
        rm -f "$BIN_DIR/vdoc"
        log_success "Removed $BIN_DIR/vdoc"
    fi

    echo ""
    log_success "vdoc uninstalled"
    log_info "Project vdocs/ directories were preserved"
    echo ""
    exit 0
fi

# =============================================================================
# Install
# =============================================================================

echo ""
echo -e "${BOLD}vdoc installer${NC}"
echo ""

# Check dependencies
check_dependency() {
    local cmd="$1"
    local msg="$2"
    local required="${3:-false}"

    if ! command -v "$cmd" &>/dev/null; then
        if [[ "$required" == "true" ]]; then
            log_error "$cmd not found - $msg"
            return 1
        else
            log_warning "$cmd not found - $msg"
            return 0
        fi
    fi
    return 0
}

check_dependency curl "required for installation" true || exit 1
check_dependency jq "some features may not work" false
check_dependency git "incremental scanning will be disabled" false

# Resolve version
if [[ "$VDOC_VERSION" == "latest" ]]; then
    log_info "Checking latest version..."

    # Try GitHub API first
    if command -v jq &>/dev/null; then
        VDOC_VERSION=$(curl -fsSL "https://api.github.com/repos/${VDOC_REPO}/releases/latest" 2>/dev/null | jq -r '.tag_name // empty' || echo "")
    fi

    # Fallback to default
    if [[ -z "$VDOC_VERSION" ]] || [[ "$VDOC_VERSION" == "null" ]]; then
        VDOC_VERSION="v2.0.0"
        log_warning "Could not fetch latest version, using $VDOC_VERSION"
    fi
fi

# Remove 'v' prefix if present
VDOC_VERSION="${VDOC_VERSION#v}"

log_success "Installing vdoc v${VDOC_VERSION}"

# Create directories
mkdir -p "$VDOC_HOME"
mkdir -p "$BIN_DIR"

# Download source
DOWNLOAD_URL="https://github.com/${VDOC_REPO}/archive/refs/tags/v${VDOC_VERSION}.tar.gz"
FALLBACK_URL="https://github.com/${VDOC_REPO}/archive/refs/heads/main.tar.gz"

log_info "Downloading..."

TMP_DIR=$(mktemp -d)
trap "rm -rf '$TMP_DIR'" EXIT

download_success=false

# Try tagged release first
if curl -fsSL "$DOWNLOAD_URL" -o "$TMP_DIR/vdoc.tar.gz" 2>/dev/null; then
    download_success=true
# Fallback to main branch
elif curl -fsSL "$FALLBACK_URL" -o "$TMP_DIR/vdoc.tar.gz" 2>/dev/null; then
    log_warning "Tagged release not found, using main branch"
    download_success=true
fi

if ! $download_success; then
    log_error "Failed to download vdoc"
    log_info "Check your internet connection or try again later"
    exit 1
fi

# Extract
log_info "Extracting..."
tar -xzf "$TMP_DIR/vdoc.tar.gz" -C "$TMP_DIR"

# Find extracted directory (handles both vdoc-X.X.X and vdoc-main)
SRC_DIR=$(find "$TMP_DIR" -maxdepth 1 -type d -name "vdoc*" | head -1)

if [[ -z "$SRC_DIR" ]] || [[ ! -d "$SRC_DIR" ]]; then
    log_error "Failed to extract vdoc archive"
    exit 1
fi

# Copy files
log_info "Installing to $VDOC_HOME..."

# Core modules
cp -r "$SRC_DIR/core" "$VDOC_HOME/"
log_success "Installed core modules"

# App (CLI)
cp -r "$SRC_DIR/app" "$VDOC_HOME/"
log_success "Installed CLI"

# Adapters
cp -r "$SRC_DIR/adapters" "$VDOC_HOME/"
log_success "Installed adapters"

# Install script (for platform installation)
cp "$SRC_DIR/install.sh" "$VDOC_HOME/"
chmod +x "$VDOC_HOME/install.sh"

# Make scripts executable
chmod +x "$VDOC_HOME/app/vdoc.sh"
chmod +x "$VDOC_HOME/core/scan.sh"
find "$VDOC_HOME/adapters" -name "*.sh" -exec chmod +x {} \;

# Create wrapper script in VDOC_HOME
cat > "$VDOC_HOME/vdoc" << 'WRAPPER'
#!/usr/bin/env bash
# vdoc CLI wrapper
export VDOC_HOME="${VDOC_HOME:-$HOME/.vdoc}"
exec bash "$VDOC_HOME/app/vdoc.sh" "$@"
WRAPPER
chmod +x "$VDOC_HOME/vdoc"

# Symlink to BIN_DIR
ln -sf "$VDOC_HOME/vdoc" "$BIN_DIR/vdoc"
log_success "Linked to $BIN_DIR/vdoc"

# Store version
echo "$VDOC_VERSION" > "$VDOC_HOME/.version"

# =============================================================================
# Verify Installation
# =============================================================================

echo ""

# Check if BIN_DIR is in PATH
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    log_warning "$BIN_DIR is not in your PATH"
    echo ""
    echo "Add this to your shell profile (~/.bashrc, ~/.zshrc, or ~/.profile):"
    echo ""
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo ""
    echo "Then restart your terminal or run:"
    echo ""
    echo "  source ~/.bashrc  # or ~/.zshrc"
    echo ""
fi

# Test installation
if [[ ":$PATH:" == *":$BIN_DIR:"* ]] && command -v vdoc &>/dev/null; then
    log_success "Installation complete!"
    echo ""
    echo "Get started:"
    echo "  cd your-project"
    echo "  vdoc init --ai claude"
    echo ""
else
    log_success "Installation complete!"
    echo ""
    echo "Get started (after updating PATH):"
    echo "  cd your-project"
    echo "  vdoc init --ai claude"
    echo ""
    echo "Or run directly:"
    echo "  $BIN_DIR/vdoc init --ai claude"
    echo ""
fi

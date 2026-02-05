# STORY-071: Create Global Installer Script

## Metadata
| Field | Value |
|-------|-------|
| **Parent Epic** | [EPIC-007](EPIC.md) |
| **Status** | Complete |
| **Ambiguity Score** | 🟢 Low |
| **Actor** | Developer |
| **Complexity** | Medium (download, extract, PATH setup) |

---

## 1. The Spec (The Contract)

### 1.1 User Story
> As a **Developer**,
> I want to install vdoc with a single curl command,
> So that **I can start using it immediately without cloning repos**.

### 1.2 Detailed Requirements
- [ ] Create `scripts/install-global.sh` installer script
- [ ] Download and extract vdoc to `~/.vdoc/`
- [ ] Symlink `vdoc` to `~/.local/bin/` (or `/usr/local/bin/`)
- [ ] Add to PATH if not already present
- [ ] Support `--version X.X.X` to install specific version
- [ ] Support `--uninstall` to remove vdoc
- [ ] Verify installation with `vdoc --version`
- [ ] Works on macOS and Linux

---

## 2. The Truth (Executable Tests)

### 2.1 Acceptance Criteria (Gherkin)
```gherkin
Feature: Global vdoc Installation

  Scenario: Fresh install
    Given vdoc is not installed
    When curl -fsSL vdoc.dev/install | bash is run
    Then ~/.vdoc/ directory is created
    And vdoc command is available in PATH
    And vdoc --version shows version number

  Scenario: Install specific version
    When curl -fsSL vdoc.dev/install | bash -s -- --version 2.0.0
    Then vdoc v2.0.0 is installed

  Scenario: Upgrade existing
    Given vdoc v2.0.0 is installed
    When curl -fsSL vdoc.dev/install | bash is run
    Then vdoc is upgraded to latest
    And existing project vdocs/ are preserved

  Scenario: Uninstall
    Given vdoc is installed
    When curl -fsSL vdoc.dev/install | bash -s -- --uninstall
    Then ~/.vdoc/ is removed
    And vdoc symlink is removed
    And project vdocs/ are preserved

  Scenario: Missing dependencies
    Given jq is not installed
    When installer is run
    Then warning shows "jq not found, some features may not work"
    And installation continues
```

---

## 3. Technical Context (For Coder Agent)

### 3.1 Affected Files
- `scripts/install-global.sh` (new) - Global installer
- GitHub Release assets (tarball of vdoc)

### 3.2 Implementation
```bash
#!/usr/bin/env bash
# scripts/install-global.sh - vdoc Global Installer
# Usage: curl -fsSL https://vdoc.dev/install | bash

set -euo pipefail

VDOC_VERSION="${VDOC_VERSION:-latest}"
VDOC_REPO="sandrinio/vdoc"
VDOC_HOME="${VDOC_HOME:-$HOME/.vdoc}"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

[[ ! -t 1 ]] && RED='' GREEN='' YELLOW='' BOLD='' NC=''

log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_warning() { echo -e "${YELLOW}!${NC} $1"; }
log_error()   { echo -e "${RED}✗${NC} $1" >&2; }
log_info()    { echo -e "  $1"; }

# Parse arguments
UNINSTALL=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --version) VDOC_VERSION="$2"; shift 2 ;;
        --uninstall) UNINSTALL=true; shift ;;
        --help)
            echo "Usage: curl -fsSL vdoc.dev/install | bash [-s -- OPTIONS]"
            echo "Options:"
            echo "  --version X.X.X   Install specific version"
            echo "  --uninstall       Remove vdoc"
            exit 0
            ;;
        *) shift ;;
    esac
done

# Uninstall
if $UNINSTALL; then
    echo -e "${BOLD}Uninstalling vdoc...${NC}"
    rm -rf "$VDOC_HOME"
    rm -f "$BIN_DIR/vdoc"
    log_success "vdoc uninstalled"
    log_info "Project vdocs/ directories were preserved"
    exit 0
fi

# Header
echo ""
echo -e "${BOLD}vdoc installer${NC}"
echo ""

# Check dependencies
check_dependency() {
    if ! command -v "$1" &>/dev/null; then
        log_warning "$1 not found - $2"
        return 1
    fi
    return 0
}

check_dependency curl "required for installation" || exit 1
check_dependency jq "some features may not work" || true
check_dependency git "incremental scanning disabled" || true

# Resolve version
if [[ "$VDOC_VERSION" == "latest" ]]; then
    log_info "Fetching latest version..."
    VDOC_VERSION=$(curl -fsSL "https://api.github.com/repos/${VDOC_REPO}/releases/latest" | jq -r '.tag_name' 2>/dev/null || echo "v2.0.0")
    VDOC_VERSION="${VDOC_VERSION#v}"
fi
log_success "Installing vdoc v${VDOC_VERSION}"

# Create directories
mkdir -p "$VDOC_HOME"
mkdir -p "$BIN_DIR"

# Download and extract
DOWNLOAD_URL="https://github.com/${VDOC_REPO}/archive/refs/tags/v${VDOC_VERSION}.tar.gz"
log_info "Downloading from GitHub..."

TMP_DIR=$(mktemp -d)
trap "rm -rf $TMP_DIR" EXIT

if curl -fsSL "$DOWNLOAD_URL" -o "$TMP_DIR/vdoc.tar.gz"; then
    tar -xzf "$TMP_DIR/vdoc.tar.gz" -C "$TMP_DIR"

    # Copy files to VDOC_HOME
    SRC_DIR="$TMP_DIR/vdoc-${VDOC_VERSION}"

    cp -r "$SRC_DIR/core" "$VDOC_HOME/"
    cp -r "$SRC_DIR/adapters" "$VDOC_HOME/"
    cp -r "$SRC_DIR/app" "$VDOC_HOME/"
    cp "$SRC_DIR/install.sh" "$VDOC_HOME/"

    # Copy presets
    mkdir -p "$VDOC_HOME/presets"
    cp "$SRC_DIR"/core/presets/*.conf "$VDOC_HOME/presets/"

    log_success "Downloaded vdoc v${VDOC_VERSION}"
else
    log_error "Failed to download vdoc"
    exit 1
fi

# Create vdoc CLI wrapper
cat > "$VDOC_HOME/vdoc" << 'WRAPPER'
#!/usr/bin/env bash
export VDOC_HOME="${VDOC_HOME:-$HOME/.vdoc}"
exec bash "$VDOC_HOME/app/vdoc.sh" "$@"
WRAPPER
chmod +x "$VDOC_HOME/vdoc"

# Symlink to PATH
ln -sf "$VDOC_HOME/vdoc" "$BIN_DIR/vdoc"
log_success "Installed to $BIN_DIR/vdoc"

# Check PATH
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    log_warning "$BIN_DIR is not in PATH"
    echo ""
    echo "Add this to your shell profile (~/.bashrc or ~/.zshrc):"
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo ""
fi

# Verify
if command -v vdoc &>/dev/null; then
    log_success "Installation complete!"
    echo ""
    echo "Get started:"
    echo "  cd your-project"
    echo "  vdoc init --ai claude"
    echo ""
else
    log_warning "vdoc installed but not in PATH yet"
    echo "Run: export PATH=\"\$HOME/.local/bin:\$PATH\""
fi
```

### 3.3 Distribution Options
```bash
# Option 1: GitHub Release tarball (recommended)
curl -fsSL https://github.com/sandrinio/vdoc/releases/latest/download/vdoc.tar.gz

# Option 2: Raw script from repo
curl -fsSL https://raw.githubusercontent.com/sandrinio/vdoc/main/scripts/install-global.sh

# Option 3: Custom domain redirect
curl -fsSL https://vdoc.dev/install  # 301 redirect to GitHub
```

---

## 4. Notes
- Installer must work without any pre-installed vdoc
- Should detect Apple Silicon vs Intel for potential binaries
- Consider checksum verification for security
- Keep installer < 200 lines for auditability


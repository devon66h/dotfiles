#!/usr/bin/env bash
set -euo pipefail

# ── Colors ──────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
RESET='\033[0m'

info()  { printf "${BOLD}${GREEN}[INFO]${RESET}  %s\n" "$*"; }
warn()  { printf "${BOLD}${YELLOW}[WARN]${RESET}  %s\n" "$*"; }
error() { printf "${BOLD}${RED}[ERROR]${RESET} %s\n" "$*" >&2; }
die()   { error "$@"; exit 1; }

# ── Resolve script directory (macOS readlink lacks -f) ──────────────
SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
    DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
    SOURCE="$(readlink "$SOURCE")"
    [[ "$SOURCE" != /* ]] && SOURCE="$DIR/$SOURCE"
done
DOTFILES_DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"

# ── Detect OS ───────────────────────────────────────────────────────
OS="$(uname -s)"
info "Detected OS: $OS"

# ── Package installation ────────────────────────────────────────────
install_macos() {
    info "Running macOS setup"

    if ! command -v brew &>/dev/null; then
        info "Installing Homebrew…"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        info "Homebrew already installed"
    fi

    info "Installing packages from Brewfile…"
    brew bundle --file="$DOTFILES_DIR/Brewfile"
}

install_linux() {
    info "Running Linux setup"

    local pkg_file="$DOTFILES_DIR/packages-linux.txt"
    [ -f "$pkg_file" ] || die "packages-linux.txt not found"

    # Read packages (strip comments and blank lines)
    local packages=()
    while IFS= read -r line; do
        line="${line%%#*}"        # strip comments
        line="${line// /}"        # strip spaces
        [ -z "$line" ] && continue
        packages+=("$line")
    done < "$pkg_file"

    # Detect package manager and map distro-specific names
    if command -v apt &>/dev/null; then
        PKG_MGR="apt"
        PKG_INSTALL=(sudo apt install -y)
        map_package() {
            case "$1" in
                fd)   echo "fd-find" ;;
                node) echo "nodejs" ;;
                *)    echo "$1" ;;
            esac
        }
    elif command -v dnf &>/dev/null; then
        PKG_MGR="dnf"
        PKG_INSTALL=(sudo dnf install -y)
        map_package() {
            case "$1" in
                fd)   echo "fd-find" ;;
                node) echo "nodejs" ;;
                *)    echo "$1" ;;
            esac
        }
    elif command -v pacman &>/dev/null; then
        PKG_MGR="pacman"
        PKG_INSTALL=(sudo pacman -S --noconfirm --needed)
        map_package() {
            case "$1" in
                node) echo "nodejs" ;;
                *)    echo "$1" ;;
            esac
        }
    else
        die "No supported package manager found (apt, dnf, pacman)"
    fi

    info "Package manager: $PKG_MGR"

    # Map and install
    local mapped=()
    for pkg in "${packages[@]}"; do
        mapped+=("$(map_package "$pkg")")
    done

    info "Installing: ${mapped[*]}"
    "${PKG_INSTALL[@]}" "${mapped[@]}"
}

case "$OS" in
    Darwin) install_macos ;;
    Linux)  install_linux ;;
    *)      die "Unsupported OS: $OS" ;;
esac

# ── oh-my-zsh ───────────────────────────────────────────────────────
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    info "Installing oh-my-zsh…"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" \
        --unattended --keep-zshrc
else
    info "oh-my-zsh already installed"
fi

# ── Stow dotfiles ──────────────────────────────────────────────────
info "Stowing dotfiles…"
cd "$DOTFILES_DIR"
stow -v -R -t "$HOME" .

info "Done! Restart your shell."

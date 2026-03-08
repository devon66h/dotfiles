#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
RESET='\033[0m'

pass() { printf "${BOLD}${GREEN}[PASS]${RESET} %s\n" "$*"; }
fail() { printf "${BOLD}${RED}[FAIL]${RESET} %s\n" "$*"; FAILURES=$((FAILURES + 1)); }
info() { printf "${BOLD}${YELLOW}[INFO]${RESET} %s\n" "$*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
FAILURES=0

DISTROS=("ubuntu" "fedora" "arch")

for distro in "${DISTROS[@]}"; do
    tag="dotfiles-test-${distro}"

    printf "\n━━━ Testing on %s ━━━\n" "$distro"

    # Build the image (runs install) 
    if ! docker build -t "$tag" -f "$SCRIPT_DIR/Dockerfile.${distro}" "$DOTFILES_DIR" 2>&1; then
        fail "$distro: docker build failed"
        continue
    fi

    # Verify results inside the container
    result=$(docker run --rm "$tag" bash -c '
        errs=""

        # zsh is installed
        if ! command -v zsh &>/dev/null; then
            errs="${errs}zsh not installed; "
        fi

        # zsh is listed in /etc/shells
        if ! grep -qxF "$(command -v zsh)" /etc/shells 2>/dev/null; then
            errs="${errs}zsh not in /etc/shells; "
        fi

        # default shell is zsh (check /etc/passwd)
        if ! getent passwd "$(whoami)" | grep -q zsh; then
            errs="${errs}zsh is not the default shell; "
        fi

        # oh-my-zsh is installed
        if [ ! -d "$HOME/.oh-my-zsh" ]; then
            errs="${errs}oh-my-zsh not installed; "
        fi

        # stow ran (spot-check: .zshrc should be a symlink)
        if [ ! -L "$HOME/.zshrc" ] && [ ! -f "$HOME/.zshrc" ]; then
            errs="${errs}.zshrc not found; "
        fi

        if [ -z "$errs" ]; then
            echo "ALL_PASSED"
        else
            echo "ERRORS: $errs"
        fi
    ')

    if [[ "$result" == *"ALL_PASSED"* ]]; then
        pass "$distro"
    else
        fail "$distro: $result"
    fi

    # Cleanup image
    docker rmi "$tag" &>/dev/null || true
done

printf "\n"
if [ "$FAILURES" -eq 0 ]; then
    printf "${BOLD}${GREEN}All tests passed!${RESET}\n"
    exit 0
else
    printf "${BOLD}${RED}%d test(s) failed${RESET}\n" "$FAILURES"
    exit 1
fi

# dotfiles

Personal development environment managed with [GNU Stow](https://www.gnu.org/software/stow/). Supports macOS and Linux.

## Bootstrap a New Machine

```sh
git clone https://github.com/devon66h/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

## Adding New Configs

Place the file in this repo mirroring where it lives relative to `$HOME`, then re-stow:

```sh
# Example: adding a new tmux config
# The file goes at ~/dotfiles/.tmux.conf so it symlinks to ~/.tmux.conf
stow -v -R .
```

Files that shouldn't be symlinked (scripts, package lists, docs) are listed in `.stow-local-ignore`.

## Adding New Packages

Add the package to `Brewfile` (macOS) and/or `packages-linux.txt` (Linux), then install:

```sh
# macOS
brew bundle --file=~/dotfiles/Brewfile

# Linux — re-run the install script or install manually
./install.sh
```

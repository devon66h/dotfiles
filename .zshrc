# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="agnoster"

plugins=(git tmux) 

source $ZSH/oh-my-zsh.sh

# Machine-specific config goes in .zshrc.local
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

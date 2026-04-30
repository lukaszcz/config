export GOPATH="$HOME/.local/go"
export PATH="$HOME/.local/bin:$HOME/.local/go/bin:$PATH"

export EDITOR=micro
export VISUAL=micro

export LESS=FR
export MCAT_THEME=makurai_light

alias ls="ls --color -h"
alias pg="less -r"
alias download="curl -fSLO"
alias mcatb="mcat -t makurai_dark"

bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[1;3D' backward-word
bindkey '^[[1;3C' forward-word

source <(fzf --zsh)

autoload -Uz compinit
compinit

export WORDCHARS="*?_.~=&!#$%^"
export PROMPT='%n@%m:%~$ '

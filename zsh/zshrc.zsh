export GOPATH="$HOME/.local/go"
export PATH="$HOME/.local/bin:$HOME/.local/go/bin:$PATH"

export EDITOR=micro
export VISUAL=micro

alias ls="ls --color -h"
alias pg="less -r"
alias download="curl -fSLO"

bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[1;3D' backward-word
bindkey '^[[1;3C' forward-word

source <(fzf --zsh)

autoload -Uz compinit
compinit

export WORDCHARS="*?_.~=&!#$%^"
export PROMPT='%n@%m:%~$ '

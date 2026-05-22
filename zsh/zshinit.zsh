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

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

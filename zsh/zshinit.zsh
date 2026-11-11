export GOPATH="$HOME/.local/go"
export PATH="$HOME/.local/bin:$HOME/.local/go/bin:$PATH"

export EDITOR=micro
export VISUAL=micro

export LESS=FR
export MCAT_THEME=makurai-light

alias ls="ls --color -h"
alias pg="less -r"
alias download="curl -fSLO"
alias mcatb="mcat -t makurai-dark"

bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[1;3D' backward-word
bindkey '^[[1;3C' forward-word

source <(fzf --zsh)

autoload -Uz compinit
compinit

export WORDCHARS="*?_.~=&!#$%^"
export PROMPT='%n@%m:%~$ '

codex() { command codex --no-daemon "$@"; }

pbcopy() {
  {
    printf '\e]52;c;'
    base64 -w0
    printf '\a'
  } > /dev/tty
}

pbpaste() {
  local old ch response='' prev=''
  local -i fd

  exec {fd}<>/dev/tty || return 1
  old=$(stty -g <&$fd) || return 1

  {
    stty -echo -icanon min 1 time 0 <&$fd

    # OSC 52 clipboard query
    printf '\e]52;c;?\a' >&$fd

    # Read until BEL or ST (ESC \)
    while IFS= read -r -k1 -u $fd ch; do
      if [[ $ch == $'\a' ]]; then
        break
      fi

      if [[ $prev == $'\e' && $ch == '\' ]]; then
        response=${response%$'\e'}
        break
      fi

      response+=$ch
      prev=$ch
    done
  } always {
    stty "$old" <&$fd
    exec {fd}>&-
  }

  # Expected response: ESC ] 52 ; <selection> ; <base64>
  response=${response#*$'\e]52;'}
  response=${response#*;}

  print -rn -- "$response" | base64 -d
}

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

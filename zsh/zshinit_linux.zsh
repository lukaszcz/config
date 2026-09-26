
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

source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh-antidote/antidote.zsh
[[ -s ${ZDOTDIR:-$HOME}/.zsh_plugins.txt ]] && antidote load

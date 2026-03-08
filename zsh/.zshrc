
[[ ! -r /Users/lukasz/.opam/opam-init/init.zsh ]] || source /Users/lukasz/.opam/opam-init/init.zsh > /dev/null 2> /dev/null

[ -f "/Users/lukasz/.ghcup/env" ] && source "/Users/lukasz/.ghcup/env"

export GOPATH="$HOME/.local/go"
export PATH="$HOME/dev/vyperlang/HOL/bin:$HOME/.local/bin:$HOME/.local/go/bin:$PATH"

export EDITOR=micro
export VISUAL=micro

alias ls="ls --color -h"
alias pg="less -r"

bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line

source <(fzf --zsh)

autoload -Uz compinit
compinit

source "/opt/homebrew/opt/fzf-tab/share/fzf-tab/fzf-tab.zsh"
source "/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "/opt/homebrew/opt/antidote/share/antidote/antidote.zsh"

y () {
	local tmp="$(mktemp -t yazi-cwd.XXXXXX)"
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(cat -- "$tmp")"  && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]
	then
		cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

export HOLDIR="$HOME/dev/vyperlang/HOL"
export VFMDIR="$HOME/dev/vyperlang/verifereum"
export VYPER_HOL="$HOME/dev/vyperlang/vyper-hol"
export VYPERDIR="$HOME/dev/vyperlang/vyper"

export WORDCHARS="*?_.~=&!#$%^"
export PROMPT='%n@%m:%~$ '

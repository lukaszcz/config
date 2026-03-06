
[[ ! -r /Users/lukasz/.opam/opam-init/init.zsh ]] || source /Users/lukasz/.opam/opam-init/init.zsh > /dev/null 2> /dev/null

[ -f "/Users/lukasz/.ghcup/env" ] && source "/Users/lukasz/.ghcup/env"

export PATH="/Users/lukasz/dev/vyperlang/HOL/bin:/Users/lukasz/.local/bin:$PATH"

export EDITOR=micro
export VISUAL=micro

alias ls="ls --color -h"

source <(fzf --zsh)

autoload -Uz compinit
compinit

source "/opt/homebrew/opt/fzf-tab/share/fzf-tab/fzf-tab.zsh"
source "/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

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

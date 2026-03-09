#!/usr/bin/env bash

set -euo pipefail

cp zsh/zshinit.zsh "$HOME/.zshinit.zsh"
cp zsh/zsh_plugins.txt "$HOME/.zsh_plugins.txt"

case "$(uname -s)" in
Darwin)
  cat zsh/zshinit_macos.zsh >> "$HOME/.zshinit.zsh"
  cat zsh/zsh_plugins_macos.txt >> "$HOME/.zsh_plugins.txt"
  ;;
Linux)
  cat zsh/zshinit_linux.zsh >> "$HOME/.zshinit.zsh"
  cat zsh/zsh_plugins_linux.txt >> "$HOME/.zsh_plugins.txt"
  ;;
*)
  echo "error: unsupported operating system: $(uname -s)" >&2
  exit 1
  ;;
esac

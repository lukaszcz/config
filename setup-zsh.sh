#!/usr/bin/env bash

set -euo pipefail

cp zsh/zshrc.zsh "$HOME/.zshrc.zsh"

case "$(uname -s)" in
Darwin)
  cat zsh/zshrc_macos.zsh >> "$HOME/.zshrc.zsh"
  ;;
Linux)
  cat zsh/zshrc_linux.zsh >> "$HOME/.zshrc.zsh"
  ;;
*)
  echo "error: unsupported operating system: $(uname -s)" >&2
  exit 1
  ;;
esac

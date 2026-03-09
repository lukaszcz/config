#!/usr/bin/env bash

set -euo pipefail

cp zsh/zshinit.zsh "$HOME/.zshinit.zsh"

case "$(uname -s)" in
Darwin)
  cat zsh/zshinit_macos.zsh >> "$HOME/.zshinit.zsh"
  ;;
Linux)
  cat zsh/zshinit_linux.zsh >> "$HOME/.zshinit.zsh"
  ;;
*)
  echo "error: unsupported operating system: $(uname -s)" >&2
  exit 1
  ;;
esac

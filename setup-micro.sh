#!/usr/bin/env bash

set -euo pipefail

mkdir -p "$HOME/.config/micro"
cp -r micro/*.json "$HOME/.config/micro/"
micro -plugin install wc
micro -plugin install autofmt
micro -plugin install detectindent
micro -plugin install go

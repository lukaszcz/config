#!/usr/bin/env bash

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/testlib.sh"

run_test_all_orchestrates_linux_setup_and_keeps_zshrc_idempotent() {
  setup_test_env
  local all_log="${TEST_ROOT}/all.log"
  : > "${all_log}"

  OS="linux"
  PKG_MANAGER="apt"
  make_stub curl 'printf "echo installed-gah\n"'
  make_stub tic 'printf "tic:%s\n" "$*" >> "${STUB_LOG}"'
  cat > "${TEST_BIN}/bash" <<EOF
#!/bin/bash
printf 'bash:%s\n' "\$*" >> "${STUB_LOG}"
EOF
  chmod +x "${TEST_BIN}/bash"

  install_pkg() {
    printf 'install_pkg:%s\n' "$*" >> "${all_log}"
  }

  install_pkg_alt() {
    printf 'install_pkg_alt:%s\n' "$*" >> "${all_log}"
  }

  install_gah() {
    printf 'install_gah:%s\n' "$*" >> "${all_log}"
  }

  install_bin() {
    printf 'install_bin:%s\n' "$*" >> "${all_log}"
  }

  install_git() {
    printf 'install_git:%s\n' "$*" >> "${all_log}"
  }

  config_zsh() {
    printf '%s\n' config_zsh >> "${all_log}"
  }

  config_git() {
    printf '%s\n' config_git >> "${all_log}"
  }

  config_micro() {
    printf '%s\n' config_micro >> "${all_log}"
  }

  config_yazi() {
    printf '%s\n' config_yazi >> "${all_log}"
  }

  all
  all

  assert_file_exists "${HOME}/.local/bin"
  assert_file_content "${HOME}/.zshrc" 'source $HOME/.zshinit.zsh'
  assert_log_contains 'bash:-c echo installed-gah'
  assert_log_contains "tic:${REPO_ROOT}/ghostty/ghostty.terminfo"
  assert_log_contains "tic:${REPO_ROOT}/kitty/kitty.terminfo"

  assert_contains "$(cat "${all_log}")" "install_pkg:unzip"
  assert_contains "$(cat "${all_log}")" "install_bin:bat https://github.com/sharkdp/bat/releases/download/v0.26.1/bat-v0.26.1-x86_64-unknown-linux-gnu.tar.gz"
  assert_contains "$(cat "${all_log}")" "install_gah:lazydocker"
  assert_contains "$(cat "${all_log}")" "install_git:https://github.com/lukaszcz/micro-unicode.git main"
  assert_contains "$(cat "${all_log}")" $'config_git\nconfig_micro\nconfig_yazi'

  teardown_test_env
}

run_test_all_orchestrates_linux_setup_and_keeps_zshrc_idempotent

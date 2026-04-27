#!/usr/bin/env bash

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/testlib.sh"

run_test_detect_system_linux_uses_apt() {
  setup_test_env
  make_stub uname 'echo Linux'
  make_stub apt 'exit 0'

  detect_system

  assert_eq "linux" "${OS}"
  assert_eq "apt" "${PKG_MANAGER}"

  teardown_test_env
}

run_test_detect_system_darwin_uses_brew() {
  setup_test_env
  make_stub uname 'echo Darwin'
  make_stub brew 'exit 0'

  detect_system

  assert_eq "darwin" "${OS}"
  assert_eq "brew" "${PKG_MANAGER}"

  teardown_test_env
}

run_test_detect_system_rejects_unsupported_os() {
  setup_test_env
  make_stub uname 'echo FreeBSD'

  run_capture detect_system

  assert_eq "1" "${RUN_STATUS}"
  assert_contains "${RUN_STDERR}" "error: unsupported operating system: FreeBSD"

  teardown_test_env
}

run_test_init_tmp_dir_respects_explicit_directory() {
  setup_test_env

  TMP_DIR="${TEST_TMP}/shared"
  init_tmp_dir

  assert_file_exists "${TEST_TMP}/shared"
  assert_eq "0" "${TMP_DIR_IS_MANAGED}"

  teardown_test_env
}

run_test_init_tmp_dir_creates_managed_directory() {
  setup_test_env

  init_tmp_dir

  assert_file_exists "${TMP_DIR}"
  assert_eq "1" "${TMP_DIR_IS_MANAGED}"

  teardown_test_env
}

run_test_cleanup_removes_managed_readonly_tree() {
  setup_test_env
  local readonly_dir="${TEST_TMP}/pkg/mod/example.com/tool@v1.0.0"

  mkdir -p "${readonly_dir}"
  printf 'module example.com/tool\n' > "${readonly_dir}/go.mod"

  chmod 0555 "${TEST_TMP}/pkg"
  chmod 0555 "${TEST_TMP}/pkg/mod"
  chmod 0555 "${readonly_dir}"
  chmod 0444 "${readonly_dir}/go.mod"

  TMP_DIR="${TEST_TMP}"
  TMP_DIR_IS_MANAGED=1

  cleanup

  assert_not_exists "${TEST_TMP}"

  teardown_test_env
}

run_test_cleanup_leaves_unmanaged_directory() {
  setup_test_env

  TMP_DIR="${TEST_TMP}"
  TMP_DIR_IS_MANAGED=0

  cleanup

  assert_file_exists "${TEST_TMP}"

  teardown_test_env
}

run_test_if_os_runs_only_matching_commands() {
  setup_test_env
  OS="linux"

  log_marker() {
    printf '%s\n' "$1" >> "${STUB_LOG}"
  }

  if_os linux log_marker matched
  if_os darwin log_marker skipped

  assert_eq "matched" "$(cat "${STUB_LOG}")"

  teardown_test_env
}

run_test_detect_system_linux_uses_apt
run_test_detect_system_darwin_uses_brew
run_test_detect_system_rejects_unsupported_os
run_test_init_tmp_dir_respects_explicit_directory
run_test_init_tmp_dir_creates_managed_directory
run_test_cleanup_removes_managed_readonly_tree
run_test_cleanup_leaves_unmanaged_directory
run_test_if_os_runs_only_matching_commands


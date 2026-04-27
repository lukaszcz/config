#!/usr/bin/env bash

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/testlib.sh"

run_test_parse_args_extracts_options_and_command() {
  setup_test_env

  parse_args --tmp-dir "${TEST_TMP}/shared" config_yazi alpha beta

  assert_eq "config_yazi" "${COMMAND}"
  assert_eq "${TEST_TMP}/shared" "${TMP_DIR}"
  assert_eq "alpha" "${COMMAND_ARGS[0]}"
  assert_eq "beta" "${COMMAND_ARGS[1]}"

  teardown_test_env
}

run_test_main_defaults_to_all() {
  setup_test_env
  local log_file="${TEST_ROOT}/main.log"
  : > "${log_file}"

  detect_system() {
    printf '%s\n' detect_system >> "${log_file}"
    OS="linux"
    PKG_MANAGER="apt"
  }

  init_tmp_dir() {
    printf '%s\n' init_tmp_dir >> "${log_file}"
    TMP_DIR="${TEST_TMP}/managed"
    mkdir -p "${TMP_DIR}"
    TMP_DIR_IS_MANAGED=1
  }

  dispatch_command() {
    printf 'dispatch:%s\n' "$*" >> "${log_file}"
  }

  cleanup() {
    printf '%s\n' cleanup >> "${log_file}"
  }

  main
  trap - EXIT

  assert_eq $'detect_system\ninit_tmp_dir\ndispatch:all' "$(cat "${log_file}")"

  teardown_test_env
}

run_test_main_help_prints_usage_without_initializing_system() {
  setup_test_env
  local log_file="${TEST_ROOT}/main.log"
  : > "${log_file}"

  detect_system() {
    printf '%s\n' detect_system >> "${log_file}"
  }

  init_tmp_dir() {
    printf '%s\n' init_tmp_dir >> "${log_file}"
  }

  run_capture main --help
  trap - EXIT

  assert_eq "0" "${RUN_STATUS}"
  assert_contains "${RUN_STDOUT}" "Usage:"
  assert_eq "" "$(cat "${log_file}")"

  teardown_test_env
}

run_test_main_command_help_uses_command_usage() {
  setup_test_env

  run_capture main config_git --help
  trap - EXIT

  assert_eq "0" "${RUN_STATUS}"
  assert_contains "${RUN_STDOUT}" "Configure global Git settings and aliases."

  teardown_test_env
}

run_test_dispatch_command_runs_internal_functions() {
  setup_test_env

  sample_internal() {
    printf 'internal:%s\n' "$1"
  }

  run_capture dispatch_command sample_internal demo

  assert_eq "0" "${RUN_STATUS}"
  assert_eq "internal:demo" "${RUN_STDOUT}"

  teardown_test_env
}

run_test_dispatch_command_rejects_unknown_commands() {
  setup_test_env

  run_capture dispatch_command does_not_exist

  assert_eq "1" "${RUN_STATUS}"
  assert_contains "${RUN_STDERR}" "error: unknown command: does_not_exist"

  teardown_test_env
}

run_test_parse_args_extracts_options_and_command
run_test_main_defaults_to_all
run_test_main_help_prints_usage_without_initializing_system
run_test_main_command_help_uses_command_usage
run_test_dispatch_command_runs_internal_functions
run_test_dispatch_command_rejects_unknown_commands


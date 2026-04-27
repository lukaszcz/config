#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${REPO_ROOT}/setup.sh"

ORIGINAL_PATH="${PATH}"

fail() {
  local message="${1:-test failed}"
  echo "${message}" >&2
  exit 1
}

setup_test_env() {
  TEST_ROOT="$(mktemp -d)"
  TEST_HOME="${TEST_ROOT}/home"
  TEST_BIN="${TEST_ROOT}/bin"
  TEST_TMP="${TEST_ROOT}/tmp"
  STUB_LOG="${TEST_ROOT}/stub.log"

  mkdir -p "${TEST_HOME}" "${TEST_BIN}" "${TEST_TMP}"
  : > "${STUB_LOG}"

  export HOME="${TEST_HOME}"
  export PATH="${TEST_BIN}:${ORIGINAL_PATH}"
  export STUB_LOG

  source "${REPO_ROOT}/setup.sh"
  reset_setup_state
}

teardown_test_env() {
  if [[ -n "${TEST_ROOT:-}" && -d "${TEST_ROOT}" ]]; then
    rm -rf "${TEST_ROOT}"
  fi
}

reset_setup_state() {
  OS=""
  PKG_MANAGER=""
  TMP_DIR=""
  TMP_DIR_IS_MANAGED=0
  LOCAL_PREFIX="${HOME}/.local"
}

make_stub() {
  local name="${1:?usage: make_stub name body}"
  local body="${2:?usage: make_stub name body}"
  local path="${TEST_BIN}/${name}"

  printf '%s\n' '#!/bin/bash' "${body}" > "${path}"
  chmod +x "${path}"
}

run_capture() {
  local stdout_file="${TEST_ROOT}/stdout"
  local stderr_file="${TEST_ROOT}/stderr"

  if ("$@") >"${stdout_file}" 2>"${stderr_file}"; then
    RUN_STATUS=0
  else
    RUN_STATUS=$?
  fi

  RUN_STDOUT="$(cat "${stdout_file}")"
  RUN_STDERR="$(cat "${stderr_file}")"
}

assert_eq() {
  local expected="${1?usage: assert_eq expected actual [message]}"
  local actual="${2?usage: assert_eq expected actual [message]}"
  local message="${3:-expected ${expected@Q}, got ${actual@Q}}"

  [[ "${actual}" == "${expected}" ]] || fail "${message}"
}

assert_contains() {
  local haystack="${1?usage: assert_contains haystack needle [message]}"
  local needle="${2?usage: assert_contains haystack needle [message]}"
  local message="${3:-expected to find ${needle@Q}}"

  [[ "${haystack}" == *"${needle}"* ]] || fail "${message}"
}

assert_file_exists() {
  local path="${1:?usage: assert_file_exists path}"

  [[ -e "${path}" ]] || fail "expected ${path} to exist"
}

assert_not_exists() {
  local path="${1:?usage: assert_not_exists path}"

  [[ ! -e "${path}" ]] || fail "expected ${path} not to exist"
}

assert_executable() {
  local path="${1:?usage: assert_executable path}"

  [[ -x "${path}" ]] || fail "expected ${path} to be executable"
}

assert_file_content() {
  local path="${1?usage: assert_file_content path expected}"
  local expected="${2?usage: assert_file_content path expected}"
  local actual

  actual="$(cat "${path}")"
  [[ "${actual}" == "${expected}" ]] || fail "expected ${path} to contain ${expected@Q}, got ${actual@Q}"
}

assert_log_contains() {
  local needle="${1:?usage: assert_log_contains needle}"
  local contents

  contents="$(cat "${STUB_LOG}")"
  assert_contains "${contents}" "${needle}" "expected log to contain ${needle@Q}"
}

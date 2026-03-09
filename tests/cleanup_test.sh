#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${REPO_ROOT}/setup.sh"

run_test_cleanup_removes_readonly_tree() {
  local root
  local readonly_dir

  root="$(mktemp -d)"
  readonly_dir="${root}/pkg/mod/example.com/tool@v1.0.0"
  mkdir -p "${readonly_dir}"
  printf 'module example.com/tool\n' > "${readonly_dir}/go.mod"

  chmod 0555 "${root}/pkg"
  chmod 0555 "${root}/pkg/mod"
  chmod 0555 "${readonly_dir}"
  chmod 0444 "${readonly_dir}/go.mod"

  TMP_DIR="${root}"
  TMP_DIR_IS_MANAGED=1

  cleanup

  [[ ! -e "${root}" ]]
}

run_test_cleanup_removes_readonly_tree

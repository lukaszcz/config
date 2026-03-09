#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${REPO_ROOT}/setup.sh"

assert_file_content() {
  local path="${1:?usage: assert_file_content path expected}"
  local expected="${2:?usage: assert_file_content path expected}"
  local actual=""

  actual="$(cat "${path}")"
  if [[ "${actual}" != "${expected}" ]]; then
    echo "expected ${path} to contain ${expected@Q}, got ${actual@Q}" >&2
    return 1
  fi
}

run_test_single_binary_archive() {
  local root
  local archive_root
  local archive_path

  root="$(mktemp -d)"
  archive_root="${root}/archive"
  archive_path="${root}/single-bin.tar.gz"

  mkdir -p "${archive_root}" "${root}/prefix" "${root}/tmp"
  printf 'single-binary\n' > "${archive_root}/demo"
  chmod 0644 "${archive_root}/demo"
  tar -czf "${archive_path}" -C "${archive_root}" demo

  LOCAL_PREFIX="${root}/prefix"
  TMP_DIR="${root}/tmp"

  install_bin demo "file://${archive_path}"

  [[ -x "${LOCAL_PREFIX}/bin/demo" ]]
  assert_file_content "${LOCAL_PREFIX}/bin/demo" 'single-binary'
}

run_test_single_executable_in_directory_archive() {
  local root
  local archive_root
  local archive_path

  root="$(mktemp -d)"
  archive_root="${root}/archive"
  archive_path="${root}/single-exec-tree.tar.gz"

  mkdir -p "${archive_root}/package/docs" "${archive_root}/package/share/man" "${root}/prefix" "${root}/tmp"
  printf '#!/usr/bin/env bash\necho nested\n' > "${archive_root}/package/tool"
  chmod 0755 "${archive_root}/package/tool"
  printf 'docs\n' > "${archive_root}/package/docs/readme.txt"
  printf 'manpage\n' > "${archive_root}/package/share/man/tool.1"
  tar -czf "${archive_path}" -C "${archive_root}" package

  LOCAL_PREFIX="${root}/prefix"
  TMP_DIR="${root}/tmp"

  install_bin tool "file://${archive_path}"

  [[ -x "${LOCAL_PREFIX}/bin/tool" ]]
  assert_file_content "${LOCAL_PREFIX}/bin/tool" $'#!/usr/bin/env bash\necho nested'
}

run_test_single_binary_archive
run_test_single_executable_in_directory_archive

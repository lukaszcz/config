#!/usr/bin/env bash

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/testlib.sh"

run_test_install_pkg_prefers_snap_when_available() {
  setup_test_env
  PKG_MANAGER="apt"
  make_stub sudo 'printf "sudo:%s\n" "$*" >> "${STUB_LOG}"; "$@"'
  make_stub snap 'printf "snap:%s\n" "$*" >> "${STUB_LOG}"'
  make_stub apt 'printf "apt:%s\n" "$*" >> "${STUB_LOG}"'

  install_pkg demo

  assert_eq $'sudo:snap install demo\nsnap:install demo' "$(cat "${STUB_LOG}")"

  teardown_test_env
}

run_test_install_pkg_falls_back_to_apt_after_snap_failures() {
  setup_test_env
  PKG_MANAGER="apt"
  make_stub sudo 'printf "sudo:%s\n" "$*" >> "${STUB_LOG}"; "$@"'
  make_stub snap 'printf "snap:%s\n" "$*" >> "${STUB_LOG}"; exit 1'
  make_stub apt 'printf "apt:%s\n" "$*" >> "${STUB_LOG}"'

  install_pkg demo

  assert_eq $'sudo:snap install demo\nsnap:install demo\nsudo:snap install --classic demo\nsnap:install --classic demo\nsudo:apt install -y demo\napt:install -y demo' "$(cat "${STUB_LOG}")"

  teardown_test_env
}

run_test_install_pkg_uses_brew_on_darwin() {
  setup_test_env
  PKG_MANAGER="brew"
  make_stub brew 'printf "brew:%s\n" "$*" >> "${STUB_LOG}"'

  install_pkg fd

  assert_eq "brew:install fd" "$(cat "${STUB_LOG}")"

  teardown_test_env
}

run_test_install_pkg_alt_selects_os_specific_package() {
  setup_test_env
  PKG_MANAGER="brew"
  make_stub brew 'printf "brew:%s\n" "$*" >> "${STUB_LOG}"'

  install_pkg_alt apt-name brew-name

  assert_eq "brew:install brew-name" "$(cat "${STUB_LOG}")"

  teardown_test_env
}

run_test_select_installed_binary_supports_single_file_and_single_exec() {
  setup_test_env
  local single_root="${TEST_ROOT}/single"
  local exec_root="${TEST_ROOT}/exec"

  mkdir -p "${single_root}" "${exec_root}/docs"
  printf 'plain\n' > "${single_root}/demo"
  printf '#!/usr/bin/env bash\necho exec\n' > "${exec_root}/tool"
  chmod +x "${exec_root}/tool"
  printf 'info\n' > "${exec_root}/docs/readme.txt"

  run_capture select_installed_binary "${single_root}"
  assert_eq "0" "${RUN_STATUS}"
  assert_eq "${single_root}/demo" "${RUN_STDOUT}"

  run_capture select_installed_binary "${exec_root}"
  assert_eq "0" "${RUN_STATUS}"
  assert_eq "${exec_root}/tool" "${RUN_STDOUT}"

  teardown_test_env
}

run_test_select_installed_binary_rejects_ambiguous_layouts() {
  setup_test_env
  local root="${TEST_ROOT}/ambiguous"

  mkdir -p "${root}"
  printf '#!/usr/bin/env bash\n' > "${root}/one"
  printf '#!/usr/bin/env bash\n' > "${root}/two"
  chmod +x "${root}/one" "${root}/two"

  run_capture select_installed_binary "${root}"

  assert_eq "1" "${RUN_STATUS}"
  assert_contains "${RUN_STDERR}" "did not unpack to a single binary"

  teardown_test_env
}

run_test_install_bin_supports_tar_archives_with_a_single_file() {
  setup_test_env
  local archive_root="${TEST_ROOT}/archive"
  local archive_path="${TEST_ROOT}/single-bin.tar.gz"

  mkdir -p "${archive_root}" "${TEST_ROOT}/prefix" "${TEST_ROOT}/tmpdir"
  printf 'single-binary\n' > "${archive_root}/demo"
  chmod 0644 "${archive_root}/demo"
  tar -czf "${archive_path}" -C "${archive_root}" demo

  LOCAL_PREFIX="${TEST_ROOT}/prefix"
  TMP_DIR="${TEST_ROOT}/tmpdir"

  install_bin demo "file://${archive_path}"

  assert_executable "${LOCAL_PREFIX}/bin/demo"
  assert_file_content "${LOCAL_PREFIX}/bin/demo" 'single-binary'

  teardown_test_env
}

run_test_install_bin_supports_nested_archives_with_one_executable() {
  setup_test_env
  local archive_root="${TEST_ROOT}/archive"
  local archive_path="${TEST_ROOT}/single-exec-tree.tar.gz"

  mkdir -p "${archive_root}/package/docs" "${archive_root}/package/share/man" "${TEST_ROOT}/prefix" "${TEST_ROOT}/tmpdir"
  printf '#!/usr/bin/env bash\necho nested\n' > "${archive_root}/package/tool"
  chmod 0755 "${archive_root}/package/tool"
  printf 'docs\n' > "${archive_root}/package/docs/readme.txt"
  printf 'manpage\n' > "${archive_root}/package/share/man/tool.1"
  tar -czf "${archive_path}" -C "${archive_root}" package

  LOCAL_PREFIX="${TEST_ROOT}/prefix"
  TMP_DIR="${TEST_ROOT}/tmpdir"

  install_bin tool "file://${archive_path}"

  assert_executable "${LOCAL_PREFIX}/bin/tool"
  assert_file_content "${LOCAL_PREFIX}/bin/tool" $'#!/usr/bin/env bash\necho nested'

  teardown_test_env
}

run_test_install_bin_supports_gzip_single_binaries() {
  setup_test_env
  local source_path="${TEST_ROOT}/demo"
  local archive_path="${TEST_ROOT}/demo.gz"

  mkdir -p "${TEST_ROOT}/prefix" "${TEST_ROOT}/tmpdir"
  printf '#!/usr/bin/env bash\necho gzip\n' > "${source_path}"
  gzip -c "${source_path}" > "${archive_path}"

  LOCAL_PREFIX="${TEST_ROOT}/prefix"
  TMP_DIR="${TEST_ROOT}/tmpdir"

  install_bin demo "file://${archive_path}"

  assert_executable "${LOCAL_PREFIX}/bin/demo"
  assert_file_content "${LOCAL_PREFIX}/bin/demo" $'#!/usr/bin/env bash\necho gzip'

  teardown_test_env
}

run_test_install_bin_rejects_ambiguous_archives() {
  setup_test_env
  local archive_root="${TEST_ROOT}/archive"
  local archive_path="${TEST_ROOT}/ambiguous.tar.gz"

  mkdir -p "${archive_root}" "${TEST_ROOT}/prefix" "${TEST_ROOT}/tmpdir"
  printf '#!/usr/bin/env bash\n' > "${archive_root}/one"
  printf '#!/usr/bin/env bash\n' > "${archive_root}/two"
  chmod +x "${archive_root}/one" "${archive_root}/two"
  tar -czf "${archive_path}" -C "${archive_root}" .

  LOCAL_PREFIX="${TEST_ROOT}/prefix"
  TMP_DIR="${TEST_ROOT}/tmpdir"

  run_capture install_bin demo "file://${archive_path}"

  assert_eq "1" "${RUN_STATUS}"
  assert_contains "${RUN_STDERR}" "did not unpack to a supported single-binary layout"

  teardown_test_env
}

run_test_install_pkg_prefers_snap_when_available
run_test_install_pkg_falls_back_to_apt_after_snap_failures
run_test_install_pkg_uses_brew_on_darwin
run_test_install_pkg_alt_selects_os_specific_package
run_test_select_installed_binary_supports_single_file_and_single_exec
run_test_select_installed_binary_rejects_ambiguous_layouts
run_test_install_bin_supports_tar_archives_with_a_single_file
run_test_install_bin_supports_nested_archives_with_one_executable
run_test_install_bin_supports_gzip_single_binaries
run_test_install_bin_rejects_ambiguous_archives

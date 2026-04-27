#!/usr/bin/env bash

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/testlib.sh"

run_test_install_src_tree_prefers_just_install_target() {
  setup_test_env
  local src_dir="${TEST_ROOT}/src"

  mkdir -p "${src_dir}" "${HOME}/.local"
  printf 'install:\n' > "${src_dir}/justfile"
  make_stub just '
if [[ "$1" == "--justfile" && "$3" == "--list" ]]; then
  printf "install\n"
elif [[ "$1" == "--justfile" && "$3" == "install" ]]; then
  printf "just:%s\n" "$*" >> "${STUB_LOG}"
else
  exit 1
fi
'

  install_src_tree "${src_dir}" demo-source

  assert_eq "just:--justfile ${src_dir}/justfile install" "$(cat "${STUB_LOG}")"

  teardown_test_env
}

run_test_install_src_tree_falls_back_to_configure_and_make() {
  setup_test_env
  local src_dir="${TEST_ROOT}/src"

  mkdir -p "${src_dir}" "${HOME}/.local"
  cat > "${src_dir}/configure" <<EOF
#!/usr/bin/env bash
printf 'configure:%s\n' "\$*" >> "${STUB_LOG}"
EOF
  chmod +x "${src_dir}/configure"
  : > "${src_dir}/Makefile"
  make_stub make 'printf "make:%s\n" "$*" >> "${STUB_LOG}"'

  install_src_tree "${src_dir}" demo-source

  assert_eq $'configure:--prefix='"${HOME}"$'/.local\nmake:\nmake:install' "$(cat "${STUB_LOG}")"

  teardown_test_env
}

run_test_install_src_tree_supports_go_modules() {
  setup_test_env
  local src_dir="${TEST_ROOT}/src"

  mkdir -p "${src_dir}"
  printf 'module example.com/tool\n' > "${src_dir}/go.mod"
  make_stub go 'printf "go:%s|GOBIN=%s|GOPATH=%s|GOCACHE=%s\n" "$*" "${GOBIN}" "${GOPATH}" "${GOCACHE}" >> "${STUB_LOG}"'

  TMP_DIR="${TEST_TMP}"
  install_src_tree "${src_dir}" demo-source

  assert_log_contains "go:install .|GOBIN=${HOME}/.local/bin|GOPATH=${TEST_TMP}/go-"
  assert_log_contains "|GOCACHE=${TEST_TMP}/go-"

  teardown_test_env
}

run_test_install_src_tree_supports_cargo_projects() {
  setup_test_env
  local src_dir="${TEST_ROOT}/src"

  mkdir -p "${src_dir}"
  printf '[package]\nname = "demo"\nversion = "0.1.0"\n' > "${src_dir}/Cargo.toml"
  make_stub cargo 'printf "cargo:%s\n" "$*" >> "${STUB_LOG}"'

  install_src_tree "${src_dir}" demo-source

  assert_eq "cargo:install --path . --root ${HOME}/.local" "$(cat "${STUB_LOG}")"

  teardown_test_env
}

run_test_install_src_tree_rejects_unknown_source_layouts() {
  setup_test_env
  local src_dir="${TEST_ROOT}/src"

  mkdir -p "${src_dir}"

  run_capture install_src_tree "${src_dir}" demo-source

  assert_eq "1" "${RUN_STATUS}"
  assert_contains "${RUN_STDERR}" "did not unpack to a supported source tree"

  teardown_test_env
}

run_test_install_src_extracts_flat_archives() {
  setup_test_env
  local package_root="${TEST_ROOT}/package"
  local archive_path="${TEST_ROOT}/demo.tar.gz"

  mkdir -p "${package_root}"
  printf '[package]\nname = "demo"\nversion = "0.1.0"\n' > "${package_root}/Cargo.toml"
  tar -czf "${archive_path}" -C "${package_root}" Cargo.toml
  make_stub cargo 'printf "cargo:%s\n" "$*" >> "${STUB_LOG}"'

  TMP_DIR="${TEST_TMP}"
  install_src "file://${archive_path}"

  assert_eq "cargo:install --path . --root ${HOME}/.local" "$(cat "${STUB_LOG}")"

  teardown_test_env
}

run_test_config_zsh_combines_base_and_linux_overrides() {
  setup_test_env
  OS="linux-amd64"

  config_zsh

  assert_file_content "${HOME}/.zshinit.zsh" "$(cat "${REPO_ROOT}/zsh/zshinit.zsh"; cat "${REPO_ROOT}/zsh/zshinit_linux.zsh")"
  assert_file_content "${HOME}/.zsh_plugins.txt" "$(cat "${REPO_ROOT}/zsh/zsh_plugins.txt"; cat "${REPO_ROOT}/zsh/zsh_plugins_linux.txt")"

  teardown_test_env
}

run_test_config_git_sets_expected_global_values() {
  setup_test_env
  make_stub git 'printf "git:%s\n" "$*" >> "${STUB_LOG}"'

  config_git

  assert_log_contains "git:config --global user.name Łukasz Czajka"
  assert_log_contains "git:config --global user.email lukaszcz@mimuw.edu.pl"
  assert_log_contains "git:config --global alias.dn !git diff \"\$@\" | diffnav -u"

  teardown_test_env
}

run_test_config_micro_copies_files_and_installs_plugins() {
  setup_test_env
  make_stub micro 'printf "micro:%s\n" "$*" >> "${STUB_LOG}"'

  config_micro

  assert_file_exists "${HOME}/.config/micro/settings.json"
  assert_file_exists "${HOME}/.config/micro/bindings.json"
  assert_eq $'micro:-plugin install wc\nmicro:-plugin install autofmt\nmicro:-plugin install detectindent\nmicro:-plugin install go' "$(cat "${STUB_LOG}")"

  teardown_test_env
}

run_test_config_yazi_copies_the_full_tree() {
  setup_test_env

  config_yazi

  assert_file_exists "${HOME}/.config/yazi/yazi.toml"
  assert_file_exists "${HOME}/.config/yazi/package.toml"
  assert_file_exists "${HOME}/.config/yazi/plugins/enter-cd-quit.yazi/main.lua"

  teardown_test_env
}

run_test_install_src_tree_prefers_just_install_target
run_test_install_src_tree_falls_back_to_configure_and_make
run_test_install_src_tree_supports_go_modules
run_test_install_src_tree_supports_cargo_projects
run_test_install_src_tree_rejects_unknown_source_layouts
run_test_install_src_extracts_flat_archives
run_test_config_zsh_combines_base_and_linux_overrides
run_test_config_git_sets_expected_global_values
run_test_config_micro_copies_files_and_installs_plugins
run_test_config_yazi_copies_the_full_tree

#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_PREFIX="${HOME}/.local"
OS=""
PKG_MANAGER=""
TMP_DIR=""
TMP_DIR_IS_MANAGED=0

usage() {
  cat <<EOF
Usage: $0 [--tmp-dir PATH] <command> [args...]
       $0 [--tmp-dir PATH]

Commands:
  all                    Run the full setup.
  config_zsh             Install Zsh configuration files.
  config_git             Configure Git settings.
  config_micro           Install Micro config and plugins.
  config_yazi            Install Yazi config.
  help                   Show this help text.

You can also invoke internal function names directly, for example:
  $0 install_gah repo_name

Options:
  -t, --tmp-dir PATH  Use PATH as the shared temp directory.
  -h, --help          Show this help text.
EOF
}

command_usage() {
  local command="${1:?usage: command_usage command}"

  case "${command}" in
    all)
      cat <<EOF
Usage: $0 [--tmp-dir PATH] all

Run the full setup workflow.
EOF
      ;;
    config_zsh)
      cat <<EOF
Usage: $0 [--tmp-dir PATH] config_zsh

Install Zsh configuration files.
EOF
      ;;
    config_git)
      cat <<EOF
Usage: $0 [--tmp-dir PATH] config_git

Configure global Git settings and aliases.
EOF
      ;;
    config_micro)
      cat <<EOF
Usage: $0 [--tmp-dir PATH] config_micro

Install Micro configuration files and plugins.
EOF
      ;;
    config_yazi)
      cat <<EOF
Usage: $0 [--tmp-dir PATH] config_yazi

Install Yazi configuration files.
EOF
      ;;
    install_gah)
      cat <<EOF
Usage: $0 [--tmp-dir PATH] install_gah repo_name

Install a package using gah.
EOF
      ;;
    install_pkg)
      cat <<EOF
Usage: $0 [--tmp-dir PATH] install_pkg package

Install a package with the detected system package manager.
EOF
      ;;
    install_pkg_alt)
      cat <<EOF
Usage: $0 [--tmp-dir PATH] install_pkg_alt apt_package brew_package

Install OS-specific package names via the detected package manager.
EOF
      ;;
    install_src)
      cat <<EOF
Usage: $0 [--tmp-dir PATH] install_src url

Download, unpack, and install a source archive.
EOF
      ;;
    install_bin)
      cat <<EOF
Usage: $0 [--tmp-dir PATH] install_bin binary_name url

Download and install a single-binary release archive.
EOF
      ;;
    install_git)
      cat <<EOF
Usage: $0 [--tmp-dir PATH] install_git url ref

Clone a Git repository at a specific ref and install it from source.
EOF
      ;;
    if_os)
      cat <<EOF
Usage: $0 [--tmp-dir PATH] if_os os command [args...]

Run a command only when the detected OS matches.
EOF
      ;;
    help)
      usage
      ;;
    *)
      echo "error: unknown command: ${command}" >&2
      usage >&2
      exit 1
      ;;
  esac
}

parse_args() {
  COMMAND=""
  COMMAND_ARGS=()
  SHOW_HELP=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -t|--tmp-dir)
        [[ $# -ge 2 ]] || {
          echo "error: missing value for $1" >&2
          exit 1
        }
        TMP_DIR="$2"
        shift 2
        ;;
      --tmp-dir=*)
        TMP_DIR="${1#*=}"
        shift
        ;;
      -h|--help)
        SHOW_HELP=1
        shift
        ;;
      *)
        COMMAND="$1"
        shift
        COMMAND_ARGS=("$@")
        return
        ;;
    esac
  done
}

detect_system() {
  case "$(uname -s)" in
    Darwin)
      OS="darwin"
      PKG_MANAGER="brew"
      command -v brew >/dev/null 2>&1 || {
        echo "error: Homebrew is required on macOS" >&2
        exit 1
      }
      ;;
    Linux)
      OS="linux"
      PKG_MANAGER="apt"
      command -v apt >/dev/null 2>&1 || {
        echo "error: apt is required on Linux" >&2
        exit 1
      }
      ;;
    *)
      echo "error: unsupported operating system: $(uname -s)" >&2
      exit 1
      ;;
  esac
}

init_tmp_dir() {
  if [[ -n "${TMP_DIR}" ]]; then
    mkdir -p "${TMP_DIR}"
    return
  fi

  TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/setup.sh.XXXXXX")"
  TMP_DIR_IS_MANAGED=1
}

cleanup() {
  local status=$?

  if [[ "${TMP_DIR_IS_MANAGED}" -eq 1 && -n "${TMP_DIR}" ]]; then
    # Go's module cache can mark temp files and directories read-only.
    # Restore user-writable permissions before removing a managed temp tree.
    find "${TMP_DIR}" -type d -exec chmod u+rwx {} + 2>/dev/null || true
    find "${TMP_DIR}" -type f -exec chmod u+rw {} + 2>/dev/null || true
    rm -rf "${TMP_DIR}" 2>/dev/null || true
  fi

  return "${status}"
}

install_pkg() {
  local package="${1:?usage: install_pkg package}"

  case "${PKG_MANAGER}" in
    apt)
      if command -v snap >/dev/null 2>&1; then
        sudo snap install "${package}" || sudo snap install --classic "${package}" || sudo apt install -y "${package}"
      else
        sudo apt install -y "${package}"
      fi
      ;;
    brew)
      brew install "${package}"
      ;;
    *)
      echo "error: unsupported package manager: ${PKG_MANAGER}" >&2
      exit 1
      ;;
  esac
}

install_pkg_alt() {
  local apt_package="${1:?usage: install_pkg_alt apt_package brew_package}"
  local brew_package="${2:?usage: install_pkg_alt apt_package brew_package}"

  case "${PKG_MANAGER}" in
    apt)
      install_pkg "${apt_package}"
      ;;
    brew)
      install_pkg "${brew_package}"
      ;;
    *)
      echo "error: unsupported package manager: ${PKG_MANAGER}" >&2
      exit 1
      ;;
  esac
}

install_src_tree() {
  local src_dir="${1:?usage: install_src_tree src_dir source}"
  local source="${2:?usage: install_src_tree src_dir source}"
  local justfile=""

  if [[ -f "${src_dir}/justfile" ]]; then
    justfile="${src_dir}/justfile"
  elif [[ -f "${src_dir}/Justfile" ]]; then
    justfile="${src_dir}/Justfile"
  fi

  (
    cd "${src_dir}"

    if [[ -n "${justfile}" ]] && just --justfile "${justfile}" --list | sed 's/^[[:space:]]*//' | grep -Eq '^install($|[[:space:]])'; then
      just --justfile "${justfile}" install
    elif [[ -x "./configure" && -f "./Makefile" ]]; then
      ./configure --prefix="${LOCAL_PREFIX}"
      make
      make install
    elif [[ -f "./go.mod" ]]; then
      local go_path="${TMP_DIR}/go-${RANDOM}-${RANDOM}/path"
      local go_cache="${TMP_DIR}/go-${RANDOM}-${RANDOM}/cache"
      mkdir -p "${LOCAL_PREFIX}/bin"
      mkdir -p "${go_path}" "${go_cache}"
      GOPATH="${go_path}" GOCACHE="${go_cache}" GOBIN="${LOCAL_PREFIX}/bin" go install .
    elif [[ -f "./Cargo.toml" ]]; then
      cargo install --path . --root "${LOCAL_PREFIX}"
    else
      echo "error: ${source} did not unpack to a supported source tree" >&2
      exit 1
    fi
  )
}

install_src() {
  local url="${1:?usage: install_src url}"
  local archive_name="${url##*/}"
  local build_root="${TMP_DIR}/src-${RANDOM}-${RANDOM}"
  local archive_path="${build_root}/${archive_name}"
  local src_dir=""

  mkdir -p "${build_root}" "${LOCAL_PREFIX}"

  curl -fsSL "${url}" -o "${archive_path}"
  tar -xf "${archive_path}" -C "${build_root}"

  src_dir="$(find "${build_root}" -mindepth 1 -maxdepth 1 -type d | head -n 1)"
  if [[ -z "${src_dir}" ]]; then
    src_dir="${build_root}"
  fi

  install_src_tree "${src_dir}" "${url}"
}

select_installed_binary() {
  local unpack_root="${1:?usage: select_installed_binary unpack_root}"
  local -a extracted_files=()
  local -a executable_files=()
  local file=""

  while IFS= read -r file; do
    extracted_files+=("${file}")
  done < <(find "${unpack_root}" -type f)

  if [[ "${#extracted_files[@]}" -eq 1 ]]; then
    printf '%s\n' "${extracted_files[0]}"
    return 0
  fi

  for file in "${extracted_files[@]}"; do
    if [[ -x "${file}" ]]; then
      executable_files+=("${file}")
    fi
  done

  if [[ "${#executable_files[@]}" -eq 1 ]]; then
    printf '%s\n' "${executable_files[0]}"
    return 0
  fi

  echo "error: ${unpack_root} did not unpack to a single binary" >&2
  return 1
}

install_bin() {
  local binary_name="${1:?usage: install_bin binary_name url}"
  local url="${2:?usage: install_bin binary_name url}"
  local build_root="${TMP_DIR}/bin-${RANDOM}-${RANDOM}"
  local unpack_root="${build_root}/unpack"
  local archive_path=""
  local extracted_path=""

  mkdir -p "${build_root}" "${unpack_root}" "${LOCAL_PREFIX}/bin"

  (
    cd "${build_root}"
    curl -fsSLO "${url}"
  )

  archive_path="$(find "${build_root}" -mindepth 1 -maxdepth 1 -type f | head -n 1)"
  if [[ -z "${archive_path}" ]]; then
    echo "error: ${url} did not download an archive" >&2
    exit 1
  fi

  case "${archive_path}" in
    *.tar|*.tar.gz|*.tgz|*.tar.bz2|*.tbz2|*.tar.xz|*.txz|*.tar.zst|*.tzst)
      tar -xf "${archive_path}" -C "${unpack_root}"
      ;;
    *.zip)
      unzip -q "${archive_path}" -d "${unpack_root}"
      ;;
    *.gz)
      gzip -dc "${archive_path}" > "${unpack_root}/${binary_name}"
      ;;
    *.bz2)
      bzip2 -dc "${archive_path}" > "${unpack_root}/${binary_name}"
      ;;
    *.xz)
      xz -dc "${archive_path}" > "${unpack_root}/${binary_name}"
      ;;
    *)
      echo "error: unsupported binary archive format: ${archive_path}" >&2
      exit 1
      ;;
  esac

  extracted_path="$(select_installed_binary "${unpack_root}")" || {
    echo "error: ${url} did not unpack to a supported single-binary layout" >&2
    exit 1
  }

  install -m 0755 "${extracted_path}" "${LOCAL_PREFIX}/bin/${binary_name}"
}

install_gah() {
  local repo="${1:?usage: install_gah repo_name}"
  gah install "${repo}" --unattended
}

install_git() {
  local url="${1:?usage: install_git url ref}"
  local ref="${2:?usage: install_git url ref}"
  local build_root="${TMP_DIR}/git-${RANDOM}-${RANDOM}"
  local repo_dir="${build_root}/repo"

  mkdir -p "${build_root}" "${LOCAL_PREFIX}"

  git clone "${url}" "${repo_dir}"
  (
    cd "${repo_dir}"
    git checkout "${ref}"
  )

  install_src_tree "${repo_dir}" "${url}@${ref}"
}

if_os() {
  local expected_os="${1:?usage: if_os os command [args...]}"
  local cmd="${2:?usage: if_os os command [args...]}"
  shift 2

  [[ "${OS}" == "${expected_os}" ]] || return 0
  "${cmd}" "$@"
}

config_zsh() {
  cp "${SCRIPT_DIR}/zsh/zshinit.zsh" "$HOME/.zshinit.zsh"
  cp "${SCRIPT_DIR}/zsh/zsh_plugins.txt" "$HOME/.zsh_plugins.txt"

  case "${OS}" in
    darwin)
      cat "${SCRIPT_DIR}/zsh/zshinit_macos.zsh" >> "$HOME/.zshinit.zsh"
      cat "${SCRIPT_DIR}/zsh/zsh_plugins_macos.txt" >> "$HOME/.zsh_plugins.txt"
      ;;
    linux)
      cat "${SCRIPT_DIR}/zsh/zshinit_linux.zsh" >> "$HOME/.zshinit.zsh"
      cat "${SCRIPT_DIR}/zsh/zsh_plugins_linux.txt" >> "$HOME/.zsh_plugins.txt"
      ;;
    *)
      echo "error: unsupported operating system: ${OS}" >&2
      exit 1
      ;;
  esac
}

config_git() {
  git config --global user.name "Łukasz Czajka"
  git config --global user.email "lukaszcz@mimuw.edu.pl"
  git config --global pull.rebase true
  git config --global init.defaultBranch main
  git config --global core.pager delta

  git config --global alias.st "status -sb"
  git config --global alias.co checkout
  git config --global alias.br branch
  git config --global alias.ci commit
  git config --global alias.wt worktree
  git config --global alias.lg "log --oneline -10"
  git config --global alias.lgs "log --oneline"
  git config --global alias.dt '!git -c diff.external=difft diff'
  git config --global alias.difft '!git -c diff.external=difft diff'
  git config --global alias.diffnav '!f() { git diff "$@" | diffnav -u; }; f'
  git config --global alias.dn '!git diff "$@" | diffnav -u'
}

config_micro() {
  mkdir -p "$HOME/.config/micro"
  cp -r "${SCRIPT_DIR}/micro/"*.json "$HOME/.config/micro/"
  micro -plugin install wc
  micro -plugin install autofmt
  micro -plugin install detectindent
  micro -plugin install go
}

config_yazi() {
  mkdir -p "$HOME/.config/yazi/"
  cp -r "${SCRIPT_DIR}/yazi/"* "$HOME/.config/yazi/"
}

all() {
  mkdir -p "$HOME/.local/bin"
  export PATH="$HOME/.local/bin:$PATH"

  install_pkg unzip

  # install gah
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/get-gah/gah/refs/heads/master/tools/install.sh)"

  # install uv
  curl -LsSf https://astral.sh/uv/install.sh | sh

  if_os linux install_pkg zsh
  install_pkg zsh-autosuggestions
  install_pkg_alt zsh-antidote antidote
  config_zsh
  if [[ ! -f "$HOME/.zshrc" ]] || ! grep -qxF 'source $HOME/.zshinit.zsh' "$HOME/.zshrc"; then
    echo 'source $HOME/.zshinit.zsh' >> "$HOME/.zshrc"
  fi

  install_pkg gcc
  install_pkg go
  install_pkg rustup

  rustup default stable

  install_gah casey/just
  install_gah burntsushi/ripgrep

  if_os darwin install_pkg bat
  if_os linux install_bin bat "https://github.com/sharkdp/bat/releases/download/v0.26.1/bat-v0.26.1-x86_64-unknown-linux-gnu.tar.gz"
  if_os darwin install_pkg fzf
  if_os linux install_bin fzf "https://github.com/junegunn/fzf/releases/download/v0.70.0/fzf-0.70.0-linux_amd64.tar.gz"
  if_os darwin install_pkg micro
  if_os linux install_bin micro "https://github.com/micro-editor/micro/releases/download/v2.0.15/micro-2.0.15-linux64-static.tar.gz"
  install_pkg yazi
  install_pkg_alt git-delta delta
  install_pkg par
  install_pkg bfs
  install_gah lazygit
  if_os linux install_gah lazydocker

  install_pkg bash-completion
  if_os darwin install_pkg fzf-tab

  install_git https://github.com/lukaszcz/mcat.git develop
  install_git https://github.com/lukaszcz/diffnav.git develop

  install_git https://github.com/lukaszcz/devtools.git main
  install_git https://github.com/lukaszcz/agm.git main

  config_git
  config_micro
  config_yazi

  install_git https://github.com/lukaszcz/micro-syntax-sml-hol4.git main
  install_git https://github.com/lukaszcz/micro-unicode.git main

  tic "${SCRIPT_DIR}/ghostty/ghostty.terminfo"
  tic "${SCRIPT_DIR}/kitty/kitty.terminfo"
}

dispatch_command() {
  local command="${1:-help}"
  shift || true

  case "${command}" in
    help)
      usage
      ;;
    all)
      all "$@"
      ;;
    config_zsh)
      config_zsh "$@"
      ;;
    config_git)
      config_git "$@"
      ;;
    config_micro)
      config_micro "$@"
      ;;
    config_yazi)
      config_yazi "$@"
      ;;
    *)
      if declare -F "${command}" >/dev/null 2>&1; then
        "${command}" "$@"
      else
        echo "error: unknown command: ${command}" >&2
        usage >&2
        exit 1
      fi
      ;;
  esac
}

main() {
  parse_args "$@"

  if [[ -z "${COMMAND}" ]]; then
    if [[ "${SHOW_HELP}" -eq 1 ]]; then
      usage
      exit 0
    fi

    COMMAND="all"
  fi

  if [[ "${SHOW_HELP}" -eq 1 ]]; then
    command_usage "${COMMAND}"
    exit 0
  fi

  if [[ "${#COMMAND_ARGS[@]}" -gt 0 ]]; then
    case "${COMMAND_ARGS[-1]}" in
      -h|--help)
        command_usage "${COMMAND}"
        exit 0
        ;;
    esac
  fi

  detect_system
  init_tmp_dir
  trap cleanup EXIT
  dispatch_command "${COMMAND}" "${COMMAND_ARGS[@]}"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi

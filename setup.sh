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
Usage: $0 [--tmp-dir PATH]

Options:
  -t, --tmp-dir PATH  Use PATH as the shared temp directory.
  -h, --help          Show this help text.
EOF
}

parse_args() {
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
        usage
        exit 0
        ;;
      *)
        echo "error: unknown argument: $1" >&2
        usage >&2
        exit 1
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
  if [[ "${TMP_DIR_IS_MANAGED}" -eq 1 && -n "${TMP_DIR}" ]]; then
    rm -rf "${TMP_DIR}"
  fi
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

main() {
  parse_args "$@"
  detect_system
  init_tmp_dir
  trap cleanup EXIT

  mkdir -p "$HOME/.local/bin"

  if_os linux install_pkg zsh
  install_pkg zsh-autosuggestions
  install_pkg_alt zsh-antidote antidote
  bash ./setup-zsh.sh
  echo 'source $HOME/.zshinit.zsh' >> "$HOME/.zshrc"

  install_pkg gcc
  install_pkg go
  install_pkg rustup

  if_os darwin install_pkg bat
  if_os linux install_bin bat "https://github.com/sharkdp/bat/releases/download/v0.26.1/bat-v0.26.1-x86_64-unknown-linux-gnu.tar.gz"
  if_os darwin install_pkg fzf
  if_os linux install_bin fzf "https://github.com/junegunn/fzf/releases/download/v0.70.0/fzf-0.70.0-linux_amd64.tar.gz"
  install_pkg micro
  install_pkg yazi
  install_pkg_alt git-delta delta
  install_pkg par
  install_pkg bfs

  install_pkg bash-completion
  if_os darwin install_pkg fzf-tab

  install_git https://github.com/lukaszcz/mcat.git develop
  install_git https://github.com/lukaszcz/diffnav.git develop

  bash ./setup-git.sh
  bash ./setup-micro.sh
  bash ./setup-yazi.sh

  install_git https://github.com/lukaszcz/micro-syntax-sml-hol4.git main
  install_git https://github.com/lukaszcz/micro-unicode.git main

  tic "${SCRIPT_DIR}/ghostty.terminfo"
  tic "${SCRIPT_DIR}/kitty.terminfo"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi

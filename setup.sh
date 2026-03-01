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

  [[ -x "${src_dir}/configure" ]] || {
    echo "error: ${url} did not unpack to a configure-based source tree" >&2
    exit 1
  }

  (
    cd "${src_dir}"
    ./configure --prefix="${LOCAL_PREFIX}"
    make
    make install
  )
}

main() {
  parse_args "$@"
  detect_system
  init_tmp_dir
  trap cleanup EXIT

  mkdir -p "$HOME/.local/bin"

  install_pkg gcc
  install_pkg go

  install_pkg bat
  install_pkg fzf
  install_pkg micro
  install_pkg yazi
  install_pkg_alt delta git-delta
  install_pkg par

  bash ./setup-micro.sh
  bash ./setup-yazi.sh

  if [[ -x /usr/bin/batcat ]] && ! command -v bat >/dev/null 2>&1; then
    ln -s /usr/bin/batcat "$HOME/.local/bin/bat"
  fi

  tic "${SCRIPT_DIR}/ghostty.terminfo"
  tic "${SCRIPT_DIR}/kitty.terminfo"
}

main "$@"

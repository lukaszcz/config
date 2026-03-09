# config

Bootstrap scripts for setting up a preferred developer environment on a new macOS or Linux machine.

The main entrypoint is [`setup.sh`](setup.sh). It installs a set of command-line tools, copies shell/editor/file-manager config into the current user's home directory, and builds a few custom tools from source.

## Supported platforms

- macOS with Homebrew installed
- Linux systems with `apt` available (Ubuntu/Debian-style)

## What it sets up

`setup.sh` currently:

- detects the platform and package manager (`brew` on macOS, `apt` on Linux)
- installs shell tooling: `zsh`, `zsh-autosuggestions`, `antidote`
- installs development toolchains: `gcc`, `go`, `rustup`
- installs CLI tools: `bat`, `fzf`, `micro`, `yazi`, `delta`, `par`, `bfs`, `bash-completion`
- installs `fzf-tab` on macOS
- clones and installs custom tools from source:
  - `mcat`
  - `diffnav`
  - `micro-syntax-sml-hol4`
  - `micro-unicode`
- copies config for:
  - `zsh`
  - `git`
  - `micro`
  - `yazi`
  - `ghostty` terminfo
  - `kitty` terminfo

The helper scripts are:

- [`setup-zsh.sh`](setup-zsh.sh)
- [`setup-git.sh`](setup-git.sh)
- [`setup-micro.sh`](setup-micro.sh)
- [`setup-yazi.sh`](setup-yazi.sh)

## Prerequisites

Before running the setup:

- macOS: install [Homebrew](https://brew.sh/)
- Linux: use a system with `apt`; `snap` is used when available for some packages
- have `git`, `curl`, `tar`, and `unzip` available
- have `sudo` access for package installation on Linux
- have GitHub SSH access configured for `git@github.com:lukaszcz/...` repositories

## Usage

Run the full bootstrap:

```bash
bash ./setup.sh
```

To reuse a specific temp directory instead of a new `mktemp` directory:

```bash
bash ./setup.sh --tmp-dir /path/to/tmp
```

Show help:

```bash
bash ./setup.sh --help
```

## Files changed in `$HOME`

The scripts write directly into the current user's home directory. Notable outputs include:

- `~/.local/bin`
- `~/.zshinit.zsh`
- `~/.zsh_plugins.txt`
- `~/.zshrc`
- `~/.config/micro`
- `~/.config/yazi`
- global Git config via `git config --global ...`

`setup.sh` appends `source $HOME/.zshinit.zsh` to `~/.zshrc` each time it runs, so repeated runs will add duplicate lines unless you clean that up manually.

## Repository layout

- [`setup.sh`](setup.sh): main bootstrap script
- [`tests/install_bin_test.sh`](tests/install_bin_test.sh): regression tests for the `install_bin` helper
- [`zsh/`](zsh): base and OS-specific zsh config
- [`micro/`](micro): micro editor config
- [`yazi/`](yazi): yazi config and plugins
- [`ghostty/`](ghostty): Ghostty config and terminfo
- [`kitty/`](kitty): Kitty config and terminfo
- [`opencode/`](opencode): OpenCode config
- [`claude/`](claude): Claude local settings

## Tests

Run the included shell test with:

```bash
bash ./tests/install_bin_test.sh
```

This verifies the archive-handling logic used by `install_bin`.

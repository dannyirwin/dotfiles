# dotfiles

Personal dotfiles for WezTerm, tmux, Zsh, Neovim, and agent tooling.
Cross-platform bootstrap for macOS, Linux, and Windows.

## What's included

| Path | Purpose |
|---|---|
| `wezterm/wezterm.lua` | WezTerm - Tokyo Night theme, key bindings, cross-platform shell detection |
| `tmux/tmux.conf` | tmux - Tokyo Night theme, vi copy mode, pane/window navigation |
| `zsh/.zshrc` | Zsh - completions, history, plugins, fzf |
| `zsh/common.sh` | Shared aliases and functions (sourced by zsh and bash) |
| `zsh/starship.toml` | Starship prompt - Tokyo Night colors |
| `nvim/` | Neovim - Tokyo Night, lazy.nvim, which-key, Telescope |
| `.agents/AGENTS.md` | Shared agent instructions (Cursor, Claude Code, etc.) |
| `.agents/OPINIONS.md` | Durable beliefs and taste map for agents |
| `skills-lock.json` | Locked agent skills list (installed via `npx skills`) |
| `install.sh` | Bootstrap script for macOS / Linux |
| `docs/install.sh` | Remote one-liner bootstrap (`curl \| sh`) |
| `install.ps1` | Bootstrap script for Windows (PowerShell) |

## Quick start

### macOS / Linux

One-liner (clone + install):

```bash
curl -fsSL https://raw.githubusercontent.com/dannyirwin/dotfiles/main/docs/install.sh | sh
```

Or clone manually:

```bash
git clone https://github.com/dannyirwin/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash install.sh
```

### Windows

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
git clone https://github.com/dannyirwin/dotfiles.git $HOME\dotfiles
cd $HOME\dotfiles
.\install.ps1
```

### Install flags

| Flag | Applies to | Effect |
|---|---|---|
| `--dry-run` | `install.sh`, curl bootstrap | Print actions without making changes |
| `--skip-skills` | `install.sh`, curl bootstrap | Skip `npx skills experimental_install` |
| `--skip-no-mistakes` | `install.sh`, curl bootstrap | Skip [no-mistakes](https://github.com/kunchenguid/no-mistakes) install and gate setup |
| `-DryRun` | `install.ps1` | Print actions without making changes |
| `-SkipSkills` | `install.ps1` | Skip agent skills install |

Examples:

```bash
bash install.sh --dry-run
bash install.sh --skip-skills --skip-no-mistakes
curl -fsSL https://raw.githubusercontent.com/dannyirwin/dotfiles/main/docs/install.sh | sh -s -- --dry-run
```

Environment variables for the curl bootstrap:

| Variable | Default |
|---|---|
| `DOTFILES_REPO` | `dannyirwin/dotfiles` |
| `DOTFILES_BRANCH` | `main` |
| `DOTFILES_DIR` | `$HOME/dotfiles` |

## How symlinking works

The install scripts create symlinks from where programs expect config to the files in this repo:

```
~/.config/wezterm/wezterm.lua  →  ~/dotfiles/wezterm/wezterm.lua
~/.tmux.conf                    →  ~/dotfiles/tmux/tmux.conf
~/.zshrc                        →  ~/dotfiles/zsh/.zshrc
~/.config/shell/common.sh       →  ~/dotfiles/zsh/common.sh
~/.config/starship.toml         →  ~/dotfiles/zsh/starship.toml
~/.config/nvim                  →  ~/dotfiles/nvim
~/dotfiles/AGENTS.md            →  ~/dotfiles/.agents/AGENTS.md
~/.agents                       →  ~/dotfiles/.agents
~/.claude/CLAUDE.md             →  ~/dotfiles/.agents/AGENTS.md
```

Edit files in `~/dotfiles` and commit to save changes.
Re-run `install.sh` only when new symlinks are added.

## Neovim

First launch installs plugins automatically via lazy.nvim.

| Key | Action |
|---|---|
| `<Space>ff` | Find files (Telescope) |
| `<Space><Space>` | Find files (shortcut) |
| `<Space>fr` | Recent files |
| `<Space>fg` | Live grep (needs `ripgrep`) |
| `<Space>fb` | Open buffers |
| `<Space>fh` | Help tags |
| `<Space>w` | Save |
| `<Space>q` | Quit window |
| `<Space>` then wait | which-key popup |

## Agent setup

### Instructions

The source of truth is `.agents/AGENTS.md`.
Root `AGENTS.md` is a symlink so Cursor discovers it in this repo.

`install.sh` links those files so tools find them in the usual places:

- `AGENTS.md` at the repo root for Cursor in this project
- `~/.agents/` for global access to `OPINIONS.md` and skills
- `~/.claude/CLAUDE.md` for Claude Code global instructions

Edit `.agents/AGENTS.md` for rules that apply across agents.
Edit `.agents/OPINIONS.md` for durable taste and engineering beliefs agents should read on demand.

### Skills

Skills are managed with the agent-agnostic [`npx skills`](https://skills.sh/) CLI.
Commit `skills-lock.json` only.
Installed skill files under `.agents/skills/` are generated and gitignored.

Add a skill:

```bash
cd ~/dotfiles
npx skills add anthropics/skills --skill skill-creator -y
git add skills-lock.json
```

Install locked skills on a new machine (also runs automatically from `install.sh`):

```bash
cd ~/dotfiles
npx skills experimental_install
```

### no-mistakes

On macOS and Linux, `install.sh` installs [no-mistakes](https://github.com/kunchenguid/no-mistakes) and runs `no-mistakes init` for this repo.
That adds a `no-mistakes` git remote and installs the `/no-mistakes` agent skill at user level.

Push through the validation gate:

```bash
git push no-mistakes <branch>
```

Or invoke `/no-mistakes` in a new agent chat after install.
Start a fresh chat session so the skill is loaded.

Windows is not supported by no-mistakes yet.
Use `-SkipSkills` on Windows as needed; there is no Windows gate setup.

## Machine-specific config

Anything you do not want tracked (API keys, work paths, etc.) goes in:

- **macOS / Linux:** `~/.zshrc.local` - auto-sourced at the bottom of `.zshrc`
- **Windows:** a local `local.ps1` dot-sourced from your PowerShell profile

## Recommended fonts

WezTerm falls back gracefully without these, but they look best:

- [JetBrains Mono](https://www.jetbrains.com/legalnotices/font/)
- [Cascadia Code](https://github.com/microsoft/cascadia-code) (Windows; bundled with some terminals)

## Updating

```bash
cd ~/dotfiles
git pull
# Re-run install.sh only if new symlinks or install steps were added
bash install.sh
```

## Adding more configs

1. Add config files under a new folder in this repo (for example `git/`).
2. Add a `link_*()` function to `install.sh` and `install.ps1`.
3. Call it from the run section at the bottom of each script.
4. Document the new path in this README.

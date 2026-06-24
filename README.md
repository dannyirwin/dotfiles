# dotfiles

Personal dotfiles — WezTerm + tmux + Zsh/Bash, cross-platform (macOS, Linux, Windows).

## What's included

| File | Purpose |
|---|---|
| `wezterm/wezterm.lua` | WezTerm config — Tokyo Night theme, key bindings, cross-platform shell detection |
| `tmux/tmux.conf` | tmux config — Tokyo Night theme, vi copy mode, pane/window navigation |
| `zsh/.zshrc` | Zsh config — completions, history, plugins, fzf |
| `zsh/common.sh` | Shared aliases and functions (sourced by zsh and bash) |
| `zsh/starship.toml` | Starship prompt — Tokyo Night colors |
| `nvim/init.lua` | Neovim config — Tokyo Night, which-key, Telescope |
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

Preview first:

```bash
curl -fsSL https://raw.githubusercontent.com/dannyirwin/dotfiles/main/docs/install.sh | sh -s -- --dry-run
```

Skip agent skills if Node.js is not available yet:

```bash
curl -fsSL https://raw.githubusercontent.com/dannyirwin/dotfiles/main/docs/install.sh | sh -s -- --skip-skills
```

Or clone manually:

```bash
git clone https://github.com/dannyirwin/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash install.sh
```

Preview changes first with `--dry-run`:

```bash
bash install.sh --dry-run
```

Skip agent skills:

```bash
bash install.sh --skip-skills
```

### Windows

```powershell
# In an elevated PowerShell window:
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
git clone https://github.com/dannyirwin/dotfiles.git $HOME\dotfiles
cd $HOME\dotfiles
.\install.ps1
```

---

## How symlinking works

The install scripts create symlinks from where programs expect their config to the files inside this repo:

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

Any edit you make to files in `~/dotfiles` is immediately reflected — no copying needed. Commit and push to save changes to GitHub.

### Neovim keymaps

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
| `<Space>` then wait | which-key popup for discoverable keys |

First launch installs plugins automatically via lazy.nvim.

### Agent instructions

The source of truth is `.agents/AGENTS.md`.
Root `AGENTS.md` is a symlink so Cursor discovers it in this repo.

Edit `.agents/AGENTS.md` for rules that apply across Cursor, Claude Code, and other agents.
Edit `.agents/OPINIONS.md` for durable taste and engineering beliefs agents should read on demand.

`install.sh` links those files so tools find them in the usual places:

- `AGENTS.md` at the repo root for Cursor in this project
- `~/.agents/` for global access to `OPINIONS.md` and skills
- `~/.claude/CLAUDE.md` for Claude Code global instructions

### Agent skills

Skills are managed with the agent-agnostic [`npx skills`](https://skills.sh/) CLI, not copied by hand.
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

`experimental_install` restores skills from `skills-lock.json` into `.agents/skills/` and registers them with detected agents (Cursor, Claude Code, Codex, and others).

---

## Machine-specific config

Anything you don't want tracked (API keys, work-specific paths, etc.) goes in:

- **Mac/Linux:** `~/.zshrc.local` — auto-sourced at the bottom of `.zshrc`
- **Windows:** Create a `local.ps1` and dot-source it from your PowerShell profile

---

## Recommended fonts

WezTerm will fall back gracefully if fonts aren't installed, but for the best experience:

- **JetBrains Mono** — https://www.jetbrains.com/legalnotices/font/
- **Cascadia Code** — https://github.com/microsoft/cascadia-code (Windows, already bundled with some terminals)

---

## Adding more configs later

To add git, Neovim, etc:

1. Create a folder: `mkdir git` or `mkdir nvim`
2. Drop the config files inside
3. Add a `link_git()` or `link_nvim()` function to `install.sh` and `install.ps1`
4. Call it at the bottom of each script

---

## Updating

```bash
cd ~/dotfiles
git pull
# re-run install.sh only if new symlinks were added
```


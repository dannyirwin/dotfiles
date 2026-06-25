# dotfiles

Personal dotfiles for WezTerm, tmux, Zsh, Neovim, and agent tooling.
Cross-platform bootstrap for macOS, Linux, and Windows.

## Prerequisites

Install these yourself before running the bootstrap scripts:

- **WezTerm** - configs are linked, not installed
- **git** - required for clone and no-mistakes setup
- **Node.js** (optional) - needed for `npx skills` agent skill installs

On Windows, enable **Developer Mode** (Settings → System → For developers) so
symbolic links work without an elevated shell.

## What's included

| Path | Purpose |
| --- | --- |
| `wezterm/wezterm.lua` | WezTerm - Tokyo Night, key bindings, shell detection |
| `tmux/tmux.conf` | tmux - Tokyo Night, vi copy mode, pane/window navigation |
| `zsh/.zshrc` | Zsh - Zinit plugins, completions, history, fzf, Starship |
| `zsh/common.sh` | Shared aliases (linked to `~/.config/shell/common.sh`) |
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
curl -fsSL \
  https://raw.githubusercontent.com/dannyirwin/dotfiles/main/docs/install.sh | sh
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
| --- | --- | --- |
| `--dry-run` | `install.sh`, curl bootstrap | Print actions without changes |
| `--skip-skills` | `install.sh`, curl bootstrap | Skip skills install |
| `--skip-no-mistakes` | `install.sh`, curl bootstrap | Skip [no-mistakes](https://github.com/kunchenguid/no-mistakes) gate setup |
| `--skip-plannotator` | `install.sh`, curl bootstrap | Skip [Plannotator](https://plannotator.ai) install |
| `-DryRun` | `install.ps1` | Print actions without making changes |
| `-SkipSkills` | `install.ps1` | Skip agent skills install |

Examples:

```bash
bash install.sh --dry-run
bash install.sh --skip-skills --skip-no-mistakes
curl -fsSL \
  https://raw.githubusercontent.com/dannyirwin/dotfiles/main/docs/install.sh \
  | sh -s -- --dry-run
```

Environment variables for the curl bootstrap:

| Variable | Default |
| --- | --- |
| `DOTFILES_REPO` | `dannyirwin/dotfiles` |
| `DOTFILES_BRANCH` | `main` |
| `DOTFILES_DIR` | `$HOME/dotfiles` |

Windows examples:

```powershell
.\install.ps1 -DryRun
.\install.ps1 -SkipSkills
```

## What the install scripts do

Both scripts link configs into the usual locations, install agent skills from
`skills-lock.json` when Node.js is available, and back up any existing files
they replace.

**macOS / Linux (`install.sh`)** also:

- Installs Homebrew on macOS when missing
- Installs CLI tools via Homebrew (macOS) or `apt-get` (Debian/Ubuntu Linux)
- Links Zsh config (`~/.zshrc`, `common.sh`, Starship)
- Installs and initializes [no-mistakes](https://github.com/kunchenguid/no-mistakes)
  unless `--skip-no-mistakes` is passed
- Installs [Plannotator](https://plannotator.ai) unless `--skip-plannotator` is passed

Linux package install requires `apt-get`.
Other distros need manual package installs before linking.

**Windows (`install.ps1`)** also:

- Installs CLI tools via `winget` when available
- Links Starship config and appends a dotfiles block to your PowerShell profile
  (Starship, zoxide, git aliases)
- Does not link Zsh config (use PowerShell on Windows)
- Does not install or configure no-mistakes

## How symlinking works

Edit files in `~/dotfiles` (or `%USERPROFILE%\dotfiles` on Windows) and commit
to save changes.
Re-run the install script only when new symlinks or install steps are added.

### Symlink map (macOS / Linux)

```text
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

### Symlink map (Windows)

```text
%USERPROFILE%\.config\wezterm\wezterm.lua  →  %USERPROFILE%\dotfiles\wezterm\wezterm.lua
%USERPROFILE%\.tmux.conf                    →  %USERPROFILE%\dotfiles\tmux\tmux.conf
%USERPROFILE%\.config\starship.toml         →  %USERPROFILE%\dotfiles\zsh\starship.toml
%USERPROFILE%\.config\nvim                  →  %USERPROFILE%\dotfiles\nvim
%USERPROFILE%\dotfiles\AGENTS.md            →  %USERPROFILE%\dotfiles\.agents\AGENTS.md
%USERPROFILE%\.agents                       →  %USERPROFILE%\dotfiles\.agents
%USERPROFILE%\.claude\CLAUDE.md             →  %USERPROFILE%\dotfiles\.agents\AGENTS.md
```

## Neovim

First launch installs plugins automatically via lazy.nvim.

| Key | Action |
| --- | --- |
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

`install.sh` and `install.ps1` link those files so tools find them in the
usual places:

- `AGENTS.md` at the repo root for Cursor in this project
- `~/.agents/` for global access to `OPINIONS.md` and skills
- `~/.claude/CLAUDE.md` for Claude Code global instructions

Edit `.agents/AGENTS.md` for rules that apply across agents.
Edit `.agents/OPINIONS.md` for durable taste and engineering beliefs agents
should read on demand.

### Skills

Skills are managed with the agent-agnostic [`npx skills`](https://skills.sh/) CLI.
Commit `skills-lock.json` only.
Installed skill files are generated and gitignored (`.agents/skills/`,
`.cursor/skills/`, `.claude/skills/`, and `.agents/.skill-lock.json`).

Pre-locked skills: `gh-axi`, `lavish`, and `skill-creator`.

Add a skill:

```bash
cd ~/dotfiles
npx skills add anthropics/skills --skill skill-creator -y
git add skills-lock.json
```

Install locked skills on a new machine (also runs automatically from the install
scripts):

```bash
cd ~/dotfiles
npx skills experimental_install
```

### no-mistakes

On macOS and Linux, `install.sh` installs
[no-mistakes](https://github.com/kunchenguid/no-mistakes) and runs
`no-mistakes init` for this repo when it is a git checkout with an `origin`
remote.
That adds a `no-mistakes` git remote and installs the `/no-mistakes` agent skill
at user level.

Push through the validation gate:

```bash
git push no-mistakes <branch>
```

Or invoke `/no-mistakes` in a new agent chat after install.
Start a fresh chat session so the skill is loaded.

Windows is not supported by no-mistakes yet.
Use `-SkipSkills` on Windows only to skip agent skill installs.

### Plannotator

On macOS and Linux, `install.sh` installs [Plannotator](https://plannotator.ai) when it is not already on `PATH`.
The installer runs non-interactively with default options (core binary and agent skills only).

Re-run the upstream installer to change extras or model-invocable skills:

```bash
curl -fsSL https://plannotator.ai/install.sh | bash
```

Windows uses a separate PowerShell installer and is not wired into `install.ps1` yet.

## Machine-specific config

Anything you do not want tracked (API keys, work paths, etc.) goes in:

- **macOS / Linux:** `~/.zshrc.local` - auto-sourced at the bottom of `.zshrc`
- **Windows:** add overrides to your PowerShell profile, or dot-source a local
  `$HOME\dotfiles\local.ps1` from there yourself

## Recommended fonts

WezTerm falls back gracefully without these, but they look best:

- [JetBrains Mono](https://www.jetbrains.com/legalnotices/font/)
- [Cascadia Code](https://github.com/microsoft/cascadia-code) (Windows; bundled
  with some terminals)

## Updating

```bash
cd ~/dotfiles
git pull
# Re-run the install script only if new symlinks or install steps were added
bash install.sh
```

On Windows, run `.\install.ps1` instead of `bash install.sh`.

## Adding more configs

1. Add config files under a new folder in this repo (for example `git/`).
2. Add a `link_*()` function to `install.sh` and a matching `Link-*` function
   to `install.ps1`.
3. Call it from the run section at the bottom of each script.
4. Document the new path in this README.

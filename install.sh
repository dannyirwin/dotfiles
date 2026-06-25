#!/usr/bin/env bash
# install.sh — dotfiles bootstrap for macOS and Linux
# Usage: bash install.sh [--dry-run] [--skip-skills] [--skip-no-mistakes]
# Installs packages (Homebrew or apt-get), links configs, agent skills, and no-mistakes.
# Dotfiles: github.com/dannyirwin/dotfiles

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=false
SKIP_SKILLS=false
SKIP_NO_MISTAKES=false

# ─────────────────────────────────────────────
#  Helpers
# ─────────────────────────────────────────────
log() { printf "\033[0;34m▶\033[0m  %s\n" "$*"; }
success() { printf "\033[0;32m✔\033[0m  %s\n" "$*"; }
warn() { printf "\033[0;33m⚠\033[0m  %s\n" "$*"; }
error() { printf "\033[0;31m✖\033[0m  %s\n" "$*" >&2; }

run() {
	if $DRY_RUN; then
		printf "\033[0;90m[dry-run]\033[0m %s\n" "$*"
	else
		"$@"
	fi
}

run_pipe() {
	local desc="$1"
	shift
	if $DRY_RUN; then
		printf "\033[0;90m[dry-run]\033[0m %s\n" "$desc"
	else
		"$@"
	fi
}

backup_existing() {
	local dst="$1"
	local backup="${dst}.backup"
	if [[ -e "$backup" ]]; then
		backup="${dst}.backup.$(date +%Y%m%d%H%M%S)"
	fi
	run mv "$dst" "$backup"
}

ensure_brew_path() {
	if ! $IS_MAC || command -v brew &>/dev/null; then
		return
	fi
	if [[ -x /opt/homebrew/bin/brew ]]; then
		eval "$(/opt/homebrew/bin/brew shellenv)"
	elif [[ -x /usr/local/bin/brew ]]; then
		eval "$(/usr/local/bin/brew shellenv)"
	fi
}

# Parse flags
for arg in "$@"; do
	[[ "$arg" == "--dry-run" ]] && DRY_RUN=true
	[[ "$arg" == "--skip-skills" ]] && SKIP_SKILLS=true
	[[ "$arg" == "--skip-no-mistakes" ]] && SKIP_NO_MISTAKES=true
done

$DRY_RUN && warn "Dry-run mode — no changes will be made."

# ─────────────────────────────────────────────
#  Platform
# ─────────────────────────────────────────────
OS="$(uname -s)"
case "$OS" in
Darwin) IS_MAC=true ;;
Linux) IS_MAC=false ;;
*)
	error "Unsupported OS: $OS"
	exit 1
	;;
esac

# ─────────────────────────────────────────────
#  Symlink helper
#  link_file <source> <target>
# ─────────────────────────────────────────────
link_file() {
	local src="$1" dst="$2"
	local dst_dir
	dst_dir="$(dirname "$dst")"

	run mkdir -p "$dst_dir"

	if [[ -e "$dst" && ! -L "$dst" ]]; then
		warn "Backing up existing file: $dst"
		backup_existing "$dst"
	fi

	if [[ -L "$dst" ]]; then
		run rm "$dst"
	fi

	run ln -s "$src" "$dst"
	success "Linked: $dst → $src"
}

# ─────────────────────────────────────────────
#  Homebrew (Mac only)
# ─────────────────────────────────────────────
install_homebrew() {
	if $IS_MAC && ! command -v brew &>/dev/null; then
		log "Installing Homebrew..."
		if $DRY_RUN; then
			printf "\033[0;90m[dry-run]\033[0m /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"\n"
		elif /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
			success "Installed Homebrew"
		else
			warn "Homebrew install failed — continuing (install manually from https://brew.sh)"
		fi
	fi
}

install_mac_packages() {
	if ! $IS_MAC; then return; fi
	ensure_brew_path
	if ! command -v brew &>/dev/null; then
		warn "Homebrew not available — skipping Mac package install"
		return
	fi
	log "Installing packages via Homebrew..."

	local packages=(
		starship # prompt
		fzf      # fuzzy finder
		fd       # fast find
		ripgrep  # fast grep
		zsh-autosuggestions
		zsh-syntax-highlighting
		zoxide # smarter cd
		git
		tmux
		neovim
	)

	for pkg in "${packages[@]}"; do
		if brew list "$pkg" &>/dev/null; then
			log "Already installed: $pkg"
		elif $DRY_RUN; then
			run brew install "$pkg"
		elif brew install "$pkg"; then
			success "Installed: $pkg"
		else
			warn "Skipped $pkg (brew install failed)"
		fi
	done
}

install_linux_packages() {
	if $IS_MAC; then return; fi
	log "Installing packages (apt)..."

	if ! command -v apt-get &>/dev/null; then
		warn "apt-get not found — skipping Linux package install"
		return
	fi

	local packages=(
		zsh
		git
		curl
		fzf
		fd-find
		ripgrep
		tmux
		ncurses-term
		neovim
		xclip
		wl-clipboard
	)

	if $DRY_RUN; then
		run sudo apt-get update -qq
		for pkg in "${packages[@]}"; do
			run sudo apt-get install -y "$pkg"
		done
	else
		if ! sudo apt-get update -qq; then
			warn "apt-get update failed — continuing with package install"
		fi
		for pkg in "${packages[@]}"; do
			if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q " install ok installed"; then
				log "Already installed: $pkg"
			elif sudo apt-get install -y "$pkg"; then
				success "Installed: $pkg"
			else
				warn "Skipped $pkg (apt install failed)"
			fi
		done
	fi

	if ! command -v fd &>/dev/null && command -v fdfind &>/dev/null; then
		local fdfind_bin fd_link="$HOME/.local/bin/fd"
		fdfind_bin="$(command -v fdfind)"
		run mkdir -p "$HOME/.local/bin"
		if run ln -sf "$fdfind_bin" "$fd_link"; then
			export PATH="$HOME/.local/bin:$PATH"
		else
			warn "Could not link fd — use fdfind or alias fd=fdfind"
		fi
	fi

	# Starship
	if ! command -v starship &>/dev/null; then
		log "Installing Starship prompt..."
		if run_pipe 'curl -sS https://starship.rs/install.sh | sh -s -- --yes' \
			sh -c 'curl -sS https://starship.rs/install.sh | sh -s -- --yes'; then
			success "Installed Starship"
		else
			warn "Starship install failed — continuing (install manually from https://starship.rs)"
		fi
	fi

	# zoxide
	if ! command -v zoxide &>/dev/null; then
		log "Installing zoxide..."
		if run_pipe 'curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash' \
			bash -c 'curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash'; then
			success "Installed zoxide"
		else
			warn "zoxide install failed — continuing (install manually from https://github.com/ajeetdsouza/zoxide)"
		fi
	fi
}

# ─────────────────────────────────────────────
#  WezTerm config
# ─────────────────────────────────────────────
link_wezterm() {
	log "Linking WezTerm config..."
	if $IS_MAC; then
		# WezTerm checks ~/.config/wezterm/wezterm.lua first on Mac
		link_file "$DOTFILES_DIR/wezterm/wezterm.lua" \
			"$HOME/.config/wezterm/wezterm.lua"
	else
		link_file "$DOTFILES_DIR/wezterm/wezterm.lua" \
			"$HOME/.config/wezterm/wezterm.lua"
	fi
}

# ─────────────────────────────────────────────
#  tmux config
# ─────────────────────────────────────────────
link_tmux() {
	log "Linking tmux config..."
	link_file "$DOTFILES_DIR/tmux/tmux.conf" \
		"$HOME/.tmux.conf"
}

# ─────────────────────────────────────────────
#  Shell config
# ─────────────────────────────────────────────
link_shell() {
	log "Linking shell config..."

	# Shared common config
	link_file "$DOTFILES_DIR/zsh/common.sh" \
		"$HOME/.config/shell/common.sh"

	# zshrc
	link_file "$DOTFILES_DIR/zsh/.zshrc" \
		"$HOME/.zshrc"

	# Starship prompt
	link_file "$DOTFILES_DIR/zsh/starship.toml" \
		"$HOME/.config/starship.toml"
}

# ─────────────────────────────────────────────
#  Neovim config
# ─────────────────────────────────────────────
link_nvim() {
	log "Linking Neovim config..."
	local dst="$HOME/.config/nvim"

	run mkdir -p "$(dirname "$dst")"

	if [[ -e "$dst" && ! -L "$dst" ]]; then
		warn "Backing up existing directory: $dst"
		backup_existing "$dst"
	fi

	if [[ -L "$dst" ]]; then
		run rm "$dst"
	fi

	run ln -s "$DOTFILES_DIR/nvim" "$dst"
	success "Linked: $dst → $DOTFILES_DIR/nvim"
}

# ─────────────────────────────────────────────
#  Agent instructions
# ─────────────────────────────────────────────
link_agents() {
	log "Linking agent instructions..."

	# Cursor and other tools: repo-root AGENTS.md (relative target for git portability)
	local agents_md="$DOTFILES_DIR/AGENTS.md"
	if [[ -e "$agents_md" && ! -L "$agents_md" ]]; then
		warn "Backing up existing file: $agents_md"
		backup_existing "$agents_md"
	fi
	if [[ -L "$agents_md" ]]; then
		run rm "$agents_md"
	fi
	if $DRY_RUN; then
		printf "\033[0;90m[dry-run]\033[0m (cd %s && ln -snf .agents/AGENTS.md AGENTS.md)\n" "$DOTFILES_DIR"
	else
		(cd "$DOTFILES_DIR" && ln -snf .agents/AGENTS.md AGENTS.md)
		success "Linked: $agents_md → .agents/AGENTS.md"
	fi

	# Global agent context (OPINIONS.md, future automation)
	local agents_dst="$HOME/.agents"

	run mkdir -p "$(dirname "$agents_dst")"

	if [[ -e "$agents_dst" && ! -L "$agents_dst" ]]; then
		warn "Backing up existing directory: $agents_dst"
		backup_existing "$agents_dst"
	fi

	if [[ -L "$agents_dst" ]]; then
		run rm "$agents_dst"
	fi

	run ln -s "$DOTFILES_DIR/.agents" "$agents_dst"
	success "Linked: $agents_dst → $DOTFILES_DIR/.agents"

	# Claude Code global instructions
	link_file "$DOTFILES_DIR/.agents/AGENTS.md" \
		"$HOME/.claude/CLAUDE.md"
}

# ─────────────────────────────────────────────
#  Agent skills (via npx skills)
# ─────────────────────────────────────────────
install_skills() {
	if $SKIP_SKILLS; then
		warn "Skipping skills install (--skip-skills)"
		return
	fi

	if [[ ! -f "$DOTFILES_DIR/skills-lock.json" ]]; then
		log "No skills-lock.json found — skipping skills install"
		return
	fi

	if ! command -v npx &>/dev/null; then
		warn "npx not found — skipping skills install (install Node.js to enable)"
		return
	fi

	log "Installing agent skills from skills-lock.json..."

	if $DRY_RUN; then
		printf "\033[0;90m[dry-run]\033[0m cd %s && npx --yes skills experimental_install\n" "$DOTFILES_DIR"
		return
	fi

	if (cd "$DOTFILES_DIR" && npx --yes skills experimental_install); then
		success "Skills installed from skills-lock.json"
	else
		warn "Skills install failed — continuing (run 'npx skills experimental_install' in $DOTFILES_DIR manually)"
	fi
}

# ─────────────────────────────────────────────
#  no-mistakes git gate + /no-mistakes skill
# ─────────────────────────────────────────────
setup_no_mistakes() {
	if $SKIP_NO_MISTAKES; then
		warn "Skipping no-mistakes setup (--skip-no-mistakes)"
		return
	fi

	if ! git -C "$DOTFILES_DIR" rev-parse --is-inside-work-tree &>/dev/null; then
		warn "Not a git repo — skipping no-mistakes init"
		return
	fi

	if ! git -C "$DOTFILES_DIR" remote get-url origin &>/dev/null; then
		warn "No origin remote — skipping no-mistakes init"
		return
	fi

	local no_mistakes_url="https://raw.githubusercontent.com/kunchenguid/no-mistakes/main/docs/install.sh"
	export PATH="$HOME/.local/bin:$PATH"

	if ! command -v no-mistakes &>/dev/null; then
		log "Installing no-mistakes..."
		if $DRY_RUN; then
			printf "\033[0;90m[dry-run]\033[0m curl -fsSL %s | sh\n" "$no_mistakes_url"
			printf "\033[0;90m[dry-run]\033[0m cd %s && no-mistakes init\n" "$DOTFILES_DIR"
			return
		fi
		if curl -fsSL "$no_mistakes_url" | sh; then
			success "Installed no-mistakes"
		else
			warn "no-mistakes install failed — skipping init"
			return
		fi
	fi

	log "Initializing no-mistakes gate for dotfiles..."
	if $DRY_RUN; then
		printf "\033[0;90m[dry-run]\033[0m cd %s && no-mistakes init\n" "$DOTFILES_DIR"
		return
	fi

	if (cd "$DOTFILES_DIR" && no-mistakes init); then
		success "no-mistakes gate initialized (git push no-mistakes <branch>, or /no-mistakes in agents)"
	else
		warn "no-mistakes init failed — continuing (run 'no-mistakes init' in $DOTFILES_DIR manually)"
	fi
}

# ─────────────────────────────────────────────
#  Run
# ─────────────────────────────────────────────
echo ""
echo "  ██████╗  ██████╗ ████████╗███████╗██╗██╗     ███████╗███████╗"
echo "  ██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝██║██║     ██╔════╝██╔════╝"
echo "  ██║  ██║██║   ██║   ██║   █████╗  ██║██║     █████╗  ███████╗"
echo "  ██║  ██║██║   ██║   ██║   ██╔══╝  ██║██║     ██╔══╝  ╚════██║"
echo "  ██████╔╝╚██████╔╝   ██║   ██║     ██║███████╗███████╗███████║"
echo "  ╚═════╝  ╚═════╝    ╚═╝   ╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝"
echo ""

install_homebrew
ensure_brew_path
install_mac_packages
install_linux_packages
link_wezterm
link_tmux
link_shell
link_nvim
link_agents
install_skills
setup_no_mistakes

echo ""
success "All done! Restart WezTerm and open a new shell to see changes."
echo ""
echo "  Optional next steps:"
echo "  • Install JetBrains Mono font: https://www.jetbrains.com/legalnotices/font/"
echo "  • Add a ~/.zshrc.local for machine-specific config (not tracked)"
echo "  • Run 'git -C $DOTFILES_DIR status' to check everything looks right"
echo ""

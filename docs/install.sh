#!/bin/sh
# Remote bootstrap for dotfiles (macOS / Linux)
#
# One-liner:
#   curl -fsSL https://raw.githubusercontent.com/dannyirwin/dotfiles/main/docs/install.sh | sh
#
# With options (passed to install.sh):
#   curl -fsSL https://raw.githubusercontent.com/dannyirwin/dotfiles/main/docs/install.sh | sh -s -- --dry-run
#   curl -fsSL https://raw.githubusercontent.com/dannyirwin/dotfiles/main/docs/install.sh | sh -s -- --skip-skills
#   curl -fsSL https://raw.githubusercontent.com/dannyirwin/dotfiles/main/docs/install.sh | sh -s -- --skip-no-mistakes
#   curl -fsSL https://raw.githubusercontent.com/dannyirwin/dotfiles/main/docs/install.sh | sh -s -- --profile coding
#   curl -fsSL https://raw.githubusercontent.com/dannyirwin/dotfiles/main/docs/install.sh | sh -s -- --skip-plannotator
#
# Environment:
#   DOTFILES_REPO=dannyirwin/dotfiles
#   DOTFILES_BRANCH=main
#   DOTFILES_DIR=$HOME/dotfiles

set -e

REPO="${DOTFILES_REPO:-dannyirwin/dotfiles}"
BRANCH="${DOTFILES_BRANCH:-main}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
DRY_RUN=0

if [ "${1:-}" = "--" ]; then
	shift
fi

for arg in "$@"; do
	case $arg in
	--dry-run) DRY_RUN=1 ;;
	esac
done

if ! command -v git >/dev/null 2>&1; then
	echo "git is required. Install Xcode Command Line Tools or git, then retry."
	exit 1
fi

if [ -e "$DOTFILES_DIR/.git" ]; then
	if [ "$DRY_RUN" -eq 1 ]; then
		echo "[dry-run] Would update dotfiles at $DOTFILES_DIR"
	else
		echo "Updating dotfiles at $DOTFILES_DIR..."
		git -C "$DOTFILES_DIR" fetch origin "$BRANCH"
		git -C "$DOTFILES_DIR" checkout "$BRANCH"
		git -C "$DOTFILES_DIR" pull --ff-only origin "$BRANCH" || {
			echo "Could not fast-forward $DOTFILES_DIR. Resolve locally or remove the directory and retry."
			exit 1
		}
	fi
else
	if [ -e "$DOTFILES_DIR" ]; then
		echo "$DOTFILES_DIR exists but is not a git repo."
		echo "Remove it, set DOTFILES_DIR to another path, or clone manually."
		exit 1
	fi
	if [ "$DRY_RUN" -eq 1 ]; then
		echo "[dry-run] Would clone dotfiles to $DOTFILES_DIR"
		echo "[dry-run] Would run install.sh $*"
		exit 0
	fi
	echo "Cloning dotfiles to $DOTFILES_DIR..."
	git clone --depth 1 --branch "$BRANCH" "https://github.com/${REPO}.git" "$DOTFILES_DIR"
fi

echo "Running install.sh..."
exec bash "$DOTFILES_DIR/install.sh" "$@"

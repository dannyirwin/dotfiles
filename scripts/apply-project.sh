#!/usr/bin/env bash
# apply-project.sh — copy dotfiles agent/Cursor bundles into a project repo
#
# Usage:
#   bash scripts/apply-project.sh [options] <target-repo>
#   bash install.sh --scope project [options] --target <target-repo>
#
# Applies shared agent instructions, Cursor bundles, and skills so a project
# works in local Cursor and Cursor Cloud (repo-scoped config only).
#
# Options:
#   --target <path>       Project root (alternative to positional argument)
#   --mode copy|link      copy (default) or symlink Cursor bundle files from dotfiles
#   --dry-run             Print actions without changes
#   --skip-skills         Skip skills-lock.json and npx skills install
#   --skip-agents         Skip .agents/ and root AGENTS.md
#   --skip-cursor         Skip cursor/ bundles under .cursor/
#   --bundle <name>       Cursor bundle to apply (default: implement-plan)
#   --skills inherit|merge|skip
#                         inherit: copy dotfiles lock when project has none (default)
#                         merge: merge dotfiles skills into project lock
#                         skip: do not touch skills-lock.json
#   -h, --help            Show help

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

DRY_RUN=false
SKIP_SKILLS=false
SKIP_AGENTS=false
SKIP_CURSOR=false
MODE=copy
BUNDLE=implement-plan
SKILLS_MODE=inherit
TARGET=""

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

usage() {
	cat <<'EOF'
Usage: bash scripts/apply-project.sh [options] <target-repo>

Apply dotfiles agent and Cursor configuration to a project repository.

Options:
  --target <path>       Project root (alternative to positional argument)
  --mode copy|link      copy (default) or symlink Cursor bundle files from dotfiles
  --dry-run             Print actions without making changes
  --skip-skills         Skip skills-lock.json and npx skills install
  --skip-agents         Skip .agents/ and root AGENTS.md
  --skip-cursor         Skip cursor/ bundles under .cursor/
  --bundle <name>       Cursor bundle name (default: implement-plan)
  --skills inherit|merge|skip
                        inherit (default), merge, or skip skills-lock.json
  -h, --help            Show this help

Examples:
  bash scripts/apply-project.sh ~/src/my-app
  bash scripts/apply-project.sh --mode link --dry-run ~/src/my-app
  bash install.sh --scope project --target ~/src/my-app
EOF
}

while [[ $# -gt 0 ]]; do
	case "$1" in
	--target)
		shift
		TARGET="${1:-}"
		if [[ -z "$TARGET" ]]; then
			error "--target requires a path"
			exit 1
		fi
		;;
	--mode)
		shift
		MODE="${1:-}"
		case "$MODE" in
		copy | link) ;;
		*)
			error "--mode must be copy or link"
			exit 1
			;;
		esac
		;;
	--dry-run) DRY_RUN=true ;;
	--skip-skills) SKIP_SKILLS=true ;;
	--skip-agents) SKIP_AGENTS=true ;;
	--skip-cursor) SKIP_CURSOR=true ;;
	--bundle)
		shift
		BUNDLE="${1:-}"
		if [[ -z "$BUNDLE" ]]; then
			error "--bundle requires a name"
			exit 1
		fi
		;;
	--skills)
		shift
		SKILLS_MODE="${1:-}"
		case "$SKILLS_MODE" in
		inherit | merge | skip) ;;
		*)
			error "--skills must be inherit, merge, or skip"
			exit 1
			;;
		esac
		;;
	-h | --help)
		usage
		exit 0
		;;
	--scope)
		shift
		if [[ "${1:-}" != "project" ]]; then
			error "apply-project.sh only supports --scope project (use install.sh for machine setup)"
			exit 1
		fi
		;;
	-*)
		error "Unknown option: $1 (try --help)"
		exit 1
		;;
	*)
		if [[ -n "$TARGET" ]]; then
			error "Unexpected argument: $1 (target already set to $TARGET)"
			exit 1
		fi
		TARGET="$1"
		;;
	esac
	shift
done

if [[ -z "$TARGET" ]]; then
	error "Target repository path is required"
	usage >&2
	exit 1
fi

if [[ ! -d "$TARGET" ]]; then
	error "Target is not a directory: $TARGET"
	exit 1
fi

TARGET="$(cd "$TARGET" && pwd)"
BUNDLE_DIR="$DOTFILES_DIR/cursor/$BUNDLE"

if ! $SKIP_CURSOR && [[ ! -d "$BUNDLE_DIR" ]]; then
	error "Cursor bundle not found: $BUNDLE_DIR"
	exit 1
fi

$DRY_RUN && warn "Dry-run mode — no changes will be made."

install_tree_entry() {
	local src="$1" dst="$2"
	local dst_parent
	dst_parent="$(dirname "$dst")"

	run mkdir -p "$dst_parent"

	if [[ -e "$dst" || -L "$dst" ]]; then
		if [[ -L "$dst" ]]; then
			local current
			current="$(readlink "$dst")"
			if [[ "$current" == "$src" ]]; then
				success "Already linked: $dst → $src"
				return
			fi
		fi
		# Applying dotfiles to itself: src and dst are the same file.
		if [[ -e "$src" ]] && [[ "$(realpath "$src")" == "$(realpath "$dst")" ]]; then
			success "Already present: $dst"
			return
		fi
		warn "Replacing existing path: $dst"
		run rm -rf "$dst"
	fi

	if [[ "$MODE" == "link" ]]; then
		run ln -s "$src" "$dst"
		success "Linked: $dst → $src"
	else
		if [[ -d "$src" ]]; then
			run cp -R "$src" "$dst"
		else
			run cp "$src" "$dst"
		fi
		success "Copied: $src → $dst"
	fi
}

install_file_entry() {
	local src="$1" dst="$2"
	install_tree_entry "$src" "$dst"
}

merge_hooks_json() {
	local dst="$1" src="$2"

	if [[ ! -f "$src" ]]; then
		return
	fi

	if [[ ! -f "$dst" ]]; then
		install_file_entry "$src" "$dst"
		return
	fi

	if ! command -v jq &>/dev/null; then
		warn "jq not found — leaving existing $dst (merge $src manually if needed)"
		return
	fi

	if $DRY_RUN; then
		printf "\033[0;90m[dry-run]\033[0m merge hooks: %s + %s → %s\n" "$dst" "$src" "$dst"
		return
	fi

	jq -s '
		.[0] as $base | .[1] as $add |
		$base
		| .version = ($base.version // $add.version // 1)
		| .hooks = (
			($base.hooks // {})
			+ (
				$add.hooks // {}
				| with_entries(
					.key as $k
					| .value = (
						(($base.hooks[$k] // []) + .value)
						| unique_by(.command // .)
					)
				)
			)
		)
	' "$dst" "$src" >"${dst}.tmp"
	mv "${dst}.tmp" "$dst"
	success "Merged hooks: $dst"
}

apply_cursor_bundle() {
	local bundle_root="$1"
	local cursor_root="$TARGET/.cursor"

	log "Applying Cursor bundle: $BUNDLE"

	run mkdir -p "$cursor_root"/{skills,agents,hooks,plans}

	if [[ -d "$bundle_root/skills" ]]; then
		for skill_dir in "$bundle_root/skills"/*; do
			[[ -d "$skill_dir" ]] || continue
			install_tree_entry "$skill_dir" "$cursor_root/skills/$(basename "$skill_dir")"
		done
	fi

	if [[ -d "$bundle_root/agents" ]]; then
		for agent_file in "$bundle_root/agents"/*.md; do
			[[ -f "$agent_file" ]] || continue
			install_file_entry "$agent_file" "$cursor_root/agents/$(basename "$agent_file")"
		done
	fi

	if [[ -f "$bundle_root/hooks/sync-plan-to-workspace.sh" ]]; then
		install_file_entry \
			"$bundle_root/hooks/sync-plan-to-workspace.sh" \
			"$cursor_root/hooks/sync-plan-to-workspace.sh"
		run chmod +x "$cursor_root/hooks/sync-plan-to-workspace.sh"
	fi

	merge_hooks_json "$cursor_root/hooks.json" "$bundle_root/hooks/hooks.json"

	if [[ -f "$bundle_root/plans/README.md" ]]; then
		install_file_entry "$bundle_root/plans/README.md" "$cursor_root/plans/README.md"
	fi
}

patch_agents_for_project() {
	local src_file="$1" dst_file="$2"
	if $DRY_RUN; then
		printf "\033[0;90m[dry-run]\033[0m patch %s → %s (OPINIONS path)\n" "$src_file" "$dst_file"
		return
	fi
	sed 's|~/.agents/OPINIONS.md|.agents/OPINIONS.md|g' "$src_file" >"$dst_file"
}

apply_agents() {
	local agents_dir="$TARGET/.agents"
	local root_agents="$TARGET/AGENTS.md"
	local shared_agents="$agents_dir/AGENTS.shared.md"
	local marker="<!-- dotfiles:shared-agents -->"

	log "Applying shared agent instructions..."

	run mkdir -p "$agents_dir"

	# Agent files are always copied (with project-local OPINIONS paths) so they
	# work in Cursor Cloud. Use --mode link for Cursor bundles only.
	install_file_entry "$DOTFILES_DIR/.agents/OPINIONS.md" "$agents_dir/OPINIONS.md"
	patch_agents_for_project "$DOTFILES_DIR/.agents/AGENTS.md" "$shared_agents"

	if [[ -f "$root_agents" && ! -L "$root_agents" ]]; then
		if ! grep -qF "$marker" "$root_agents" 2>/dev/null; then
			warn "Existing AGENTS.md kept at $root_agents"
			warn "Shared baseline written to $shared_agents (merge manually or add a project section)"
		else
			success "AGENTS.md already includes dotfiles shared marker"
		fi
		return
	fi

	if [[ -L "$root_agents" ]]; then
		run rm "$root_agents"
	fi

	if $DRY_RUN; then
		printf "\033[0;90m[dry-run]\033[0m write %s with shared baseline + project placeholder\n" "$root_agents"
		return
	fi

	cat >"$root_agents" <<EOF
$marker

EOF
	cat "$shared_agents" >>"$root_agents"
	cat >>"$root_agents" <<'EOF'

## Project

Add project-specific agent instructions below (build commands, cloud VM quirks,
architecture notes). This section is the right place for Cursor Cloud setup.
EOF
	success "Wrote: $root_agents"
}

merge_skills_lock() {
	local project_lock="$TARGET/skills-lock.json"
	local dotfiles_lock="$DOTFILES_DIR/skills-lock.json"

	if [[ ! -f "$dotfiles_lock" ]]; then
		warn "No dotfiles skills-lock.json — skipping skills lock step"
		return
	fi

	case "$SKILLS_MODE" in
	skip) return ;;
	inherit)
		if [[ -f "$project_lock" ]]; then
			log "Project already has skills-lock.json — leaving unchanged"
			return
		fi
		install_file_entry "$dotfiles_lock" "$project_lock"
		;;
	merge)
		if ! command -v jq &>/dev/null; then
			error "jq is required for --skills merge"
			exit 1
		fi
		if [[ ! -f "$project_lock" ]]; then
			install_file_entry "$dotfiles_lock" "$project_lock"
			return
		fi
		if $DRY_RUN; then
			printf "\033[0;90m[dry-run]\033[0m merge skills-lock.json\n"
			return
		fi
		jq -s '
			.[0] as $base | .[1] as $add |
			$base
			| .version = ($base.version // $add.version // 1)
			| .skills = (($base.skills // {}) + ($add.skills // {}))
		' "$project_lock" "$dotfiles_lock" >"${project_lock}.tmp"
		mv "${project_lock}.tmp" "$project_lock"
		success "Merged skills-lock.json"
		;;
	esac
}

install_project_skills() {
	if $SKIP_SKILLS || [[ "$SKILLS_MODE" == "skip" ]]; then
		warn "Skipping skills install"
		return
	fi

	local project_lock="$TARGET/skills-lock.json"
	if [[ ! -f "$project_lock" ]]; then
		warn "No skills-lock.json in project — skipping npx skills install"
		return
	fi

	if ! command -v npx &>/dev/null; then
		warn "npx not found — skipping skills install (install Node.js to enable)"
		return
	fi

	log "Installing agent skills in project..."
	if $DRY_RUN; then
		printf "\033[0;90m[dry-run]\033[0m cd %s && npx --yes skills experimental_install\n" "$TARGET"
		return
	fi

	if (cd "$TARGET" && npx --yes skills experimental_install); then
		success "Skills installed in project"
	else
		warn "Skills install failed — run 'npx skills experimental_install' in $TARGET manually"
	fi
}

suggest_gitignore() {
	local gitignore="$TARGET/.gitignore"
	local entries=(
		".agents/skills/"
		".agents/.skill-lock.json"
		".cursor/skills/"
		".claude/skills/"
	)

	for entry in "${entries[@]}"; do
		if [[ -f "$gitignore" ]] && grep -qxF "$entry" "$gitignore" 2>/dev/null; then
			continue
		fi
		warn "Consider adding '$entry' to $gitignore (generated by npx skills)"
	done
}

echo ""
echo "  apply-project — dotfiles → $TARGET"
echo ""

if ! $SKIP_CURSOR; then
	apply_cursor_bundle "$BUNDLE_DIR"
fi

if ! $SKIP_AGENTS; then
	apply_agents
fi

if ! $SKIP_SKILLS; then
	merge_skills_lock
	install_project_skills
	suggest_gitignore
fi

echo ""
success "Project apply complete."
echo ""
echo "  Next steps:"
echo "  • Edit $TARGET/AGENTS.md with project-specific commands and cloud VM notes"
echo "  • Commit .cursor/, .agents/, AGENTS.md, and skills-lock.json to git for Cursor Cloud"
echo "  • Re-run with --mode link for local-only symlinks into ~/dotfiles"
echo ""

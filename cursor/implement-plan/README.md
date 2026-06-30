# implement-plan pipeline

Portable Cursor bundle for plan authoring and execution.
Shipped with dotfiles and applied to projects via `scripts/apply-project.sh`.

Primary target project: [project-dewy](https://github.com/dannyirwin/project-dewy).

## What each folder contains

| Path | Purpose |
| --- | --- |
| `skills/implement-plan/` | Orchestrator skill: parse plan phases, spawn implementers, run verifier, fix loop, PR summary |
| `skills/code-review/` | Diff review skill invoked by `plan-verifier` |
| `agents/` | `plan-phase-implementer` and `plan-verifier` subagent prompts |
| `hooks/` | Plan Mode mirror hook (`hooks.json` + `sync-plan-to-workspace.sh`) |
| `plans/` | Workspace plans README |

## Pipeline flow

1. **Author** a plan in Cursor Plan Mode (or write a `.md` file with `## Phase` sections and `## Acceptance criteria`).
2. **Mirror** (optional): with the hook installed, writes under `~/.cursor/plans/` copy into `<repo>/.cursor/plans/`.
3. **Execute**: invoke `/implement-plan` on the plan file path.
4. **Verify**: `plan-verifier` output goes into the PR description.

## Deploy into a project

```bash
cd ~/dotfiles
bash scripts/apply-project.sh ~/src/project-dewy
```

That copies this bundle into `<repo>/.cursor/`, merges `hooks.json`, vendors
shared agent files under `<repo>/.agents/`, and writes a starter `AGENTS.md`
when the project does not have one.

Then edit the project's `AGENTS.md ## Project` section with build commands,
env vars, and architecture notes.

## Deploy user-global (all projects)

```bash
DOTFILES=~/dotfiles/cursor/implement-plan

mkdir -p ~/.cursor/{skills,agents}
cp -R "$DOTFILES"/skills/* ~/.cursor/skills/
cp "$DOTFILES"/agents/*.md ~/.cursor/agents/
```

Project `.cursor/agents/` overrides `~/.cursor/agents/` when names match.

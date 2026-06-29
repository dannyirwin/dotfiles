# implement-plan pipeline

Verbatim archive of the Cursor `/implement-plan` workflow copied from the CONQR
repo (`.cursor/`) on 2026-06-29.
The CONQR project was not modified when this archive was created.

## What each folder contains

| Path | Purpose |
| --- | --- |
| `skills/implement-plan/` | Orchestrator skill: parse plan phases, spawn implementers, run verifier, fix loop, PR summary |
| `skills/code-review/` | Diff review skill invoked by `plan-verifier` |
| `agents/` | `plan-phase-implementer` and `plan-verifier` subagent prompts |
| `hooks/` | Plan Mode mirror hook (`hooks.json` + `sync-plan-to-workspace.sh`) |
| `plans/` | Workspace plans README and example epic handoff prompt |
| `docs/` | Workflow and agent-config architecture notes from Plan Mode sessions |

## Pipeline flow

1. **Author** a plan in Cursor Plan Mode (or write a `.md` file with `## Phase` sections and `## Acceptance criteria`).
2. **Mirror** (optional): with the hook installed, writes under `~/.cursor/plans/` copy into `<repo>/.cursor/plans/`.
3. **Execute**: invoke `/implement-plan` on the plan file path.
4. **Verify**: `plan-verifier` output goes into the PR description.

## Deploy into a project

Copy (or symlink) into the target repo's `.cursor/` tree:

```bash
DOTFILES=~/dotfiles/cursor/implement-plan
REPO=.cursor   # at repo root

mkdir -p "$REPO"/{skills,agents,hooks,plans}
cp -R "$DOTFILES"/skills/* "$REPO"/skills/
cp "$DOTFILES"/agents/*.md "$REPO"/agents/
cp "$DOTFILES"/hooks/sync-plan-to-workspace.sh "$REPO"/hooks/
mkdir -p "$REPO"/plans
```

Merge `hooks/hooks.json` into the project's `.cursor/hooks.json` (or copy if none exists).

## Deploy user-global (all projects)

```bash
DOTFILES=~/dotfiles/cursor/implement-plan

mkdir -p ~/.cursor/{skills,agents}
cp -R "$DOTFILES"/skills/* ~/.cursor/skills/
cp "$DOTFILES"/agents/*.md ~/.cursor/agents/
```

Project `.cursor/agents/` overrides `~/.cursor/agents/` when names match.

## Source paths

| Archive file | Original source |
| --- | --- |
| `skills/*`, `agents/*`, `hooks/*`, `plans/*` (except handoff) | `conqr/.cursor/` |
| `plans/postgis_h3_handoff_prompt.md` | `conqr/.cursor/plans/` |
| `docs/planning_workflow_audit.plan.md` | `~/.cursor/plans/planning_workflow_audit_edfe4015.plan.md` |
| `docs/agent_config_architecture.plan.md` | `~/.cursor/plans/agent_config_architecture_1ad4c5c8.plan.md` |

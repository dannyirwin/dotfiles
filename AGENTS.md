<!-- dotfiles:shared-agents -->

# Agent instructions

These are common instructions for Danny's agents across all scenarios.

## General Guidelines

- Never use the em dash (—).
  Use a plain hyphen (-) instead.
- When writing commit messages, never auto-add your agent name as co-author.
- Never manually modify CHANGELOG.md files or any files that are marked as
  auto-generated.
- When writing or substantially editing long Markdown files, put each full
  sentence on its own line.
  Preserve normal Markdown structure, but avoid wrapping multiple sentences
  onto one physical line.
- When making technical decisions, do not give much weight to development cost.
  Instead, prefer quality, simplicity, robustness, scalability, and long-term
  maintainability.
- When doing bug fixes, always start by reproducing the bug in an E2E setting
  that matches how an end user would interact.
  This makes sure you find the real problem so your fix will actually solve it.
- When end-to-end testing a product, be picky about the UI you see and be
  obsessed with pixel perfection.
  If something clearly looks off, even if it is not directly related to what you
  are doing, try to get it fixed along the way.
- Apply the same high standard to engineering excellence: lint, test failures,
  and test flakiness.
  If you see one, even if it is not caused by what you are working on right now,
  still get it fixed.

## Danny's Opinions

When work would benefit from Danny's taste or beliefs, read `.agents/OPINIONS.md`.
Start with the engineering and tooling sections; treat empty sections as unsettled.

## Project

This repo is the **source** for personal dotfiles and portable agent bundles.
It is not an application monorepo.

### Install and apply

```bash
# Global machine setup (laptop)
bash install.sh --profile full

# Copy agent/Cursor config into another repo (local + Cursor Cloud)
bash scripts/apply-project.sh ~/src/project-dewy
```

### Cursor Cloud

Cloud VMs do not have `~/.agents` symlinks.
Use the committed `.agents/` directory and `.cursor/` bundle in this repo.
Edit `AGENTS.md` (this file) for repo-specific notes; edit `.agents/AGENTS.md` for
personal rules that should propagate to all projects via `apply-project.sh`.

### Agent bundles

Portable Cursor bundles live under `cursor/` (default: `cursor/implement-plan/`).
Subagent prompts under `.cursor/agents/` are templates - customize per target
project after `apply-project.sh`, especially the Conventions section.

### Lint and test

Run shellcheck on changed shell scripts when editing install/apply tooling.
No application test suite in this repo.

### Plan workflow

- Author plans in Cursor Plan Mode (hook mirrors to `.cursor/plans/` when installed).
- Execute with `/implement-plan` on a plan file path.
- Bundles and subagents ship from `cursor/implement-plan/`; customize after apply.

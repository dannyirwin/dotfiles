# PostGIS + H3 Migration — Handoff Prompt

Use this when starting work on **one slice** of the territory migration. Each slice gets its **own new plan file** (phases + files + acceptance criteria), then `/implement-plan` on that file — **not** on the epic roadmap directly.

---

## Copy-paste handoff (fill in `[PR_N]` and `[SLUG]`)

```
Implement slice **[PR_N]** of the CONQR PostGIS + H3 territory migration.

## Context (read first)
- Epic roadmap: `.cursor/plans/postgis_h3_territory_migration_c2d1af1e.plan.md`
- Game mechanics audit: `.cursor/plans/game_mechanics_audit_bb7fc98e.plan.md`
- H3 technical spec (PR5–7): `.cursor/plans/h3_defense_technical_spec_c2d1af1e.plan.md`
- Handoff index: `.cursor/plans/postgis_h3_handoff_prompt.md`
- Implement skill: `.cursor/skills/implement-plan/SKILL.md`

Branch: `chore/postgis-h3-territory-migration-plan` (or a feature branch cut from `develop` for the actual code PR).

## Your task
1. Read the epic section for **[PR_N]** only, plus any referenced spec sections.
2. Create a NEW plan file: `.cursor/plans/pr[N]-[SLUG].plan.md`
   - Use `## Phase N` headings (not PR headings) — the implement-plan skill treats these as phases.
   - Each phase lists specific files it touches and `depends on: Phase N` where needed.
   - Include `## Acceptance criteria` (behavioral + structural; GEOMETRY_BENCH goldens for behavioral PRs).
3. Do NOT implement yet — produce the sub-plan for review, OR if instructed to proceed: run `/implement-plan` on the sub-plan file.

## Locked decisions (do not re-litigate)
- PostGIS for zone geometry; `geometry` / `renderGeometry` column names kept (not `geom`).
- `ST_AsGeoJSON` at API boundary — wire contract unchanged.
- H3 res 11 working default (`GAMEPLAY.territory.h3Resolution`); uniform resolution only (no mixed res in combat table).
- Defense in `zone_defense_cell` child table — not JSON on zone row after PR8.
- Clean-start defense at cutover (geometry preserved; defense layers reset to `defensePoints` baseline).
- GiST index compound `(leagueId, geometry)` on TerritoryZone (PR1).
- Guild additive map: no schema work in this migration; competitive guild layer deferred.

## Out of scope for this slice
- Other PR numbers in the epic unless this slice explicitly depends on them.
- Ballard staging seed (PR9) unless this slice IS PR9.
- Frontend changes unless a slice explicitly requires them (DTO stays stable).
```

---

## Slice index (pick one per session)

| Slice | Slug suggestion | Depends on | Primary spec |
|-------|-----------------|------------|--------------|
| **PR0** | `pr0-foundations-bench-goldens` | — | Epic only |
| **PR1** | `pr1-postgis-territory-zone-geometry` | PR0 | Epic |
| **PR2** | `pr2-postgis-overlap-map-reads` | PR1 | Epic |
| **PR3** | `pr3-postgis-geometry-ops-drop-json` | PR2 | Epic |
| **PR4** | `pr4-postgis-realm-battleground` | PR1 (parallel to PR2–3) | Epic |
| **PR5** | `pr5-h3-defense-model` | PR0 | H3 spec |
| **PR6** | `pr6-h3-combat-write-path` | PR5 (+ PR1 for geometry reads) | H3 spec |
| **PR7** | `pr7-h3-presentation-read-path` | PR6 | H3 spec |
| **PR8** | `pr8-cutover-cleanup-docs` | PR3 + PR7 | Epic + H3 spec |
| **PR9** | `pr9-ballard-staging-seed` | PR3 + PR7 (A+B done) | Epic |

**Workstream order:** PR0 → PR1 → PR2 → PR3 (PostGIS) and PR0 → PR5 → PR6 → PR7 → PR8 (H3). PR4 can run after PR1 in parallel with PR2–3. PR9 last.

---

## Sub-plan template (structure for each new plan file)

```markdown
---
name: PR[N] — [Short title]
overview: One-sentence goal. Link to epic section.
todos:
  - id: phase-1
    content: "Phase 1: ..."
    status: pending
---

# PR[N] — [Title]

Parent epic: [postgis_h3_territory_migration_c2d1af1e.plan.md](postgis_h3_territory_migration_c2d1af1e.plan.md)

## Goal
[What this PR delivers when merged]

## Prerequisites
- [ ] PR0 goldens captured (if behavioral)
- [ ] [Other deps]

## Phase 1 — [Name]
**Files:** `path/a.ts`, `path/b.sql`
- Task bullet 1
- Task bullet 2

## Phase 2 — [Name]
**Files:** ...
**depends on:** Phase 1
- ...

## Acceptance criteria
- [ ] ...
- [ ] GEOMETRY_BENCH parity vs PR0 goldens (if applicable)
- [ ] API responses unchanged (field names/types)
- [ ] Tests: ...

## Out of scope
- ...
```

---

## Example: starting PR1

Handoff message:

```
Implement slice PR1 of the CONQR PostGIS + H3 territory migration.

Read `.cursor/plans/postgis_h3_handoff_prompt.md` and the PR1 section of
`.cursor/plans/postgis_h3_territory_migration_c2d1af1e.plan.md`.

Create `.cursor/plans/pr1-postgis-territory-zone-geometry.plan.md` with phases:
1. Migration — PostGIS extension + geometry/renderGeometry columns + compound GiST (leagueId, geometry) + backfill
2. territoryGeoRepository.ts — raw SQL read/write, ST_AsGeoJSON on read
3. Wire claimZones + zone persist paths to write PostGIS only (JSON columns unused, not dual-written)
4. Tests + bench smoke

Then run `/implement-plan` on that sub-plan.
```

---

## Verification checklist (every code slice)

- [ ] `pnpm --filter @conqr/backend test` (unit tests for touched modules)
- [ ] GEOMETRY_BENCH scenarios pass (behavioral PRs)
- [ ] No new hardcoded H3 resolution outside config (H3 slices)
- [ ] `code-review` + `strict-app-wide-review` on the PR diff (PR3, PR6, PR7 especially)
- [ ] Docs impact review if PR8 or behavior-visible changes

---

## Key code anchors (current system)

| Concern | Location |
|---------|----------|
| Claim / combat | `packages/backend/src/services/territoryService.ts` |
| Square density grid | `packages/backend/src/utils/spatialDefense.ts` |
| Truth vs render geometry | `packages/backend/src/utils/zoneRenderGeometry.ts` |
| League map | `packages/backend/src/routes/leagues.ts` |
| Territory API | `packages/backend/src/routes/territory.ts` |
| Config | `packages/backend/src/config/gameplay.ts` |
| Schema | `packages/backend/prisma/schema.prisma` (~TerritoryZone) |

**Truth `geometry`** = gameplay. **`renderGeometry`** = map display (smoothed, battleground-clipped). API `geometry` field usually sends render shape.

---
phase: 09-marketplace-wiring-and-end-to-end-validation
plan: 01
subsystem: infra
tags: [marketplace, plugin, claude-plugin, strip_cue, makefile, skill]

# Dependency graph
requires:
  - phase: 06-plugin-scaffold-and-path-migration
    provides: SKILL.md with $CLAUDE_PLUGIN_ROOT/socrates/ path pattern (now corrected to $CLAUDE_PLUGIN_ROOT/)
  - phase: 07-pre-built-protocol-files
    provides: strip_cue.py build pipeline and Makefile build/check targets (now extended for governance/)
provides:
  - .claude-plugin/marketplace.json — repo-root marketplace catalog with socrates-skill entry at ./socrates
  - socrates/.claude-plugin/plugin.json with version removed — marketplace.json is sole version authority
  - socrates/governance/recording.opt.cue — pre-built recording schema generated via strip_cue.py
  - scripts/strip_cue.py FILE_MAP extended to 16 entries (15 protocols + 1 governance)
  - Makefile check/clean extended to validate socrates/governance/ alongside socrates/protocols/
  - SKILL.md path prefix bug fixed — zero $CLAUDE_PLUGIN_ROOT/socrates/ references remain
affects:
  - phase 09 plan 02 — E2E GitHub install validation (depends on all outputs from this plan)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Marketplace-as-repo: .claude-plugin/marketplace.json at root points to plugin subdirectory via relative source path"
    - "Version authority separation: version in marketplace.json only, not plugin.json"
    - "Governance directory pattern: socrates/governance/ for pre-built non-protocol files (recording schema)"
    - "$CLAUDE_PLUGIN_ROOT resolves to plugin root (socrates/) after marketplace install — no segment duplication in paths"

key-files:
  created:
    - .claude-plugin/marketplace.json
    - socrates/governance/recording.opt.cue
  modified:
    - socrates/.claude-plugin/plugin.json
    - scripts/strip_cue.py
    - Makefile
    - socrates/skills/socrates/SKILL.md

key-decisions:
  - "Marketplace catalog at .claude-plugin/marketplace.json with source: ./socrates — single-repo layout, git-only distribution"
  - "version field removed from plugin.json — marketplace.json is sole version authority (per official docs for relative-path plugins)"
  - "recording.opt.cue placed in socrates/governance/ (separate from protocols/) — preserves logical grouping for governance files"
  - "$CLAUDE_PLUGIN_ROOT in SKILL.md points directly to plugin root after install — /socrates/ segment must not appear in paths"
  - "21 protocol paths + 2 recording governance paths corrected (23 total path changes in SKILL.md)"

patterns-established:
  - "Build pipeline extends naturally: add FILE_MAP entry, run make build, commit generated file"
  - "Makefile check validates all generated files via git diff --exit-code — idempotent verification"

requirements-completed: [PLUG-01, PLUG-02]

# Metrics
duration: 2min
completed: 2026-03-02
---

# Phase 9 Plan 1: Marketplace Wiring and Build Pipeline Extension Summary

**Marketplace catalog created with socrates-skill plugin entry, recording.opt.cue pre-built via extended strip_cue.py, and SKILL.md $CLAUDE_PLUGIN_ROOT path prefix corrected for marketplace install compatibility**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-03-02T01:09:27Z
- **Completed:** 2026-03-02T01:11:31Z
- **Tasks:** 2
- **Files modified:** 6 (1 new directory, 2 new files, 4 modified)

## Accomplishments
- Created `.claude-plugin/marketplace.json` at repo root making `zetaminusone/socrates` a discoverable marketplace with socrates-skill at `./socrates`
- Removed version from `plugin.json` — version authority consolidated to marketplace.json only
- Extended `strip_cue.py` FILE_MAP and Makefile to include `governance/recording.opt.cue` — `make build` now generates 16 files, `make check` validates all 16
- Fixed critical path prefix bug in SKILL.md: replaced all 23 `$CLAUDE_PLUGIN_ROOT/socrates/` occurrences with correct paths (`$CLAUDE_PLUGIN_ROOT/protocols/` for 21 protocol paths, `$CLAUDE_PLUGIN_ROOT/governance/recording.opt.cue` for 2 recording references)

## Task Commits

Each task was committed atomically:

1. **Task 1: Create marketplace.json, fix plugin.json version, extend build pipeline** - `2cd45ec` (feat)
2. **Task 2: Fix SKILL.md $CLAUDE_PLUGIN_ROOT path prefix** - `9a7fe72` (fix)

## Files Created/Modified
- `.claude-plugin/marketplace.json` (new) — Marketplace catalog with socrates-marketplace name, socrates-skill plugin entry, source ./socrates, version 0.1.0
- `socrates/.claude-plugin/plugin.json` — Version field removed; now has name, description, author, homepage, repository, license only
- `scripts/strip_cue.py` — FILE_MAP extended with `("dialectics/governance/recording.cue", "governance/recording.opt.cue")` entry
- `Makefile` — check target: git diff now validates `socrates/governance/` alongside `socrates/protocols/`; clean target: find covers both directories
- `socrates/governance/recording.opt.cue` (new) — Pre-built recording schema (3288 → 1834 chars, 44% reduction, contains #Record)
- `socrates/skills/socrates/SKILL.md` — 23 path references corrected: 21 protocol paths use `$CLAUDE_PLUGIN_ROOT/protocols/`, 2 recording paths use `$CLAUDE_PLUGIN_ROOT/governance/recording.opt.cue`

## Decisions Made
- Placed marketplace.json at `.claude-plugin/marketplace.json` (not repo root directly) — follows Claude marketplace convention for directory-based plugin config
- Created `socrates/governance/` as separate directory from `protocols/` — governance files are not protocol schemas; logical separation maintained
- Used `replace_all` for path substitution — mechanical find-replace with zero semantic content changes; verified by grep count post-edit

## Deviations from Plan

None — plan executed exactly as written.

Note: Plan verification check expected `grep -c 'CLAUDE_PLUGIN_ROOT/protocols/'` to return 22, but actual count is 21. The original SKILL.md had 23 path references total (21 protocol paths + 2 recording governance paths = 23). Phase 6 decision log confirms "24 old refs removed, 23 new refs added." The 21 vs 22 discrepancy is a documentation artifact in the plan — all paths are correctly fixed and the key success criterion (zero `$CLAUDE_PLUGIN_ROOT/socrates/` remaining) is met.

## Issues Encountered
None.

## User Setup Required
None — no external service configuration required.

## Next Phase Readiness
- All infrastructure for E2E validation is in place: marketplace.json, corrected SKILL.md paths, pre-built recording.opt.cue
- Plan 02 can proceed with real GitHub install test: `/plugin marketplace add zetaminusone/socrates` then `/plugin install socrates-skill@socrates-marketplace`
- make check passes and reports 16 files up-to-date — CI-ready

## Self-Check: PASSED

- FOUND: .claude-plugin/marketplace.json
- FOUND: socrates/governance/recording.opt.cue
- FOUND: 09-01-SUMMARY.md
- FOUND commit: 2cd45ec (Task 1)
- FOUND commit: 9a7fe72 (Task 2)

---
*Phase: 09-marketplace-wiring-and-end-to-end-validation*
*Completed: 2026-03-02*

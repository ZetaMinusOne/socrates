---
phase: 06-plugin-scaffold-and-path-migration
plan: 01
subsystem: infra
tags: [claude-plugin, plugin-manifest, skill-directory, gitmodules, path-resolution, CLAUDE_PLUGIN_ROOT]

# Dependency graph
requires:
  - phase: 05-schema-conformance-alignment
    provides: "Stable SKILL.md with correct CUE schema instructions — base content for plugin migration"
provides:
  - "socrates/.claude-plugin/plugin.json manifest with semver version and identity metadata"
  - "SKILL.md at plugin autodiscovery location: socrates/skills/socrates/SKILL.md"
  - ".gitmodules corrected to reference socrates/dialectics submodule path"
  - "Empirical confirmation: $CLAUDE_PLUGIN_ROOT expands correctly in Read tool paths from SKILL.md"
  - "Empirical confirmation: /socrates slash command works (expands to /socrates-skill:socrates)"
affects:
  - 06-02-path-migration
  - 07-pre-built-protocol-files
  - 09-marketplace-wiring

# Tech tracking
tech-stack:
  added: ["Claude Code plugin manifest (plugin.json)", "plugin autodiscovery convention (skills/name/SKILL.md)"]
  patterns: ["Plugin manifest at <root>/.claude-plugin/plugin.json", "Skill at <root>/skills/<name>/SKILL.md", "$CLAUDE_PLUGIN_ROOT prefix for intra-plugin Read paths"]

key-files:
  created:
    - "socrates/.claude-plugin/plugin.json"
    - "socrates/skills/socrates/SKILL.md"
  modified:
    - ".gitmodules"

key-decisions:
  - "$CLAUDE_PLUGIN_ROOT DOES expand in SKILL.md Read tool paths — confirmed empirically with --plugin-dir. Plan 2 will use $CLAUDE_PLUGIN_ROOT/socrates/ as the migration prefix for all 24 hardcoded path references."
  - "/socrates invocation form works after plugin install — displays as /socrates-skill:socrates in autocomplete but /socrates also resolves correctly."
  - "version=0.1.0 included in plugin.json per PLUG-04 requirement — Phase 9 must reconcile with marketplace.json version priority rule."

patterns-established:
  - "Plugin manifest pattern: socrates/.claude-plugin/plugin.json with name, version, description, author, homepage, repository, license"
  - "Skill location pattern: socrates/skills/socrates/SKILL.md (plugin autodiscovery convention)"
  - "Path prefix pattern for Plan 2: $CLAUDE_PLUGIN_ROOT/socrates/protocols/ for protocol files, $CLAUDE_PLUGIN_ROOT/socrates/dialectics/governance/ for recording.cue"

requirements-completed: [PLUG-03, PLUG-04]

# Metrics
duration: ~18min
completed: 2026-03-01
---

# Phase 6 Plan 01: Plugin Scaffold and Path Migration Summary

**Plugin manifest created, SKILL.md moved to autodiscovery location, .gitmodules fixed, and $CLAUDE_PLUGIN_ROOT empirically confirmed to expand in Read tool paths — Plan 2 migration strategy is unblocked**

## Performance

- **Duration:** ~18 min
- **Started:** 2026-03-01T18:37:48Z
- **Completed:** 2026-03-01T18:56:00Z
- **Tasks:** 2 (1 auto + 1 human-verify checkpoint)
- **Files modified:** 3

## Accomplishments

- Created `socrates/.claude-plugin/plugin.json` with full identity metadata (name, version, description, author, homepage, repository, license) satisfying PLUG-03 and PLUG-04
- Moved SKILL.md from `socrates/SKILL.md` to `socrates/skills/socrates/SKILL.md` per plugin autodiscovery convention — all existing frontmatter preserved
- Fixed `.gitmodules` submodule path from `.claude/skills/socrates/dialectics` to `socrates/dialectics` and ran `git submodule sync`
- **Empirically confirmed** (via `--plugin-dir ./socrates` test) that `$CLAUDE_PLUGIN_ROOT` expands correctly in Read tool paths from SKILL.md — Plan 2's migration strategy is now verified before executing the 24-reference migration

## Task Commits

Each task was committed atomically:

1. **Task 1: Create plugin manifest and restructure directory** - `fc425ca` (feat)
2. **Task 2: Test plugin loading and path resolution** - human-verify checkpoint (no code commit — empirical test, findings documented here)

## Empirical Test Findings

These findings from Task 2 are **critical inputs for Plan 2**. Record them here explicitly.

| Question | Finding | Plan 2 Impact |
|----------|---------|---------------|
| Slash command invocation form | `/socrates` works; autocomplete shows `/socrates-skill:socrates` | Both forms are valid; document `/socrates` as the user-facing form |
| Does `$CLAUDE_PLUGIN_ROOT` expand in Read paths? | **YES — confirmed working** | Plan 2 will use `$CLAUDE_PLUGIN_ROOT/socrates/` prefix for all 24 references |
| Preflight behavior with old paths | Preflight fails with file-not-found (expected) | Confirms path migration is required and correctness test is straightforward |

### Plan 2 Migration Strategy (derived from empirical findings)

All 24 occurrences of `.claude/skills/socrates/` in `socrates/skills/socrates/SKILL.md` should be replaced:

- **Protocol files:** `.claude/skills/socrates/protocols/` → `$CLAUDE_PLUGIN_ROOT/socrates/protocols/`
- **Recording.cue:** `.claude/skills/socrates/dialectics/governance/` → `$CLAUDE_PLUGIN_ROOT/socrates/dialectics/governance/`

Verification after migration: preflight reads `$CLAUDE_PLUGIN_ROOT/socrates/protocols/dialectics.opt.cue` without error.

## Files Created/Modified

- `socrates/.claude-plugin/plugin.json` — Plugin manifest with name=socrates-skill, version=0.1.0, and full identity fields
- `socrates/skills/socrates/SKILL.md` — SKILL.md at plugin autodiscovery location (moved from `socrates/SKILL.md`)
- `.gitmodules` — Submodule path corrected from `.claude/skills/socrates/dialectics` to `socrates/dialectics`

## Decisions Made

1. **`$CLAUDE_PLUGIN_ROOT` migration prefix confirmed.** Empirical test showed variable expands correctly in Read tool paths. Plan 2 will use `$CLAUDE_PLUGIN_ROOT/socrates/` as the prefix for all 24 hardcoded path references.

2. **Both invocation forms work.** `/socrates` resolves correctly after plugin install; autocomplete displays it as `/socrates-skill:socrates`. The user-facing docs should use `/socrates`.

3. **`version=0.1.0` included in plugin.json.** Required by PLUG-04 for update detection. Note: STATE.md documents the concern that this may silently override marketplace.json version for relative-path plugins — Phase 9 must reconcile this when adding the marketplace entry.

## Deviations from Plan

**1. [Rule 3 - Blocking] Used filesystem `mv` instead of `git mv` for SKILL.md**
- **Found during:** Task 1
- **Issue:** `git mv socrates/SKILL.md socrates/skills/socrates/SKILL.md` failed — the `socrates/` directory was not yet tracked by git (it appeared as `??` in `git status`)
- **Fix:** Used standard `mv` filesystem command. The file was added as a new tracked file (`A`) in the subsequent commit. History is not preserved for this move, but this is acceptable since the socrates/ directory was entirely untracked at this point.
- **Files modified:** `socrates/skills/socrates/SKILL.md` (staged as new file)
- **Verification:** `git status` confirms file added at new location; old location removed
- **Committed in:** fc425ca (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (Rule 3 - blocking)
**Impact on plan:** Minor workaround — `mv` instead of `git mv` produces identical result since the source file was untracked. No scope creep.

## Issues Encountered

- `git mv` failed because `socrates/SKILL.md` was not yet tracked by git (entire `socrates/` directory was untracked from prior session work). Resolved by using filesystem `mv` with equivalent outcome.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Plan 2 (06-02) is fully unblocked: the path migration strategy is confirmed (`$CLAUDE_PLUGIN_ROOT/socrates/` prefix), the target file location is correct, and the 24-reference count is verified
- Plan 2 should execute `sed`-equivalent string replacement across all 24 occurrences of `.claude/skills/socrates/` in `socrates/skills/socrates/SKILL.md`
- Preflight message should also be updated from "Run: git submodule update --init --recursive" to guidance appropriate for plugin installs
- Phase 9 concern: `plugin.json` version `0.1.0` may silently override `marketplace.json` version — must reconcile when adding marketplace entry

---
*Phase: 06-plugin-scaffold-and-path-migration*
*Completed: 2026-03-01*

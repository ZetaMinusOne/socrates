---
phase: 05-schema-conformance
plan: 01
subsystem: skill-instruction
tags: [skill, cue, schema, enum, structured-output, record]

# Dependency graph
requires:
  - phase: 04-structured-output
    provides: "--structured and --record flag support in SKILL.md"
provides:
  - "Corrected resolution enum values for CDP (close_as_unified) and ATP (close_as_rejected) terminal paths"
  - "Corrected AAP fragility tier labels: structural, significant, moderate, minor"
  - "Corrected instance type reference: #{ACRONYM}Instance pattern with #ADPRecord exception"
  - "ADP --record version fallback: use 'n/a' when no #Protocol type exists"
affects: [skill-invocation, structured-output, record-output]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Schema-directed execution: SKILL.md instructions align exactly with .opt.cue enum values"
    - "General fallback rule for missing schema fields (ADP #Protocol absence pattern)"

key-files:
  created: []
  modified:
    - ".claude/skills/socrates/SKILL.md"

key-decisions:
  - "Use 'n/a' for ADP run_version fallback — honest (no version exists), type-valid (run_version: string has no enum constraint), and self-documenting via notes field"
  - "Add general fallback rule (not ADP-specific) for protocols without #Protocol type — more robust for future protocols"
  - "Keep CBP/HEP/EMP skip-retry resolutions under schema-directed execution (not named explicitly) — only hard-coded skip paths need explicit naming in SKILL.md"
  - "Fixes 4+5 combined into one edit: replacing #ProtocolInstance with #{ACRONYM}Instance pattern and the #ADPRecord exception together"

patterns-established:
  - "When SKILL.md hard-codes enum values that differ per protocol, use inline list format matching the gate fields table style"
  - "Full sweep verification after targeted fixes confirms no secondary mismatches"

requirements-completed: [EXEC-05, OUTP-02, OUTP-03]

# Metrics
duration: 2min
completed: 2026-02-28
---

# Phase 05 Plan 01: Schema Conformance Alignment Summary

**Five targeted enum/type corrections to SKILL.md: CDP/ATP resolution enums, AAP tier labels, #{ACRONYM}Instance type pattern, and ADP version fallback for --record**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-28T19:55:06Z
- **Completed:** 2026-02-28T19:57:00Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- CDP terminal path now uses `close_as_unified` (was incorrectly `reframe_and_close`)
- ATP terminal path now uses `close_as_rejected` (was incorrectly `reframe_and_close`)
- AAP fragility map tier labels corrected to match `#FragilityTier.label` schema: `structural`, `significant`, `moderate`, `minor` (removed `load-bearing` and `background` which are not schema values)
- Instance type reference corrected: `#{ACRONYM}Instance` pattern with explicit `#ADPRecord` exception (replaced non-existent `#ProtocolInstance` generic)
- ADP `--record` version fallback added: use `"n/a"` when protocol has no `#Protocol` type, with `notes` field clarification
- Full sweep of all 13 protocols confirmed zero additional mismatches

## Task Commits

Each task was committed atomically:

1. **Task 1: Apply all 5 schema-instruction fixes to SKILL.md** - `bbd04d9` (fix)
2. **Task 2: Cross-verify all fixes against source CUE schemas** - verification only, no additional changes needed

**Plan metadata:** *(final docs commit below)*

## Files Created/Modified

- `.claude/skills/socrates/SKILL.md` - 4 targeted text edits correcting 5 schema-instruction mismatches (Issues 1-5 from v1.0 audit + full sweep)

## Decisions Made

- Used `"n/a"` for ADP `run_version` fallback — honest, type-valid (`run_version: string` unconstrained), brief. The `notes` field carries the explanatory text.
- Added a general fallback rule rather than an ADP-specific exception — handles any future protocol that also lacks `#Protocol` without requiring another fix.
- Issues 4 and 5 were fixed in a single edit (both affected the structured output section): replaced `#ProtocolInstance` with `#{ACRONYM}Instance` pattern and added the `#ADPRecord` exception together.
- CBP, HEP, and EMP skip-retry resolutions intentionally left under schema-directed execution — per plan pitfall analysis, only the 3 named skip-retry protocols (CFFP/CDP/ATP) needed explicit instruction.

## Deviations from Plan

None — plan executed exactly as written. All 5 fixes applied in Task 1; Task 2 cross-verification confirmed all values correct against source schemas with zero additional mismatches.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

Phase 05 plan 01 is the only plan in this phase. All 5 schema-conformance gaps identified in the v1.0 milestone audit are now resolved:
- SKILL.md instructions produce valid enum values for CDP/ATP terminal paths
- SKILL.md instructions produce valid AAP tier labels in both narrative and structured output
- SKILL.md references correct instance type names for all 13 protocols
- SKILL.md handles ADP `--record` version field gracefully with a type-valid fallback

The Socrates skill is now v1.0-ready: schema-conformant across all 13 protocols and 3 output modes (narrative, --structured, --record).

---
*Phase: 05-schema-conformance*
*Completed: 2026-02-28*

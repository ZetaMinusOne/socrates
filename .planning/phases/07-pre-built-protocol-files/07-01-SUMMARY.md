---
phase: 07-pre-built-protocol-files
plan: 01
subsystem: infra
tags: [git, makefile, python, cue, build-artifacts, plugin-distribution]

# Dependency graph
requires:
  - phase: 06-plugin-scaffold-and-path-migration
    provides: socrates/protocols/ directory structure with 15 .opt.cue files on disk (untracked)
provides:
  - 15 .opt.cue protocol files committed to git under socrates/protocols/
  - Makefile with build, clean, and check targets tracked in git
  - scripts/strip_cue.py tracked as build infrastructure
  - Zero-setup install: consumers get all protocol files without submodule init or build step
affects:
  - phase-08-session-start-hook
  - phase-09-marketplace-listing

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Committed generated files: generated .opt.cue files tracked as first-class repo assets for zero-setup consumer install"
    - "make check staleness detection: regenerate in-place then git diff --exit-code to detect submodule drift"

key-files:
  created:
    - socrates/protocols/dialectics.opt.cue
    - socrates/protocols/routing.opt.cue
    - socrates/protocols/adversarial/atp.opt.cue
    - socrates/protocols/adversarial/cbp.opt.cue
    - socrates/protocols/adversarial/cdp.opt.cue
    - socrates/protocols/adversarial/cffp.opt.cue
    - socrates/protocols/adversarial/emp.opt.cue
    - socrates/protocols/adversarial/hep.opt.cue
    - socrates/protocols/evaluative/aap.opt.cue
    - socrates/protocols/evaluative/cgp.opt.cue
    - socrates/protocols/evaluative/ifa.opt.cue
    - socrates/protocols/evaluative/ovp.opt.cue
    - socrates/protocols/evaluative/ptp.opt.cue
    - socrates/protocols/evaluative/rcp.opt.cue
    - socrates/protocols/exploratory/adp.opt.cue
    - Makefile
    - scripts/strip_cue.py
  modified: []

key-decisions:
  - "All 15 .opt.cue protocol files freshly regenerated via make build before git add — ensures committed files match current dialectics submodule state, not stale from prior session"
  - "make check uses in-place regeneration + git diff --exit-code — deterministic, requires no temp directory, leverages existing strip_cue.py idempotency"
  - "Makefile and scripts/strip_cue.py tracked in same phase as protocol files — build infrastructure must be versioned alongside the artifacts it produces"

patterns-established:
  - "Generated-but-tracked pattern: run generator immediately before git add to ensure freshness, then commit — developer regeneration workflow uses same pattern"
  - "Staleness detection via make check: idempotent regeneration + git diff is authoritative; no custom hash comparison needed"

requirements-completed: [BLDG-01, BLDG-02, BLDG-03]

# Metrics
duration: 5min
completed: 2026-03-01
---

# Phase 7 Plan 01: Pre-Built Protocol Files Summary

**15 stripped .opt.cue protocol files committed to git via make build, with Makefile check target for submodule drift detection, enabling zero-setup plugin install**

## Performance

- **Duration:** 5 min
- **Started:** 2026-03-01T20:43:24Z
- **Completed:** 2026-03-01T20:48:30Z
- **Tasks:** 2
- **Files modified:** 17

## Accomplishments

- All 15 .opt.cue protocol files freshly regenerated from dialectics submodule and committed — consumers get them on plugin install with no build step (BLDG-01, BLDG-02)
- Makefile enhanced with `check` target using idempotent regeneration + `git diff --exit-code` to detect submodule drift (BLDG-03)
- Makefile and `scripts/strip_cue.py` tracked as first-class build infrastructure alongside the protocol files they produce

## Task Commits

Each task was committed atomically:

1. **Task 1: Regenerate and commit all 15 pre-built protocol files** - `de08d8b` (feat)
2. **Task 2: Enhance Makefile with check target and commit build infrastructure** - `0a421aa` (feat)

**Plan metadata:** (docs commit — created below)

## Files Created/Modified

- `socrates/protocols/dialectics.opt.cue` - Stripped kernel primitives (Rebuttal, Challenge, Derivation, ObligationGate, RevisionLoop)
- `socrates/protocols/routing.opt.cue` - Stripped routing logic (structural features, protocol selection)
- `socrates/protocols/adversarial/atp.opt.cue` - Adversarial Truth Protocol
- `socrates/protocols/adversarial/cbp.opt.cue` - Claim-by-Claim Protocol
- `socrates/protocols/adversarial/cdp.opt.cue` - Counterpoint-Driven Protocol
- `socrates/protocols/adversarial/cffp.opt.cue` - Claim-Flaw-Fix Protocol
- `socrates/protocols/adversarial/emp.opt.cue` - Evidence Marshaling Protocol
- `socrates/protocols/adversarial/hep.opt.cue` - Hypothesis Elimination Protocol
- `socrates/protocols/evaluative/aap.opt.cue` - Assumption Audit Protocol
- `socrates/protocols/evaluative/cgp.opt.cue` - Claim-Gap Protocol
- `socrates/protocols/evaluative/ifa.opt.cue` - Inference Failure Analysis
- `socrates/protocols/evaluative/ovp.opt.cue` - Output Validity Protocol
- `socrates/protocols/evaluative/ptp.opt.cue` - Premise-Testing Protocol
- `socrates/protocols/evaluative/rcp.opt.cue` - Reasoning Chain Protocol
- `socrates/protocols/exploratory/adp.opt.cue` - Argument Decomposition Protocol
- `Makefile` - build, clean, check targets for protocol file management
- `scripts/strip_cue.py` - CUE stripping script that reads dialectics submodule and writes .opt.cue files

## Decisions Made

- Freshly ran `make build` immediately before staging — ensures committed files match current submodule HEAD, not stale from a prior session (per research Pitfall 3)
- Used `git add socrates/protocols/` (directory form) rather than glob — correctly captures all 3 subdirectory levels (per research Pitfall 1)
- `make check` uses in-place regeneration + `git diff --exit-code` as the staleness signal — leverages strip_cue.py idempotency, no temp directory needed

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

- macOS `wc -l` output has leading whitespace; inline grep `^15$` in verification script fails — used `tr -d ' '` to trim before comparison. No impact on actual file counts or commits.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Phase 7 complete: all 15 protocol files committed, consumers get zero-setup install, developers have `make build/clean/check` workflow
- Phase 8 (SessionStart hook) can proceed: plugin structure is stable and install-ready
- Known Phase 8 constraints remain (bug #10373: hook doesn't fire on brand new conversations; bug #27145: $CLAUDE_PLUGIN_ROOT unset in hook; bug #16538: additionalContext may not reach Claude from plugin hooks)

---
*Phase: 07-pre-built-protocol-files*
*Completed: 2026-03-01*

## Self-Check: PASSED

- FOUND: socrates/protocols/dialectics.opt.cue
- FOUND: socrates/protocols/routing.opt.cue
- FOUND: Makefile
- FOUND: scripts/strip_cue.py
- FOUND: .planning/phases/07-pre-built-protocol-files/07-01-SUMMARY.md
- FOUND: commit de08d8b (Task 1)
- FOUND: commit 0a421aa (Task 2)
- Verified: git ls-files socrates/protocols/ returns 15

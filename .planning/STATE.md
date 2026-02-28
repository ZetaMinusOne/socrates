# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-28)

**Core value:** Users get rigorous, protocol-driven reasoning on any problem without needing to know which dialectic method to apply
**Current focus:** Phase 3 - Protocol Execution

## Current Position

Phase: 3 of 4 (Protocol Execution)
Plan: 1 of TBD in current phase
Status: In progress — adversarial protocols complete
Last activity: 2026-02-28 — Phase 3 Plan 01 complete

Progress: [████░░░░░░] 40%

## Performance Metrics

**Velocity:**
- Total plans completed: 4
- Average duration: 2.0 min
- Total execution time: 0.13 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01-foundation | 2 | 5 min | 2.5 min |
| 02-routing | 1 | 2 min | 2 min |
| 03-protocol-execution | 1 | 1 min | 1 min |

**Recent Trend:**
- Last 5 plans: 01-01 (2 min), 01-02 (3 min), 02-01 (2 min), 03-01 (1 min)
- Trend: stable

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- Claude interprets CUE schemas directly (no runtime): Simpler distribution, no toolchain dependency
- Git submodule for .cue files: Stays in sync with upstream, no copy drift
- Narrative output by default: More accessible; structured output available via flag for power users
- Auto-routing via governance/routing.cue: Users describe problems, skill handles protocol selection
- Submodule placed inside skill directory (.claude/skills/socrates/dialectics) for self-contained dependency
- Preflight check reads protocols/dialectics.opt.cue to validate both submodule AND stripped file generation
- SKILL.md references .opt.cue paths (not raw dialectics/ paths) — raw files are source-of-truth, opt files for invocation
- Block comment threshold: 3+ consecutive //-only lines = documentation block (stripped); 1-2 lines = semantic field description (preserved)
- Agent instruction sections in adp.cue and rcp.cue classified as block documentation and stripped — they are usage guidance for humans, not execution semantics for Claude
- Protocol full names embedded as lookup table in SKILL.md routing section (not read from .opt.cue files): avoids 13 unnecessary Read calls per invocation
- routing.opt.cue inline comments used as authoritative routing table: SKILL.md directs Claude to read these rather than inlining the mapping (prevents drift with upstream submodule)
- 5 boundary discrimination questions encoded in SKILL.md for OVP/HEP, CBP/CDP, CFFP/PTP, CFFP/CGP, AAP/RCP boundary pairs — applied internally by Claude, never shown to user
- Schema-directed execution in SKILL.md: Claude reads .opt.cue file and follows its type definitions — no hard-coded phase sequences in SKILL.md
- 3 skip-retry diagnoses (construct_incoherent/CFFP, construct_not_decomposable/CDP, transfer_not_viable/ATP) bypass revision loop and close immediately
- Phase 5 gate field names per-protocol: all_provable (CFFP), all_ready (CDP), all_satisfied (CBP/HEP/ATP/EMP)

### Pending Todos

None yet.

### Blockers/Concerns

None — adversarial protocol fidelity concern resolved by schema-directed execution pattern

## Session Continuity

Last session: 2026-02-28
Stopped at: Completed 03-01-PLAN.md — adversarial protocol execution instructions added to SKILL.md
Resume file: .planning/phases/03-protocol-execution/03-02-PLAN.md (evaluative + exploratory execution)

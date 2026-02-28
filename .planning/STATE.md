# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-28)

**Core value:** Users get rigorous, protocol-driven reasoning on any problem without needing to know which dialectic method to apply
**Current focus:** Phase 2 - Routing

## Current Position

Phase: 2 of 4 (Routing)
Plan: 1 of 1 in current phase
Status: Phase complete
Last activity: 2026-02-28 — Completed 02-01-PLAN.md

Progress: [███░░░░░░░] 30%

## Performance Metrics

**Velocity:**
- Total plans completed: 3
- Average duration: 2.3 min
- Total execution time: 0.12 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01-foundation | 2 | 5 min | 2.5 min |
| 02-routing | 1 | 2 min | 2 min |

**Recent Trend:**
- Last 5 plans: 01-01 (2 min), 01-02 (3 min), 02-01 (2 min)
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

### Pending Todos

None yet.

### Blockers/Concerns

- Phase 3: The 6 adversarial protocols have multi-round challenge-rebuttal cycles — review protocol-specific phase structures before building to prevent fidelity drift

## Session Continuity

Last session: 2026-02-28
Stopped at: Completed 02-01-PLAN.md — Phase 2 Routing complete. SKILL.md routing section implemented with structural feature extraction, 5 boundary discrimination questions, all three outcome handlers (routed/ambiguous/unroutable), OVP→HEP composite sequencing, and corrected protocol names. Ready for Phase 3 (execution implementation).
Resume file: None

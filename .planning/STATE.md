# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-01)

**Core value:** Users get rigorous, protocol-driven reasoning on any problem without needing to know which dialectic method to apply
**Current focus:** Milestone v1.1 — Plugin Distribution

## Current Position

Phase: Not started (defining requirements)
Plan: —
Status: Defining requirements
Last activity: 2026-03-01 — Milestone v1.1 started

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- Claude interprets CUE schemas directly (no runtime): Simpler distribution, no toolchain dependency
- Git submodule for .cue files (dev-only): Stays in sync with upstream, no copy drift
- Narrative output by default: More accessible; structured output available via flag for power users
- Auto-routing via governance/routing.cue: Users describe problems, skill handles protocol selection
- Submodule placed inside skill directory (socrates/dialectics) for self-contained dependency
- Preflight check reads protocols/dialectics.opt.cue to validate both submodule AND stripped file generation
- SKILL.md references .opt.cue paths (not raw dialectics/ paths) — raw files are source-of-truth, opt files for invocation
- Block comment threshold: 3+ consecutive //-only lines = documentation block (stripped); 1-2 lines = semantic field description (preserved)
- Protocol full names embedded as lookup table in SKILL.md routing section (not read from .opt.cue files): avoids 13 unnecessary Read calls per invocation
- routing.opt.cue inline comments used as authoritative routing table
- Schema-directed execution in SKILL.md: Claude reads .opt.cue file and follows its type definitions
- Single-repo marketplace: this repo is both plugin and marketplace
- Pre-built protocol files committed to git: repo is always install-ready
- Build step replaces submodule for consumers: they never run submodule init

### Pending Todos

None yet.

### Blockers/Concerns

None.

## Session Continuity

Last session: 2026-03-01
Stopped at: Starting milestone v1.1 — defining requirements
Resume file: None

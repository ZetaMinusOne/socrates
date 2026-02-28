# Phase 1: Foundation - Context

**Gathered:** 2026-02-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Register `/socrates` as a Claude Code slash command, wire the dialectics git submodule, and establish the progressive file structure so all 13 protocol files are loadable on demand. No routing logic, no protocol execution, no output formatting — just the scaffolding.

</domain>

<decisions>
## Implementation Decisions

### Invocation format
- Argument hint: freeform problem description (e.g. `/socrates <describe your problem>`)
- No flags hinted in Phase 1 — flags (`--structured`, `--record`) are Phase 4
- Command name: `/socrates` — standalone, no namespace

### No-argument behavior
- When invoked without arguments: show a brief intro and prompt for input
- Intro is minimal: state what it does ("I apply structured dialectic reasoning to your problem"), ask what they want to reason about
- Do NOT list protocols or categories — keep it simple and inviting

### File organization
- One file per protocol — 13 separate protocol files for maximum granularity
- Only the relevant protocol file(s) are loaded per invocation (progressive disclosure)

### Context budget — CUE optimization
- Priority: execution fidelity — keep everything Claude needs to faithfully execute protocols, including field descriptions, constraints, and phase sequences
- Strip comments, formatting whitespace, and non-essential content — but preserve all structural and semantic content
- Optimized protocol files are pre-generated and committed to repo (no build step, deterministic, reviewable)

### Claude's Discretion
- Skill file location (root vs dedicated directory) — pick based on Claude Code skill conventions
- Routing logic placement (in SKILL.md vs separate file) — pick based on what keeps SKILL.md focused
- Submodule location — pick based on git submodule conventions
- Context budget threshold (hard ceiling vs soft target) — determine based on actual CUE file sizes
- Protocol file format (optimized CUE vs converted Markdown) — determine based on how well Claude can interpret each for execution

</decisions>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 01-foundation*
*Context gathered: 2026-02-28*

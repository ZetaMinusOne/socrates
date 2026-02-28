# Socrates

## What This Is

A Claude Code skill that brings structured dialectic reasoning into Claude via `/socrates`. Users describe a problem, the skill auto-routes it to the appropriate reasoning protocol from the [riverline-labs/dialectics](https://github.com/riverline-labs/dialectics) framework, and Claude executes the protocol — producing a narrative explanation of the reasoning process and conclusion. An optional flag provides raw structured output instead.

## Core Value

Users get rigorous, protocol-driven reasoning on any problem without needing to know which dialectic method to apply — the skill handles routing and execution transparently.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Auto-route problems to the correct dialectic protocol via governance/routing.cue logic
- [ ] Execute all 13 protocols (6 adversarial, 6 evaluative, 1 exploratory) by interpreting their .cue schemas
- [ ] Produce narrative output by default explaining the reasoning process and conclusion
- [ ] Support a structured output flag that returns typed results matching CUE output schemas
- [ ] Reference dialectics .cue files via git submodule from riverline-labs/dialectics
- [ ] Install as a Claude Code custom slash command (`/socrates`)

### Out of Scope

- MCP server packaging — Claude Code skill only for now
- CUE runtime execution — Claude interprets the schemas, no `cue eval` needed
- Claude Desktop support — targeting Claude Code only
- Custom protocol authoring — users consume existing protocols, not create new ones

## Context

- Built on [riverline-labs/dialectics](https://github.com/riverline-labs/dialectics), a formal engine for structured disagreement resolution using CUE schemas
- The dialectics framework defines 13 reasoning protocols across three categories:
  - **Adversarial** (6): CFFP, CDP, CBP, HEP, ATP, EMP — structural reasoning through challenge-rebuttal cycles
  - **Evaluative** (6): AAP, IFA, RCP, CGP, PTP, OVP — validation and judgment
  - **Exploratory** (1): ADP — possibility mapping
- Core mechanics: rebuttal, challenge, derivation, obligation gates, revision loops
- governance/routing.cue handles protocol selection; governance/recording.cue converts runs into queryable records
- The .cue files serve as structured specs that Claude reads and follows — no CUE toolchain required at runtime
- Example runs in the repo demonstrate protocol execution patterns

## Constraints

- **Distribution**: Claude Code custom slash command only — must follow Claude Code skill file conventions
- **CUE files**: Referenced via git submodule, not copied — stays in sync with upstream
- **No runtime deps**: Claude interprets .cue schemas directly; no CUE binary or toolchain required
- **Protocol fidelity**: Output must follow the structure defined in each protocol's CUE schema

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Claude interprets CUE schemas (no runtime) | Simpler distribution, no toolchain dependency, Claude can reason about structured specs | — Pending |
| Git submodule for .cue files | Stays in sync with upstream, no copy drift | — Pending |
| Narrative output by default | More accessible; structured output available via flag for power users | — Pending |
| Auto-routing via governance/routing.cue | Users shouldn't need to know protocol names — describe problem, get reasoning | — Pending |

---
*Last updated: 2026-02-28 after initialization*

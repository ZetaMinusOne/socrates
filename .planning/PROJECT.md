# Socrates

## What This Is

A Claude Code plugin that brings structured dialectic reasoning into Claude via `/socrates`. Users describe a problem, the skill auto-routes it to the appropriate reasoning protocol from the [riverline-labs/dialectics](https://github.com/riverline-labs/dialectics) framework, and Claude executes the protocol — producing a narrative explanation of the reasoning process and conclusion. An optional flag provides raw structured output instead.

## Core Value

Users get rigorous, protocol-driven reasoning on any problem without needing to know which dialectic method to apply — the skill handles routing and execution transparently.

## Current Milestone: v1.1 Plugin Distribution

**Goal:** Make Socrates installable via `/plugin` — single-repo marketplace, pre-built protocol files, zero consumer setup.

**Target features:**
- Plugin manifest and marketplace structure (`.claude-plugin/`)
- Build step that strips CUE files from submodule into committed distribution files
- Session-start hook to inject skill context automatically
- Updated SKILL.md path references for plugin-relative paths
- Cross-platform hook support

## Requirements

### Validated

<!-- Shipped and confirmed valuable — v1.0 -->

- ✓ Auto-route problems to the correct dialectic protocol via governance/routing.cue logic — v1.0
- ✓ Execute all 13 protocols (6 adversarial, 6 evaluative, 1 exploratory) by interpreting their .cue schemas — v1.0
- ✓ Produce narrative output by default explaining the reasoning process and conclusion — v1.0
- ✓ Support a structured output flag that returns typed results matching CUE output schemas — v1.0
- ✓ Support a record flag that returns output formatted as #Record for audit trails — v1.0
- ✓ Reference dialectics .cue files via git submodule from riverline-labs/dialectics — v1.0
- ✓ Register as a Claude Code custom slash command (`/socrates`) — v1.0
- ✓ Protocol .cue files optimized for agent context window (stripped of comments/whitespace) — v1.0
- ✓ Schema-conformant output for all 13 protocols — v1.0

### Active

<!-- Current scope — v1.1 Plugin Distribution -->

- [ ] Installable via `/plugin` with zero consumer setup
- [ ] Pre-built protocol files committed to git (no submodule init for consumers)
- [ ] Session-start hook injects skill context automatically
- [ ] SKILL.md paths work relative to plugin root
- [ ] Cross-platform hook support (macOS/Linux/Windows)

### Out of Scope

- MCP server packaging — plugin distribution is the current focus
- CUE runtime execution — Claude interprets the schemas, no `cue eval` needed
- Claude Desktop support — targeting Claude Code only
- Custom protocol authoring — users consume existing protocols, not create new ones
- Separate marketplace repo — single-repo approach chosen
- CI/release pipeline for builds — pre-built files are committed directly

## Context

- Built on [riverline-labs/dialectics](https://github.com/riverline-labs/dialectics), a formal engine for structured disagreement resolution using CUE schemas
- The dialectics framework defines 13 reasoning protocols across three categories:
  - **Adversarial** (6): CFFP, CDP, CBP, HEP, ATP, EMP — structural reasoning through challenge-rebuttal cycles
  - **Evaluative** (6): AAP, IFA, RCP, CGP, PTP, OVP — validation and judgment
  - **Exploratory** (1): ADP — possibility mapping
- Core mechanics: rebuttal, challenge, derivation, obligation gates, revision loops
- governance/routing.cue handles protocol selection; governance/recording.cue converts runs into queryable records
- The .cue files serve as structured specs that Claude reads and follows — no CUE toolchain required at runtime
- Skill moved from `.claude/skills/socrates/` to `socrates/` at repo root
- Distribution model: `/plugin` pattern (like [obra/superpowers](https://github.com/obra/superpowers)) — `.claude-plugin/` manifest, hooks for session bootstrap, skills directory for SKILL.md

## Constraints

- **Distribution**: Claude Code `/plugin` system — must follow `.claude-plugin/` conventions
- **Build**: Pre-built protocol files committed to git; consumers never run build steps or submodule init
- **No runtime deps**: Claude interprets .cue schemas directly; no CUE binary or toolchain required
- **Protocol fidelity**: Output must follow the structure defined in each protocol's CUE schema
- **Plugin root**: All file references in SKILL.md must work relative to `$CLAUDE_PLUGIN_ROOT`

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Claude interprets CUE schemas (no runtime) | Simpler distribution, no toolchain dependency, Claude can reason about structured specs | ✓ Good |
| Git submodule for .cue files (dev only) | Stays in sync with upstream; consumers get pre-built files | ✓ Good |
| Narrative output by default | More accessible; structured output available via flag for power users | ✓ Good |
| Auto-routing via governance/routing.cue | Users shouldn't need to know protocol names — describe problem, get reasoning | ✓ Good |
| Single-repo marketplace | Simpler distribution; one repo is both plugin and marketplace | — Pending |
| Pre-built files committed to git | Repo is always install-ready; no CI/release required | — Pending |
| Build step replaces submodule for consumers | Consumers don't deal with submodules; build step copies and strips CUE files | — Pending |

---
*Last updated: 2026-03-01 after milestone v1.1 start*

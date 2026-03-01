# Phase 6: Plugin Scaffold and Path Migration - Context

**Gathered:** 2026-03-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Create plugin manifest, restructure directories to match plugin conventions, and migrate all SKILL.md path references from hardcoded `.claude/skills/socrates/` to `$CLAUDE_PLUGIN_ROOT/socrates/`. After this phase, users who install via `--plugin-dir` can invoke `/socrates` and all file reads resolve correctly.

</domain>

<decisions>
## Implementation Decisions

### Plugin identity
- Name: `socrates-skill` (differs from marketplace name `socrates`)
- Version: `0.1.0` (pre-release — fresh distribution channel)
- Description: "Structured dialectic reasoning via 13 protocols. Invoke explicitly with /socrates — never auto-applies to problems."
- Author: `zetaminusone`
- Homepage: `https://zetaminusone.com`
- Repository: `https://github.com/riverline-labs/socrates`
- License: MIT

### Invocation constraint
- The skill must only be invoked when explicitly called via `/socrates` — Claude should never auto-invoke it to help answer questions, even if a problem looks like it could benefit from dialectic reasoning
- `disable-model-invocation: true` already set in SKILL.md frontmatter — preserve this

### Claude's Discretion
- Preflight error messaging — update the "submodule not initialized" message to something appropriate for plugin installs
- Path migration scope — migrate all ~24 `.claude/skills/socrates/` references including `recording.cue` governance path to `$CLAUDE_PLUGIN_ROOT/socrates/`
- Directory restructuring approach — move SKILL.md to `socrates/skills/socrates/SKILL.md` per plugin conventions
- Submodule path handling in `.gitmodules`

</decisions>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches for directory restructuring and path migration.

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Makefile`: build/clean targets already exist for `.opt.cue` generation
- `scripts/strip_cue.py`: generates optimized protocol files from dialectics submodule
- 15 `.opt.cue` files already committed in `socrates/protocols/`

### Established Patterns
- SKILL.md frontmatter: `disable-model-invocation: true`, `allowed-tools: Read`
- Progressive disclosure: protocol files loaded on demand, not inlined
- Path pattern: `.claude/skills/socrates/protocols/{category}/{acronym}.opt.cue` (24 occurrences to migrate)

### Integration Points
- `.gitmodules` references `.claude/skills/socrates/dialectics` — needs path update
- `plugin.json` must go at `socrates/.claude-plugin/plugin.json`
- SKILL.md must move from `socrates/SKILL.md` to `socrates/skills/socrates/SKILL.md`
- `--record` flag reads `dialectics/governance/recording.cue` via old path

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 06-plugin-scaffold-and-path-migration*
*Context gathered: 2026-03-01*

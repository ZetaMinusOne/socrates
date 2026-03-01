# Phase 6: Plugin Scaffold and Path Migration - Context

**Gathered:** 2026-03-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Restructure the Socrates skill from a local `.claude/skills/` installation into a distributable plugin. Create the plugin manifest (`plugin.json`), reorganize the directory to match plugin conventions, and replace all hardcoded `.claude/skills/socrates/` paths in SKILL.md with `$CLAUDE_PLUGIN_ROOT/socrates/`. After this phase, `--plugin-dir ./socrates` installs the skill and all file reads resolve correctly.

</domain>

<decisions>
## Implementation Decisions

### Plugin identity
- Plugin name: `socrates-skill` (distinct from marketplace name `socrates`)
- Author: Riverline Labs
- License: MIT
- Description: reuse the existing SKILL.md description line ("Apply structured dialectic reasoning to any problem...")
- Homepage: GitHub repository URL (riverline-labs/socrates)
- Repository: same GitHub URL

### Preflight messaging
- Replace the current "run git submodule update" error with a reinstall suggestion: "Plugin files missing. Try reinstalling: `/plugin install socrates-skill@socrates`"
- Use `$CLAUDE_PLUGIN_ROOT` paths exclusively — no dual-path fallback for local development (`--plugin-dir` sets this variable)
- Single generic error message (don't distinguish "no plugin root" vs "files missing")
- Keep the hard-stop behavior — if protocol files are missing, stop completely

### Version strategy
- Initial version: `0.1.0` — reserves 1.0.0 for when marketplace install is fully validated (Phase 9)
- Bump version per phase as meaningful increments land (0.1.0 → 0.2.0 → 0.3.0 → 1.0.0)

### Recording.cue path
- Migrate recording.cue path in Phase 6 alongside all other path changes (not deferred to Phase 7)
- Path: `$CLAUDE_PLUGIN_ROOT/socrates/dialectics/governance/recording.cue` — under `socrates/` for consistency with protocol paths
- Only migrate paths that SKILL.md actually reads (protocols + governance) — example runs are not referenced and stay unmigrated

### Claude's Discretion
- Exact plugin.json field ordering and formatting
- Directory restructuring approach (move files vs create new structure)
- SKILL.md frontmatter adjustments for plugin registration
- Any additional plugin.json fields beyond the required set

</decisions>

<specifics>
## Specific Ideas

- Phase 9 success criteria references `$CLAUDE_PLUGIN_ROOT/dialectics/governance/recording.cue` (without `socrates/` segment) — the researcher should verify whether this is the correct convention or if it should be `$CLAUDE_PLUGIN_ROOT/socrates/dialectics/governance/recording.cue` as decided here
- The install command from requirements is `/plugin install socrates-skill@socrates` — plugin name must match this

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `socrates/SKILL.md`: 25KB skill file with ~18 hardcoded `.claude/skills/socrates/` path references (lines 11, 16, 38, 42, 45-65, 69, 180, 221, 237, 302)
- `socrates/protocols/`: 15 pre-built `.opt.cue` files already exist (13 protocols + dialectics + routing)
- `socrates/scripts/strip_cue.py`: Build script for regenerating optimized protocol files
- `socrates/dialectics/`: Git submodule with source CUE schemas

### Established Patterns
- SKILL.md frontmatter uses `name`, `description`, `argument-hint`, `disable-model-invocation`, `allowed-tools` fields
- Progressive disclosure: protocol files loaded on-demand, not all at once
- Preflight pattern: read a sentinel file, hard-stop with error if missing

### Integration Points
- SKILL.md path references: all `.claude/skills/socrates/` occurrences must become `$CLAUDE_PLUGIN_ROOT/socrates/`
- Plugin manifest: `socrates/.claude-plugin/plugin.json` (new file)
- SKILL.md location: must move to `socrates/skills/socrates/SKILL.md` per success criteria
- Submodule at `socrates/dialectics/` stays in place — plugin consumers get pre-built files (Phase 7)

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 06-plugin-scaffold-and-path-migration*
*Context gathered: 2026-03-01*

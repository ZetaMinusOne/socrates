# Phase 9: Marketplace Wiring and End-to-End Validation - Context

**Gathered:** 2026-03-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Create marketplace.json, pre-build recording.cue for distribution, and verify the full GitHub-sourced install-to-use flow works with zero consumer setup. Two commands to install, one command to use.

</domain>

<decisions>
## Implementation Decisions

### Marketplace listing
- Marketplace name: `socrates-marketplace` (distinct from plugin name `socrates-skill` — avoids Pitfall 6 name collision)
- Description (benefit-focused): "Apply rigorous philosophical reasoning to any problem — 13 protocols for stress-testing arguments, auditing assumptions, and mapping possibilities"
- Owner: `zetaminusone`
- Tags: reasoning, dialectics, philosophy
- Include `homepage` and `repository` fields in the marketplace plugin entry for discoverability

### Source strategy
- Relative path `./socrates` — single-repo layout, git-only distribution
- Users add via `/plugin marketplace add zetaminusone/socrates` (NOT `riverline-labs/socrates` — that repo has the upstream dialectics CUE files, not the plugin)
- Users install via `/plugin install socrates-skill@socrates-marketplace`

### Version management
- Version lives in marketplace.json only (per official docs: "For relative-path plugins, set the version in the marketplace entry")
- Remove `version` from plugin.json to prevent silent override
- Initial version: `0.1.0`

### recording.cue distribution
- Pre-build recording.cue via `strip_cue.py` into `socrates/governance/recording.opt.cue` (separate from protocols/ — preserves logical grouping)
- Add to Makefile build pipeline alongside protocol files
- Update SKILL.md path from `$CLAUDE_PLUGIN_ROOT/socrates/dialectics/governance/recording.cue` to `$CLAUDE_PLUGIN_ROOT/socrates/governance/recording.opt.cue`
- `make check` validates all 16 files (15 protocols + 1 governance recording)

### Validation scope
- Happy path E2E: install from GitHub, invoke `/socrates`, get complete narrative response
- Include session hook validation: `/clear` then `/socrates` without manual SKILL.md read
- Real GitHub install against `zetaminusone/socrates` (not local `--plugin-dir` simulation)
- Test problem: "Is the Socratic method still relevant to modern education?"

### Claude's Discretion
- marketplace.json `category` field value (if used)
- Exact `strip_cue.py` modifications for recording.cue processing
- Validation ordering and any intermediate checks before the final E2E gate
- Error message wording if marketplace add or install fails

</decisions>

<specifics>
## Specific Ideas

- Repository is `zetaminusone/socrates`, not `riverline-labs/socrates`. The roadmap success criteria reference `riverline-labs` — this needs correcting.
- The `governance/` directory at plugin root (`socrates/governance/`) is a new directory that doesn't exist yet — created specifically for pre-built governance files that aren't protocol schemas.

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `plugin.json` at `socrates/.claude-plugin/plugin.json` — already has name `socrates-skill`, description, author, homepage, repository, license. Version (`0.1.0`) to be removed.
- `strip_cue.py` at `scripts/strip_cue.py` — existing build pipeline for .opt.cue generation. Needs extension for recording.cue.
- `Makefile` — existing `build` and `check` targets for protocol files. Both need extension for governance/recording.opt.cue.
- Research docs at `.planning/research/ARCHITECTURE.md` — has marketplace.json template and full architecture diagram.

### Established Patterns
- Pre-built files go through `strip_cue.py` and are committed to git (Phase 7 pattern)
- `$CLAUDE_PLUGIN_ROOT/socrates/` prefix for all SKILL.md Read paths (Phase 6 pattern)
- Session hook at `socrates/hooks/` with `hooks.json` + extensionless `session-start` script (Phase 8 pattern)
- `.gitattributes` enforces LF line endings on shell scripts

### Integration Points
- `.claude-plugin/marketplace.json` at repo root (new file) — makes repo a discoverable marketplace
- `socrates/governance/recording.opt.cue` (new file + new directory) — pre-built recording schema
- SKILL.md line 36 — recording.cue path reference needs updating
- Makefile build/check targets — need extension for 16th file

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 09-marketplace-wiring-and-end-to-end-validation*
*Context gathered: 2026-03-01*

# Phase 7: Pre-Built Protocol Files - Context

**Gathered:** 2026-03-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Commit all 15 pre-built `.opt.cue` files to git so consumers who install the plugin get working protocol files without running any build step or submodule init. The build pipeline (`make build` via `strip_cue.py`) must remain functional for developers who update the dialectics submodule.

</domain>

<decisions>
## Implementation Decisions

### Claude's Discretion

User deferred all implementation decisions — this is a straightforward infrastructure phase. Claude has full flexibility on:

- **Staleness protection** — Whether/how to detect when committed `.opt.cue` files are outdated vs the submodule (hash check, make target, or developer discipline)
- **Build verification** — What `make build` validates after regeneration (file count, diff report, size budget)
- **Developer workflow** — How to document the submodule-update-then-rebuild flow
- **Git hygiene** — How to handle generated-but-tracked files (comments, .gitignore adjustments, or keep simple)

</decisions>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches.

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/strip_cue.py`: Fully functional stripping script — reads from `dialectics/` submodule, writes `.opt.cue` to `socrates/protocols/`. Reports sizes and warns on budget violations (16K char limit).
- `Makefile`: Has `build` (runs strip_cue.py) and `clean` (deletes all .opt.cue) targets.

### Established Patterns
- File mapping is hardcoded in `strip_cue.py` FILE_MAP — 15 entries covering 13 protocols + dialectics.opt.cue + routing.opt.cue
- Output preserves directory structure: `adversarial/`, `evaluative/`, `exploratory/` subdirs under `socrates/protocols/`

### Integration Points
- All 15 `.opt.cue` files already exist on disk but are **untracked by git** — core task is `git add` + commit
- SKILL.md (from Phase 6) references these files via `$CLAUDE_PLUGIN_ROOT/socrates/protocols/` paths
- `dialectics/` submodule is the upstream source for regeneration

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 07-pre-built-protocol-files*
*Context gathered: 2026-03-01*

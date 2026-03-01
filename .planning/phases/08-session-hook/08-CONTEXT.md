# Phase 8: Session Hook - Context

**Gathered:** 2026-03-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Cross-platform SessionStart hook that auto-injects Socrates skill context when a user opens, resumes, or clears a Claude Code session. Users never need to manually prime the session — `/socrates` just works. Creating new hook types or modifying skill behavior are separate concerns.

</domain>

<decisions>
## Implementation Decisions

### Injected content scope
- Lightweight primer only — inject the YAML frontmatter extracted from SKILL.md (~200 tokens)
- Full SKILL.md content (~4K tokens) is NOT injected; Claude reads it on-demand when `/socrates` is invoked
- Frontmatter is dynamically extracted at runtime by parsing SKILL.md, not hardcoded in the hook script
- Fixed path: `${CLAUDE_PLUGIN_ROOT}/socrates/skills/socrates/SKILL.md`

### Trigger events
- Matcher pattern: `startup|resume|clear`
- No `compact` — context is already present in the conversation during compaction
- `resume` included to ensure context survives session serialization

### Hook failure behavior
- Silent failure — return empty/no `additionalContext`, session starts normally
- No stderr warnings, no blocking, no error messages from the hook
- No frontmatter validation in the script — if the file exists and has a frontmatter block, return it
- No explicit timeout — rely on Claude Code's built-in hook timeout
- SKILL.md's own preflight check handles real errors when `/socrates` is actually invoked

### Claude's Discretion
- Exact frontmatter parsing approach in the session-start script (sed, awk, or other)
- run-hook.cmd polyglot wrapper implementation details (adopt superpowers pattern)
- .gitattributes line ending enforcement scope and placement
- Hook script structure and error handling internals

</decisions>

<specifics>
## Specific Ideas

- Follow the obra/superpowers reference implementation pattern for run-hook.cmd and hooks.json
- Extensionless `session-start` script (no .sh extension) — required because Claude Code on Windows auto-prepends "bash" to .sh filenames
- The primer should give Claude just enough to know Socrates exists and what it does, nothing more

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `socrates/.claude-plugin/plugin.json`: Plugin manifest already created with name, version, description
- `socrates/skills/socrates/SKILL.md`: 336-line skill file with YAML frontmatter containing name, description, argument-hint, disable-model-invocation
- `socrates/protocols/`: Pre-built .opt.cue files already committed (Phase 7 complete)

### Established Patterns
- `${CLAUDE_PLUGIN_ROOT}` variable used throughout SKILL.md for all file path references
- Plugin structure follows `.claude-plugin/` convention at `socrates/` root
- Skills directory at `socrates/skills/socrates/` (non-default path, plugin.json may need skills field)

### Integration Points
- `socrates/hooks/hooks.json` — new file, wires SessionStart event to hook script
- `socrates/hooks/run-hook.cmd` — new file, polyglot Windows batch/Unix bash wrapper
- `socrates/hooks/session-start` — new file, extensionless bash script that reads and returns frontmatter
- `.gitattributes` — new or updated file, enforces LF line endings on hook scripts

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 08-session-hook*
*Context gathered: 2026-03-01*

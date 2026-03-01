# Phase 6: Plugin Scaffold and Path Migration - Research

**Researched:** 2026-03-01
**Domain:** Claude Code plugin manifest, directory conventions, path resolution in SKILL.md
**Confidence:** HIGH (official docs verified; key pitfall confirmed by open GitHub issues)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Plugin identity:**
- Name: `socrates-skill` (differs from marketplace name `socrates`)
- Version: `0.1.0` (pre-release — fresh distribution channel)
- Description: "Structured dialectic reasoning via 13 protocols. Invoke explicitly with /socrates — never auto-applies to problems."
- Author: `zetaminusone`
- Homepage: `https://zetaminusone.com`
- Repository: `https://github.com/riverline-labs/socrates`
- License: MIT

**Invocation constraint:**
- The skill must only be invoked when explicitly called via `/socrates` — Claude should never auto-invoke it
- `disable-model-invocation: true` already set in SKILL.md frontmatter — preserve this

### Claude's Discretion

- Preflight error messaging — update the "submodule not initialized" message to something appropriate for plugin installs
- Path migration scope — migrate all ~24 `.claude/skills/socrates/` references including `recording.cue` governance path to `$CLAUDE_PLUGIN_ROOT/socrates/`
- Directory restructuring approach — move SKILL.md to `socrates/skills/socrates/SKILL.md` per plugin conventions
- Submodule path handling in `.gitmodules`

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| PLUG-03 | Plugin manifest (plugin.json) includes name, version, description, author, homepage, repository, and license | Official schema documented — all fields confirmed valid |
| PLUG-04 | Plugin version in plugin.json follows semver and enables update detection for cached installations | Semver format confirmed; version priority rule verified |
| PATH-01 | User can invoke `/socrates` after plugin install and all protocol file reads resolve correctly via `$CLAUDE_PLUGIN_ROOT` | Critical: `$CLAUDE_PLUGIN_ROOT` does NOT expand in SKILL.md text — workaround documented |
| PATH-02 | SKILL.md preflight check reads `$CLAUDE_PLUGIN_ROOT/socrates/protocols/dialectics.opt.cue` (not hardcoded `.claude/skills/` path) | Depends on PATH-01 resolution strategy |
| PATH-03 | All ~18 protocol file references in SKILL.md use `$CLAUDE_PLUGIN_ROOT/socrates/protocols/` prefix | 24 occurrences confirmed; migration is mechanical string replacement |
</phase_requirements>

---

## Summary

Phase 6 delivers the plugin scaffold and path migration that transforms the existing `socrates/SKILL.md` into a proper Claude Code plugin. The work has three distinct concerns: (1) creating the `.claude-plugin/plugin.json` manifest with the correct identity, (2) restructuring the directory so SKILL.md lands at `socrates/skills/socrates/SKILL.md` per plugin autodiscovery conventions, and (3) migrating all 24 hardcoded `.claude/skills/socrates/` path references in SKILL.md to plugin-relative paths.

The most significant research finding is a confirmed open bug: `$CLAUDE_PLUGIN_ROOT` does NOT expand inside SKILL.md markdown text when Claude uses the Read tool. This variable works in JSON hook/MCP configurations, but not in the markdown instructions Claude reads as a skill. This is bug #9354, open since October 2025 with no Anthropic fix. The path references in SKILL.md are prose instructions that Claude interprets, not shell variables — which means the substitution mechanism that would resolve `$CLAUDE_PLUGIN_ROOT` at runtime is not applied. The practical consequence is that STATE.md's noted concern (bug #17271 about slash command invocation form) and the path resolution question are both real blockers that require empirical testing with `--plugin-dir` before committing to a migration strategy.

A secondary concern is the version priority rule: official docs confirm that when version is set in BOTH `plugin.json` and a marketplace entry, `plugin.json` always wins silently. STATE.md already captures this as a decision: "Version set only in marketplace.json for relative-path plugins: setting in plugin.json silently overrides." This means for the single-repo marketplace design, the version should go in marketplace.json only, not in plugin.json.

**Primary recommendation:** Test `--plugin-dir ./socrates` immediately before writing any SKILL.md content. Determine empirically whether `$CLAUDE_PLUGIN_ROOT` in a Read instruction resolves to the plugin root, or whether a relative-path approach works, before doing the full 24-reference migration.

---

## Standard Stack

### Core

| Component | Version/Format | Purpose | Why Standard |
|-----------|---------------|---------|--------------|
| `.claude-plugin/plugin.json` | JSON, semver version | Plugin manifest | Required by Claude Code plugin system |
| `socrates/skills/socrates/SKILL.md` | Markdown with YAML frontmatter | Skill entrypoint | Plugin autodiscovery convention |
| `$CLAUDE_PLUGIN_ROOT` | Environment variable | Plugin-root-relative path prefix | Only portable path for installed plugins |

### Supporting

| Tool | Purpose | When to Use |
|------|---------|-------------|
| `claude --plugin-dir ./socrates` | Local plugin testing | Validate all changes before any marketplace work |
| `claude --debug` | Plugin loading diagnostics | Verify manifest parsing, skill registration |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `$CLAUDE_PLUGIN_ROOT` in SKILL.md | Relative paths (`./protocols/`) | Relative paths may work at `--plugin-dir` time but break after cache-copy installation |
| Separate version in plugin.json | Version in marketplace.json only | For relative-path plugins, docs explicitly recommend marketplace.json only |

---

## Architecture Patterns

### Target Plugin Directory Structure

```
socrates/                           # Plugin root (passed to --plugin-dir)
├── .claude-plugin/
│   └── plugin.json                 # Manifest (name, version, description, ...)
├── skills/
│   └── socrates/
│       └── SKILL.md               # Moved from socrates/SKILL.md
├── protocols/                      # Pre-built .opt.cue files (already committed)
│   ├── dialectics.opt.cue
│   ├── routing.opt.cue
│   ├── adversarial/
│   │   ├── atp.opt.cue
│   │   ├── cbp.opt.cue
│   │   ├── cdp.opt.cue
│   │   ├── cffp.opt.cue
│   │   ├── emp.opt.cue
│   │   └── hep.opt.cue
│   ├── evaluative/
│   │   ├── aap.opt.cue
│   │   ├── cgp.opt.cue
│   │   ├── ifa.opt.cue
│   │   ├── ovp.opt.cue
│   │   ├── ptp.opt.cue
│   │   └── rcp.opt.cue
│   └── exploratory/
│       └── adp.opt.cue
└── dialectics/                     # Git submodule (for developer builds)
    └── governance/
        └── recording.cue          # Used by --record flag
```

The skill slash command will be invoked as `/socrates-skill:socrates` after installation, or just `/socrates` depending on how the `name` field in frontmatter interacts with plugin namespacing (see Pitfall 3).

### Pattern 1: plugin.json Manifest

**What:** Metadata file at `socrates/.claude-plugin/plugin.json`
**Required fields:** Only `name` is required if a manifest is present; all others are optional metadata
**Example (target for this phase):**

```json
{
  "name": "socrates-skill",
  "version": "0.1.0",
  "description": "Structured dialectic reasoning via 13 protocols. Invoke explicitly with /socrates — never auto-applies to problems.",
  "author": {
    "name": "zetaminusone"
  },
  "homepage": "https://zetaminusone.com",
  "repository": "https://github.com/riverline-labs/socrates",
  "license": "MIT"
}
```

**Note on version:** For the single-repo marketplace design, version should go in `marketplace.json` (Phase 9), NOT here. Setting version in both causes `plugin.json` to silently override the marketplace version. Either omit `version` from `plugin.json` entirely, or accept that for `--plugin-dir` testing (Phase 6 scope) both are equivalent and the marketplace concern is Phase 9's problem.

Source: https://code.claude.com/docs/en/plugins-reference

### Pattern 2: Path References in SKILL.md

The current SKILL.md has 24 occurrences of `.claude/skills/socrates/` as path prefixes. These need to be migrated to work post-installation.

**What the official docs say:** Use `${CLAUDE_PLUGIN_ROOT}` for all intra-plugin path references in hooks, MCP servers, and scripts. The env variable is set to the absolute path of the plugin directory.

**What the bugs say:** `${CLAUDE_PLUGIN_ROOT}` does NOT expand in SKILL.md markdown text (bug #9354, open since Oct 2025). It only works in JSON configurations. In SKILL.md, Claude reads the text as prose instructions and the variable is not substituted by the Claude Code runtime.

**The migration question** this phase must answer empirically: When SKILL.md contains text like:
```
Read the file at path: `$CLAUDE_PLUGIN_ROOT/socrates/protocols/dialectics.opt.cue`
```

Does Claude receive `$CLAUDE_PLUGIN_ROOT` as a literal string (wrong), or does Claude Code substitute it before Claude sees the text? The bug report shows it is literal when used in Bash commands from skills, but Read tool paths in SKILL.md are conceptually different — they are instructions to Claude, not executed shell commands.

**Working hypothesis (MEDIUM confidence):** Since Claude's Read tool receives the path string from the SKILL.md text, and Claude Code does not preprocess SKILL.md variable substitutions (beyond `$ARGUMENTS`, `$ARGUMENTS[N]`, `$N`, `${CLAUDE_SESSION_ID}`), the literal string `$CLAUDE_PLUGIN_ROOT/socrates/protocols/dialectics.opt.cue` will be passed to the Read tool, which will fail to find the file. Claude would need to understand `$CLAUDE_PLUGIN_ROOT` as a semantic concept, not a shell variable.

**This must be verified with `--plugin-dir` before the 24-reference migration is committed.**

Source: https://github.com/anthropics/claude-code/issues/9354, https://code.claude.com/docs/en/plugins-reference

### Pattern 3: Slash Command Registration

Official docs state plugin skills use `plugin-name:skill-name` namespacing. With `name: socrates-skill` in `plugin.json`, the skill at `skills/socrates/SKILL.md` would register as `/socrates-skill:socrates`.

Bug #17271 (open Feb 2026) complicates this: when a SKILL.md has a `name` field in frontmatter, the plugin prefix may be stripped, leaving just `/socrates`. The existing SKILL.md has `name: socrates` in frontmatter. Whether this produces `/socrates` (desired) or `/socrates-skill:socrates` (undesired but not broken) is empirically uncertain.

**The success criterion** from the phase spec says "the slash command registers correctly under the plugin namespace" — which is satisfied either way as long as `/socrates` works.

### Anti-Patterns to Avoid

- **Hardcoded absolute paths:** Never use `/Users/name/.claude/...` in SKILL.md
- **Putting skills inside `.claude-plugin/`:** Only `plugin.json` goes in `.claude-plugin/`. Skills, commands, hooks at plugin root
- **Setting version in both `plugin.json` and `marketplace.json`:** `plugin.json` silently overrides
- **Assuming `$CLAUDE_PLUGIN_ROOT` expands in SKILL.md:** Unverified — must test first

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| JSON validation for plugin.json | Manual inspection | `claude plugin validate .` or `/plugin validate` | CLI validates schema, catches required fields |
| Discovering all path occurrences | Manual search | `grep -n '\.claude/skills/socrates' SKILL.md` | Deterministic count: 24 occurrences confirmed |

**Key insight:** The plugin manifest schema is minimal — only `name` is required. All other fields (version, description, author, homepage, repository, license) are optional metadata. The manifest cannot break unless the JSON is malformed or `name` is missing.

---

## Common Pitfalls

### Pitfall 1: Version in Both plugin.json and marketplace.json

**What goes wrong:** Developer sets `version: 0.1.0` in `plugin.json` AND in the marketplace entry. The `plugin.json` version silently wins. When the marketplace entry is bumped to `0.1.1`, cached users never see the update because Claude Code compares against `plugin.json`'s `0.1.0`.

**Why it happens:** `plugin.json` is documented as the "authority" in strict mode (default). The marketplace entry supplementing it is not authoritative for version.

**How to avoid:** For relative-path plugins in a single-repo marketplace, set version ONLY in the marketplace entry. Either omit `version` from `plugin.json` entirely, or accept that Phase 6 (which doesn't touch the marketplace yet) can include it and Phase 9 will clean it up.

**Warning signs:** STATE.md already flagged this: "Version set only in marketplace.json for relative-path plugins: setting in plugin.json silently overrides."

Source: https://code.claude.com/docs/en/plugin-marketplaces

### Pitfall 2: $CLAUDE_PLUGIN_ROOT Not Expanding in SKILL.md

**What goes wrong:** All 24 path references are migrated to use `$CLAUDE_PLUGIN_ROOT/socrates/protocols/...` but when Claude executes the skill, the Read tool receives the literal string `$CLAUDE_PLUGIN_ROOT/...` and fails with file-not-found.

**Why it happens:** Claude Code's skill runtime does NOT preprocess `$CLAUDE_PLUGIN_ROOT` in SKILL.md text content. The variable is only expanded in JSON hook/MCP configs. The markdown text is passed verbatim to Claude.

**How to avoid:** Test `--plugin-dir ./socrates` immediately with a single modified path reference BEFORE doing the full migration. Confirm the Read tool either: (a) resolves the path correctly, or (b) fails visibly so an alternative approach can be designed.

**If `$CLAUDE_PLUGIN_ROOT` doesn't work:** The fallback paths to investigate are:
1. Claude interprets the base path injected by the skill runtime (the "base path" mechanism described by Mikhail Shilkov's reverse-engineering) and resolves paths relative to it — this would mean relative paths like `./protocols/dialectics.opt.cue` might work
2. The skill's SKILL.md location gives Claude enough context to resolve relative paths
3. A hook-based approach sets `$CLAUDE_PLUGIN_ROOT` in the environment before the skill runs (Phase 8 hook territory, not Phase 6)

**Warning signs:** If the preflight check (line 11 of current SKILL.md) returns file-not-found after path migration, `$CLAUDE_PLUGIN_ROOT` is not expanding.

Source: https://github.com/anthropics/claude-code/issues/9354

### Pitfall 3: Plugin Slash Command Invocation Form

**What goes wrong:** After installation via `--plugin-dir`, the skill may register as `/socrates-skill:socrates` instead of `/socrates`, or may not appear in autocomplete at all.

**Why it happens:** Bug #17271 (open Feb 2026) documents inconsistent behavior in how plugin name prefixes interact with the `name` field in SKILL.md frontmatter. The existing SKILL.md has `name: socrates` in frontmatter.

**How to avoid:** Test invocation after `--plugin-dir` load. The success criterion is that `/socrates <problem>` routes correctly — not that the autocomplete lists it under a specific form. Document the actual invocation form for users.

**Warning signs:** If `/socrates` returns "command not found" but `/socrates-skill:socrates` works, the user-facing invocation docs need to be updated.

Source: https://github.com/anthropics/claude-code/issues/17271

### Pitfall 4: Directory Structure — Skills Inside .claude-plugin/

**What goes wrong:** Putting `skills/` inside `.claude-plugin/` alongside `plugin.json`. Claude Code only looks for `plugin.json` in `.claude-plugin/`. Skills, commands, hooks must be at the plugin root.

**Why it happens:** The `.claude-plugin/` name suggests it's the Claude configuration directory. It's not — it's only for the manifest.

**How to avoid:** The target structure is `socrates/skills/socrates/SKILL.md`, not `socrates/.claude-plugin/skills/socrates/SKILL.md`.

Source: https://code.claude.com/docs/en/plugins

### Pitfall 5: .gitmodules Path Mismatch

**What goes wrong:** Current `.gitmodules` references `.claude/skills/socrates/dialectics` but the submodule is already physically at `socrates/dialectics`. If `.gitmodules` is not updated, `git submodule update --init` will fail for developers.

**Why it happens:** The submodule was moved from the `.claude/skills/socrates/` location to `socrates/` in a previous phase, but `.gitmodules` still points to the old path.

**How to avoid:** Update `.gitmodules` to:
```
[submodule "socrates/dialectics"]
    path = socrates/dialectics
    url = https://github.com/riverline-labs/dialectics.git
```
And run `git submodule sync` to apply the change.

---

## Code Examples

### plugin.json (verified format from official docs)

```json
{
  "name": "socrates-skill",
  "description": "Structured dialectic reasoning via 13 protocols. Invoke explicitly with /socrates — never auto-applies to problems.",
  "author": {
    "name": "zetaminusone"
  },
  "homepage": "https://zetaminusone.com",
  "repository": "https://github.com/riverline-labs/socrates",
  "license": "MIT"
}
```

Note: `version` is intentionally omitted. It will be set in `marketplace.json` (Phase 9). For `--plugin-dir` testing, no version is needed.

Source: https://code.claude.com/docs/en/plugins-reference#plugin-manifest-schema

### Path Reference Migration (current → target)

All 24 occurrences of `.claude/skills/socrates/` in SKILL.md need replacing. The 24 occurrences break down as:

**Preflight (lines 11, 16):** 2 occurrences — `protocols/dialectics.opt.cue`
**recording.cue (lines 38, 302):** 2 occurrences — `dialectics/governance/recording.cue`
**Protocol files section (lines 42-65):** 14 occurrences — all `protocols/` paths
**Routing section (line 69):** 1 occurrence — `protocols/routing.opt.cue`
**Adversarial execution (line 180):** 1 occurrence — `protocols/adversarial/{acronym}.opt.cue`
**Evaluative execution (line 221):** 1 occurrence — `protocols/evaluative/{acronym}.opt.cue`
**ADP execution (line 237):** 1 occurrence — `protocols/exploratory/adp.opt.cue`
**Record output (line 302):** Already counted above

**Target prefix** (pending empirical verification): `$CLAUDE_PLUGIN_ROOT/socrates/protocols/`
**Target for recording.cue**: `$CLAUDE_PLUGIN_ROOT/socrates/dialectics/governance/recording.cue`

The replacement is a deterministic sed/string-replace operation. The uncertainty is whether `$CLAUDE_PLUGIN_ROOT` will resolve correctly at runtime (see Pitfall 2).

### Testing Plugin Locally

```bash
# Load plugin for this session
claude --plugin-dir ./socrates

# Verify skill appears (check invocation form)
/help

# Test preflight with new path
/socrates test problem

# Debug if not loading
claude --debug --plugin-dir ./socrates
```

Source: https://code.claude.com/docs/en/plugins#test-your-plugins-locally

### .gitmodules Update

Current (wrong — references old location):
```
[submodule ".claude/skills/socrates/dialectics"]
    path = .claude/skills/socrates/dialectics
    url = https://github.com/riverline-labs/dialectics.git
```

Target (correct — references actual location):
```
[submodule "socrates/dialectics"]
    path = socrates/dialectics
    url = https://github.com/riverline-labs/dialectics.git
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `.claude/skills/` for standalone | `<plugin>/skills/<name>/SKILL.md` for plugins | Plugin system release (~Oct 2025) | SKILL.md must move to plugin's skills/ dir |
| `commands/` directory | `skills/` preferred; `commands/` still works | 2.1.3 merge of skills/commands | Skills add supporting file feature; commands still valid |
| No version management | Semver in plugin.json OR marketplace.json | Plugin system release | Must pick one location — both causes silent override |

**Important note about `commands/` vs `skills/`:** The official docs label `commands/` as "legacy" and recommend `skills/` for new skills. A skill at `skills/socrates/SKILL.md` creates `/socrates` (namespaced to `/plugin-name:socrates`). A command at `commands/socrates.md` also creates `/socrates`. For Phase 6, use `skills/` directory as directed by CONTEXT.md.

---

## Open Questions

1. **Does `$CLAUDE_PLUGIN_ROOT` expand in SKILL.md Read-tool paths?**
   - What we know: It does NOT expand when used in Bash commands from skills (bug #9354, open). The only documented SKILL.md substitutions are `$ARGUMENTS`, `$ARGUMENTS[N]`, `$N`, `${CLAUDE_SESSION_ID}`.
   - What's unclear: Whether Claude Code preprocesses SKILL.md text before passing to Claude, or whether Claude is given the literal string and expected to understand `$CLAUDE_PLUGIN_ROOT` as a semantic concept.
   - Recommendation: Make this the FIRST thing tested in Phase 6 execution. Add one `$CLAUDE_PLUGIN_ROOT` path to SKILL.md, run `--plugin-dir`, invoke the skill, observe whether the Read succeeds. If it fails, evaluate relative paths as the fallback strategy.

2. **What is the actual invocation form for `/socrates` after plugin install?**
   - What we know: Bug #17271 (open Feb 2026) shows inconsistency. Plugin skills with `name` in frontmatter may lose the plugin prefix. Socrates SKILL.md has `name: socrates`.
   - What's unclear: Whether `/socrates` or `/socrates-skill:socrates` is the actual invocation form.
   - Recommendation: Test empirically with `--plugin-dir`. Document whatever form works. The success criterion is that the skill executes correctly, not the exact autocomplete representation.

3. **Does `version` belong in plugin.json for Phase 6?**
   - What we know: STATE.md decision says version goes in marketplace.json only (Phase 9). Official docs confirm this is correct for relative-path plugins.
   - What's unclear: Whether omitting `version` from `plugin.json` causes any issue for `--plugin-dir` testing (Phase 6 has no marketplace yet).
   - Recommendation: Omit `version` from `plugin.json`. It will be added to `marketplace.json` in Phase 9. For `--plugin-dir` testing, version is irrelevant.

---

## Validation Architecture

> `workflow.nyquist_validation` is not present in `.planning/config.json` — skipping this section.

---

## Sources

### Primary (HIGH confidence)

- https://code.claude.com/docs/en/plugins-reference — Plugin manifest schema, complete field list, CLAUDE_PLUGIN_ROOT documentation, version management rules
- https://code.claude.com/docs/en/plugins — Plugin creation guide, directory structure, --plugin-dir usage, skills/ vs commands/
- https://code.claude.com/docs/en/plugin-marketplaces — Version priority rules (plugin.json vs marketplace.json), relative-path plugin guidance
- https://code.claude.com/docs/en/skills — SKILL.md frontmatter reference, available string substitutions (confirms CLAUDE_PLUGIN_ROOT NOT listed)

### Secondary (MEDIUM confidence)

- https://github.com/anthropics/claude-code/issues/9354 — Bug: `$CLAUDE_PLUGIN_ROOT` does not expand in command/skill markdown. Open since Oct 2025. 43 upvotes, no Anthropic fix. Community workaround via resolver script.
- https://github.com/anthropics/claude-code/issues/17271 — Bug: Plugin skill slash command invocation form inconsistency. Open Feb 2026.

### Tertiary (LOW confidence)

- https://mikhail.io/2025/10/claude-code-skills/ — Reverse-engineered "base path" mechanism: skill runtime injects base path into skill header, enabling relative path navigation. Not official.

---

## Metadata

**Confidence breakdown:**
- Standard stack (plugin.json format): HIGH — official docs, complete schema documented
- Architecture (directory structure): HIGH — official docs, multiple examples verified
- Path resolution ($CLAUDE_PLUGIN_ROOT in SKILL.md): LOW — known open bug, no official resolution, empirical test required
- Slash command invocation form: LOW — known open bug #17271, empirical test required
- Version placement: HIGH — official docs explicitly warn against setting in both places

**Research date:** 2026-03-01
**Valid until:** 2026-04-01 (Claude Code plugin system is actively evolving; bugs #9354 and #17271 may be fixed)

# Phase 9: Marketplace Wiring and End-to-End Validation - Research

**Researched:** 2026-03-01
**Domain:** Claude Code plugin marketplace distribution and end-to-end validation
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Marketplace listing
- Marketplace name: `socrates-marketplace` (distinct from plugin name `socrates-skill` — avoids Pitfall 6 name collision)
- Description (benefit-focused): "Apply rigorous philosophical reasoning to any problem — 13 protocols for stress-testing arguments, auditing assumptions, and mapping possibilities"
- Owner: `zetaminusone`
- Tags: reasoning, dialectics, philosophy
- Include `homepage` and `repository` fields in the marketplace plugin entry for discoverability

#### Source strategy
- Relative path `./socrates` — single-repo layout, git-only distribution
- Users add via `/plugin marketplace add zetaminusone/socrates` (NOT `riverline-labs/socrates` — that repo has the upstream dialectics CUE files, not the plugin)
- Users install via `/plugin install socrates-skill@socrates-marketplace`

#### Version management
- Version lives in marketplace.json only (per official docs: "For relative-path plugins, set the version in the marketplace entry")
- Remove `version` from plugin.json to prevent silent override
- Initial version: `0.1.0`

#### recording.cue distribution
- Pre-build recording.cue via `strip_cue.py` into `socrates/governance/recording.opt.cue` (separate from protocols/ — preserves logical grouping)
- Add to Makefile build pipeline alongside protocol files
- Update SKILL.md path from `$CLAUDE_PLUGIN_ROOT/socrates/dialectics/governance/recording.cue` to `$CLAUDE_PLUGIN_ROOT/socrates/governance/recording.opt.cue`
- `make check` validates all 16 files (15 protocols + 1 governance recording)

#### Validation scope
- Happy path E2E: install from GitHub, invoke `/socrates`, get complete narrative response
- Include session hook validation: `/clear` then `/socrates` without manual SKILL.md read
- Real GitHub install against `zetaminusone/socrates` (not local `--plugin-dir` simulation)
- Test problem: "Is the Socratic method still relevant to modern education?"

### Claude's Discretion
- marketplace.json `category` field value (if used)
- Exact `strip_cue.py` modifications for recording.cue processing
- Validation ordering and any intermediate checks before the final E2E gate
- Error message wording if marketplace add or install fails

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| PLUG-01 | User can run `/plugin marketplace add riverline-labs/socrates` to register the marketplace (NOTE: corrected to `zetaminusone/socrates` per CONTEXT.md) | marketplace.json schema verified from official docs; single-repo relative-path pattern confirmed; install command form verified |
| PLUG-02 | User can run `/plugin install socrates-skill@socrates-marketplace` to install the plugin from the marketplace | Plugin entry with `name: "socrates-skill"`, marketplace `name: "socrates-marketplace"`, `source: "./socrates"` relative path pattern verified from official docs |
</phase_requirements>

---

## Summary

Phase 9 has three distinct work streams that must complete in order: (1) create `.claude-plugin/marketplace.json` at the repo root making `zetaminusone/socrates` a discoverable marketplace; (2) pre-build `recording.cue` via `strip_cue.py` and create `socrates/governance/recording.opt.cue` so the `--record` flag works without touching the git submodule at install time; and (3) execute a real GitHub-sourced end-to-end validation test confirming the full install-to-use flow.

The critical pre-existing issue that MUST be fixed in this phase: SKILL.md currently uses `$CLAUDE_PLUGIN_ROOT/socrates/protocols/...` paths (23 occurrences), but when installed from the marketplace, `$CLAUDE_PLUGIN_ROOT` resolves to the plugin root directory (`socrates/`) itself — making all those paths read as `socrates/socrates/protocols/...`, which does not exist. The correct paths must be `$CLAUDE_PLUGIN_ROOT/protocols/...`. This is a blocker for E2E validation and must be audited and fixed in this phase.

The good news: the infrastructure is almost complete. The plugin manifest (`plugin.json`) exists with all required fields. The hooks are already wired. The 15 protocol `.opt.cue` files are already pre-built and committed. The remaining work is mechanical: create one new JSON file (marketplace.json), extend strip_cue.py and Makefile for the 16th file, fix the SKILL.md path prefix bug, remove `version` from plugin.json, then run the E2E test.

**Primary recommendation:** Fix the `$CLAUDE_PLUGIN_ROOT/socrates/` path prefix bug in SKILL.md before doing any marketplace testing — that bug will cause the E2E test to fail silently with a misleading preflight error.

---

## Standard Stack

### Core

| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| `.claude-plugin/marketplace.json` (repo root) | N/A | Marketplace catalog; makes repo discoverable via `/plugin marketplace add` | Required location per official Claude Code plugin docs |
| `socrates/.claude-plugin/plugin.json` | Exists | Plugin manifest; identifies plugin name for `/plugin install` resolution | Required for plugin framework discovery; `name` is the only required field |
| `strip_cue.py` | Existing | Pre-build pipeline; strips CUE comments for distribution | Already used for 15 protocol files; extending to 16th is pattern-consistent |
| `Makefile` | Existing | Build/check orchestration | Already wraps strip_cue.py; used by contributors |

### Supporting

| Component | Version | Purpose | When to Use |
|-----------|---------|---------|-------------|
| `socrates/governance/recording.opt.cue` | New file | Pre-built recording schema for `--record` flag | Replaces submodule read at runtime; enables zero-setup install |
| `.gitattributes` | Exists | LF line ending enforcement | Already covers `socrates/hooks/*`; check if `socrates/governance/*` needs adding |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `strip_cue.py` extension | Separate build script for governance files | Adds complexity; reuse existing script is cleaner |
| `source: "./socrates"` (relative path) | `source: { "source": "github", "repo": "zetaminusone/socrates" }` (GitHub source) | Relative path is simpler for single-repo layout; both work — relative requires git-based marketplace add (which is the distribution method) |

---

## Architecture Patterns

### Recommended Project Structure

After Phase 9, the new files and changes are:

```
/                                         # repo root = marketplace
├── .claude-plugin/
│   └── marketplace.json                  # NEW: marketplace catalog
├── socrates/                             # plugin root
│   ├── .claude-plugin/
│   │   └── plugin.json                   # MODIFY: remove "version" field
│   ├── governance/                       # NEW directory
│   │   └── recording.opt.cue             # NEW: pre-built recording schema
│   ├── skills/socrates/SKILL.md          # FIX: path prefix bug ($CLAUDE_PLUGIN_ROOT/socrates/ → $CLAUDE_PLUGIN_ROOT/)
│   └── protocols/                        # UNCHANGED (15 files already committed)
├── scripts/
│   └── strip_cue.py                      # MODIFY: add recording.cue to FILE_MAP
└── Makefile                              # MODIFY: extend build/check targets to 16 files
```

### Pattern 1: marketplace.json Single-Repo Layout

**What:** The repo root acts as both the plugin source and the marketplace catalog. `.claude-plugin/marketplace.json` at the repo root makes the repository a discoverable marketplace. The `plugins` array has one entry pointing to `./socrates` as the plugin source.

**When to use:** Always for single-repo plugin + marketplace distribution.

**Verified marketplace.json schema (official docs):**
```json
{
  "name": "socrates-marketplace",
  "owner": {
    "name": "zetaminusone"
  },
  "plugins": [
    {
      "name": "socrates-skill",
      "source": "./socrates",
      "description": "Apply rigorous philosophical reasoning to any problem — 13 protocols for stress-testing arguments, auditing assumptions, and mapping possibilities",
      "version": "0.1.0",
      "homepage": "https://zetaminusone.com",
      "repository": "https://github.com/zetaminusone/socrates",
      "tags": ["reasoning", "dialectics", "philosophy"]
    }
  ]
}
```

**Install commands (verified):**
```
/plugin marketplace add zetaminusone/socrates
/plugin install socrates-skill@socrates-marketplace
```

**Key constraint:** The `source: "./socrates"` relative path works because users add via GitHub path (`/plugin marketplace add owner/repo`), which triggers a full git clone. If users added via direct URL to `marketplace.json`, relative paths would fail.

### Pattern 2: Version Placement for Relative-Path Plugins

**What:** For plugins with `source: "./relative-path"` in marketplace.json, version must be in marketplace.json only. If `plugin.json` also declares a version, `plugin.json` wins silently — the marketplace version is ignored for update detection.

**Current state:** `socrates/.claude-plugin/plugin.json` has `"version": "0.1.0"`. This field must be REMOVED.

**Action:** Delete the `"version"` key from `plugin.json`. The version in the `plugins[0]` marketplace entry becomes authoritative.

Source: Official docs — "For relative-path plugins, set the version in the marketplace entry."

### Pattern 3: strip_cue.py Extension for recording.cue

**What:** The existing `FILE_MAP` in `strip_cue.py` maps source CUE files to output `.opt.cue` paths. Add one entry for `recording.cue`.

**Current FILE_MAP (15 entries):**
```python
FILE_MAP = [
    ("dialectics/dialectics.cue",  "protocols/dialectics.opt.cue"),
    ("dialectics/governance/routing.cue", "protocols/routing.opt.cue"),
    # ... 13 protocol files
]
```

**New entry to add:**
```python
("dialectics/governance/recording.cue", "governance/recording.opt.cue"),
```

**Why:** The `governance/` output directory is separate from `protocols/` to preserve logical grouping (recording is governance, not a protocol). The script already handles `os.makedirs(os.path.dirname(dst_path), exist_ok=True)` so the new directory is created automatically.

**Makefile extension:** The `check` target currently validates `socrates/protocols/` only:
```makefile
@git diff --exit-code socrates/protocols/ > /dev/null 2>&1 && ...
```
This must be extended to also check `socrates/governance/`:
```makefile
@git diff --exit-code socrates/protocols/ socrates/governance/ > /dev/null 2>&1 && ...
```

### Pattern 4: SKILL.md Path Prefix Fix

**What:** All 23 `$CLAUDE_PLUGIN_ROOT/socrates/` path references in SKILL.md must be changed to `$CLAUDE_PLUGIN_ROOT/`.

**Root cause of the bug:** When installed from the marketplace, `$CLAUDE_PLUGIN_ROOT` is set to the plugin root directory — which IS `socrates/`. So `$CLAUDE_PLUGIN_ROOT/socrates/protocols/` expands to `<cache>/socrates/socrates/protocols/`, a path that doesn't exist.

**Correct expansion at install time:**
- `$CLAUDE_PLUGIN_ROOT` → `~/.claude/plugins/cache/socrates-skill/` (the plugin's cache directory)
- `$CLAUDE_PLUGIN_ROOT/protocols/dialectics.opt.cue` → `~/.claude/plugins/cache/socrates-skill/protocols/dialectics.opt.cue` ✅
- `$CLAUDE_PLUGIN_ROOT/socrates/protocols/dialectics.opt.cue` → `~/.claude/plugins/cache/socrates-skill/socrates/protocols/dialectics.opt.cue` ✅ (works ONLY with --plugin-dir ./socrates because then plugin root IS the parent directory)

**Why it works with `--plugin-dir ./socrates` but not marketplace install:**
- `--plugin-dir ./socrates` sets `$CLAUDE_PLUGIN_ROOT` to the parent of `socrates/` (i.e., the repo root). So `$CLAUDE_PLUGIN_ROOT/socrates/protocols/` expands correctly as `repo-root/socrates/protocols/`.
- Marketplace install sets `$CLAUDE_PLUGIN_ROOT` to the plugin directory itself (`socrates/`). So `$CLAUDE_PLUGIN_ROOT/socrates/protocols/` tries to read `socrates/socrates/protocols/`.

This explains why the Phase 6 empirical test passed with `--plugin-dir` but the paths are wrong for real marketplace install.

**Mechanical substitution:**
```
Old: $CLAUDE_PLUGIN_ROOT/socrates/protocols/
New: $CLAUDE_PLUGIN_ROOT/protocols/

Old: $CLAUDE_PLUGIN_ROOT/socrates/dialectics/governance/recording.cue
New: $CLAUDE_PLUGIN_ROOT/governance/recording.opt.cue
```

The recording.cue reference changes simultaneously with the path prefix fix AND the recording distribution strategy (Phase 9 pre-builds recording.opt.cue into `governance/`).

**Count:** 23 occurrences total in SKILL.md (22 using `socrates/protocols/`, 1 using `socrates/dialectics/governance/`).

### Anti-Patterns to Avoid

- **Leaving `version` in both plugin.json and marketplace.json:** `plugin.json` always wins silently — existing users never receive updates when maintainer bumps only the marketplace version.
- **Testing only with `--plugin-dir ./socrates` and declaring success:** The `--plugin-dir` flag sets `$CLAUDE_PLUGIN_ROOT` differently than a real marketplace install. Paths that work with `--plugin-dir ./socrates` may fail after real installation (confirmed by the path prefix bug described above).
- **Using URL-based marketplace add for relative-path plugins:** `/plugin marketplace add https://raw.githubusercontent.com/...` downloads only the JSON — relative `source` paths fail. Only git-based add (`owner/repo`) clones the full repo.
- **Putting recording.cue inside protocols/:** recording.cue is a governance schema, not a protocol. Keeping it in `governance/` preserves semantic correctness and avoids confusion with the 15 protocol files.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Stripping CUE comments from recording.cue | A separate script for governance files | Extend existing `strip_cue.py` FILE_MAP | Same algorithm; deterministic and idempotent; same 16k char limit |
| Marketplace JSON validation | Manual JSON review | `claude plugin validate .` or `/plugin validate .` | Built-in validation catches schema errors, duplicate names, path traversal |
| Testing the install flow | Simulating with --plugin-dir | Real `/plugin marketplace add` + `/plugin install` against GitHub | --plugin-dir sets $CLAUDE_PLUGIN_ROOT differently; only real install catches path prefix bugs |

**Key insight:** The plugin system's existing tooling handles validation and install. The phase's work is configuration and file creation, not custom infrastructure.

---

## Common Pitfalls

### Pitfall 1: $CLAUDE_PLUGIN_ROOT Path Prefix Bug (Critical)

**What goes wrong:** After real marketplace install, all protocol file reads fail. Preflight fires with "protocol files are missing or unreadable" error. User sees no /socrates functionality.

**Why it happens:** SKILL.md was verified with `--plugin-dir ./socrates` (Phase 6), which sets `$CLAUDE_PLUGIN_ROOT` to the parent of the plugin dir. Marketplace install sets `$CLAUDE_PLUGIN_ROOT` to the plugin dir itself. The extra `/socrates/` in the path only resolves correctly with `--plugin-dir`.

**How to avoid:** Fix all 23 path occurrences in SKILL.md before running E2E test. Verify with: count occurrences of `$CLAUDE_PLUGIN_ROOT/socrates/` — must be 0 after fix.

**Warning signs:** E2E test fails immediately at preflight with "protocol files missing" even though the files are present in the plugin cache.

### Pitfall 2: Marketplace Name vs. Plugin Name Collision

**What goes wrong:** If marketplace `name` equals plugin `name`, Claude Code hits an EXDEV (cross-device link) bug on Linux (#24389). Install fails.

**Why it happens:** The framework uses the marketplace name and plugin name as parts of cache paths. When they collide, a rename/link operation fails.

**How to avoid:** Already handled — marketplace name is `socrates-marketplace`, plugin name is `socrates-skill`. These are distinct.

**Warning signs:** Install succeeds on macOS but fails on Linux.

### Pitfall 3: Silent Version Override

**What goes wrong:** Plugin.json `"version": "0.1.0"` takes precedence over marketplace.json version. Future version bumps in marketplace.json are silently ignored. Users never receive updates.

**Why it happens:** Per official docs, plugin.json always wins when both files declare a version for relative-path plugins.

**How to avoid:** Remove `"version"` from `socrates/.claude-plugin/plugin.json`. Verify with: `grep -c '"version"' socrates/.claude-plugin/plugin.json` → must be 0.

**Warning signs:** After bumping version in marketplace.json, `/plugin update socrates-skill@socrates-marketplace` reports "already up to date."

### Pitfall 4: recording.cue Submodule Not Available After Install

**What goes wrong:** `--record` flag fails silently. Claude tries to read `$CLAUDE_PLUGIN_ROOT/dialectics/governance/recording.cue` but the file is absent or the submodule is not initialized.

**Why it happens:** The git submodule at `socrates/dialectics/` is a gitlink — when the plugin is cloned/copied during install, the submodule directory exists but contains no files (the submodule is not initialized for consumers).

**How to avoid:** Pre-build `recording.opt.cue` via strip_cue.py into `socrates/governance/recording.opt.cue` and commit it. Update SKILL.md to read `$CLAUDE_PLUGIN_ROOT/governance/recording.opt.cue` instead of the submodule path. Verify with: `ls socrates/governance/recording.opt.cue` — file must exist and be committed.

**Warning signs:** `/socrates --record "..."` fails; without `--record`, `/socrates "..."` works fine.

### Pitfall 5: Makefile check Target Missing governance/ Directory

**What goes wrong:** `make check` reports success even if `recording.opt.cue` is stale or missing, because the check only validates `socrates/protocols/`.

**Why it happens:** The `check` target was written before governance/ existed. It uses `git diff --exit-code socrates/protocols/` which ignores `socrates/governance/`.

**How to avoid:** Add `socrates/governance/` to the git diff check: `git diff --exit-code socrates/protocols/ socrates/governance/`.

**Warning signs:** `make check` reports "Protocol files are up to date" while `socrates/governance/recording.opt.cue` is missing or stale.

### Pitfall 6: `source` Path Must Start with `./`

**What goes wrong:** Marketplace.json source `"socrates"` (without `./`) fails validation. Plugin directory not found.

**Why it happens:** Relative path sources must start with `./` per official docs. Bare directory names are not treated as relative paths.

**How to avoid:** Use `"source": "./socrates"` (with `./`). Verify with `claude plugin validate .` in the repo root.

### Pitfall 7: .gitattributes Not Covering New governance/ Directory

**What goes wrong:** On Windows checkouts, `socrates/governance/recording.opt.cue` gets CRLF line endings, which doesn't affect CUE file parsing but is inconsistent with project conventions.

**Why it happens:** `.gitattributes` currently enforces LF on `socrates/hooks/*` but not other subdirectories. CUE files are handled by `* text=auto` but the `governance/` directory was not explicitly covered.

**How to avoid:** CUE files are not shell scripts so CRLF won't cause execution failures — this is low severity. The `* text=auto` rule handles text file normalization. No specific action required unless the project needs strict LF enforcement on .opt.cue files.

---

## Code Examples

Verified patterns from official sources:

### marketplace.json (Complete)

```json
{
  "name": "socrates-marketplace",
  "owner": {
    "name": "zetaminusone"
  },
  "plugins": [
    {
      "name": "socrates-skill",
      "source": "./socrates",
      "description": "Apply rigorous philosophical reasoning to any problem — 13 protocols for stress-testing arguments, auditing assumptions, and mapping possibilities",
      "version": "0.1.0",
      "homepage": "https://zetaminusone.com",
      "repository": "https://github.com/zetaminusone/socrates",
      "tags": ["reasoning", "dialectics", "philosophy"]
    }
  ]
}
```

Source: Official marketplace schema — https://code.claude.com/docs/en/plugin-marketplaces

### plugin.json After Version Removal

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

Note: `"version"` key removed. Marketplace entry is now authoritative for versioning.

### strip_cue.py FILE_MAP Addition

```python
FILE_MAP = [
    ("dialectics/dialectics.cue",                          "protocols/dialectics.opt.cue"),
    ("dialectics/governance/routing.cue",                  "protocols/routing.opt.cue"),
    # --- governance (separate from protocols/) ---
    ("dialectics/governance/recording.cue",                "governance/recording.opt.cue"),
    # ... existing 13 protocol entries unchanged ...
]
```

The `os.makedirs(..., exist_ok=True)` call in `process_file()` already handles creating the new `governance/` output directory automatically.

### Makefile check Target Extension

```makefile
check:
	python3 scripts/strip_cue.py
	@git diff --exit-code socrates/protocols/ socrates/governance/ > /dev/null 2>&1 && echo "Protocol files are up to date." || (echo "Protocol files are stale — run 'make build' and commit the changes."; exit 1)
```

### SKILL.md Path Substitution (Before/After)

Before (23 occurrences, broken for marketplace install):
```
$CLAUDE_PLUGIN_ROOT/socrates/protocols/dialectics.opt.cue
$CLAUDE_PLUGIN_ROOT/socrates/protocols/routing.opt.cue
$CLAUDE_PLUGIN_ROOT/socrates/protocols/adversarial/atp.opt.cue
... (22 total with socrates/protocols/)
$CLAUDE_PLUGIN_ROOT/socrates/dialectics/governance/recording.cue
```

After (correct for marketplace install):
```
$CLAUDE_PLUGIN_ROOT/protocols/dialectics.opt.cue
$CLAUDE_PLUGIN_ROOT/protocols/routing.opt.cue
$CLAUDE_PLUGIN_ROOT/protocols/adversarial/atp.opt.cue
... (22 total with protocols/ only)
$CLAUDE_PLUGIN_ROOT/governance/recording.opt.cue
```

### E2E Validation Sequence

```
# Step 1: Add marketplace (real GitHub)
/plugin marketplace add zetaminusone/socrates

# Step 2: Install plugin
/plugin install socrates-skill@socrates-marketplace

# Step 3: Test basic invocation (new session)
/socrates Is the Socratic method still relevant to modern education?
# Expected: complete narrative response with protocol routing explanation

# Step 4: Test --record flag
/socrates --record Is the Socratic method still relevant to modern education?
# Expected: #Record JSON object with all required fields

# Step 5: Test session hook
/clear
/socrates Is the Socratic method still relevant to modern education?
# Expected: works without manual SKILL.md read (hook fires on /clear)
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `--plugin-dir ./socrates` for testing | Real `/plugin marketplace add` for E2E | Phase 9 | Catches path prefix bugs invisible to --plugin-dir |
| recording.cue read from submodule at runtime | recording.opt.cue pre-built, committed to governance/ | Phase 9 | --record flag works without submodule init |
| Version in plugin.json | Version in marketplace.json only | Phase 9 | Update detection works correctly |
| Paths: `$CLAUDE_PLUGIN_ROOT/socrates/protocols/` | Paths: `$CLAUDE_PLUGIN_ROOT/protocols/` | Phase 9 (fix) | All protocol reads succeed after marketplace install |

**Deprecated/outdated:**
- `$CLAUDE_PLUGIN_ROOT/socrates/dialectics/governance/recording.cue` — replaced by `$CLAUDE_PLUGIN_ROOT/governance/recording.opt.cue`
- `"version": "0.1.0"` in plugin.json — removed; lives in marketplace.json only

---

## Open Questions

1. **Does `keywords` or `tags` field appear in the marketplace plugin entry schema?**
   - What we know: Official docs show `tags` as a valid field in the plugin entry. The `keywords` field is in the plugin.json manifest schema. Both appear in the advanced example.
   - What's unclear: Whether both resolve to the same search index or whether one takes precedence.
   - Recommendation: Use `tags` in the marketplace entry (matches the schema table explicitly). If `keywords` is also desired, it can be added to plugin.json without conflict.

2. **What is the exact cache path for a plugin installed as `socrates-skill@socrates-marketplace`?**
   - What we know: Docs state `~/.claude/plugins/cache/` is the cache root. Cache path likely uses plugin name.
   - What's unclear: Whether cache subdirectory is `socrates-skill`, `socrates-skill@socrates-marketplace`, or something else.
   - Recommendation: Irrelevant to implementation — `$CLAUDE_PLUGIN_ROOT` resolves to the correct cache path regardless. Do not rely on the cache path; use `$CLAUDE_PLUGIN_ROOT` only.

3. **Will the session hook correctly fire on `/clear` given bug #16538?**
   - What we know: Bug #16538 notes `hookSpecificOutput.additionalContext` may not reach Claude from plugin-based hooks. Hooks fire on `/clear` and resume (confirmed Phase 8). Delivery to Claude from plugin context is unverified.
   - What's unclear: Whether the hook output is received by Claude after a real marketplace install (vs. --plugin-dir).
   - Recommendation: Include hook validation in E2E test. If delivery fails, document as known limitation (same as Phase 8 finding for new conversations). Do not block E2E gate on hook delivery — it's a known upstream bug.

4. **Does `make check` handle missing `socrates/governance/` gracefully before first `make build`?**
   - What we know: `git diff --exit-code` on a non-existent path fails with an error rather than a clean exit.
   - What's unclear: Exact git behavior when governance/ doesn't exist yet.
   - Recommendation: Run `make build` before `make check` in the Makefile, or add `|| true` guard for missing directory. Safe approach: the Makefile `check` target already runs `python3 scripts/strip_cue.py` first, which creates the directory and file. So `git diff` will always find the directory.

---

## Sources

### Primary (HIGH confidence)
- https://code.claude.com/docs/en/plugin-marketplaces — marketplace.json full schema, required/optional fields, relative-path plugin notes, version placement warning, install commands
- https://code.claude.com/docs/en/plugins-reference — plugin.json complete schema, `$CLAUDE_PLUGIN_ROOT` variable semantics, file location reference, CLI commands reference, version management warning
- Existing project file: `/Users/javier/projects/socrates/scripts/strip_cue.py` — FILE_MAP structure, BASE_DIR computation, process_file() behavior
- Existing project file: `/Users/javier/projects/socrates/Makefile` — current build/check target structure
- Existing project file: `/Users/javier/projects/socrates/socrates/skills/socrates/SKILL.md` — confirmed 23 occurrences of `$CLAUDE_PLUGIN_ROOT/socrates/` prefix (grep verified)
- Existing project file: `/Users/javier/projects/socrates/socrates/.claude-plugin/plugin.json` — confirmed `"version": "0.1.0"` present, needs removal
- Existing project file: `/Users/javier/projects/socrates/.planning/research/ARCHITECTURE.md` — marketplace.json template and architecture diagrams from earlier research phase

### Secondary (MEDIUM confidence)
- Phase 8 STATE.md findings — `$CLAUDE_PLUGIN_ROOT` unset in hook shell environment (bug #24529); BASH_SOURCE[0] workaround in session-start; hookSpecificOutput delivery unverified (bug #16538)
- Phase 6 STATE.md findings — `$CLAUDE_PLUGIN_ROOT` DOES expand in SKILL.md Read tool paths (verified empirically via `--plugin-dir`); path prefix bug not yet discovered at that time

### Tertiary (LOW confidence)
- None

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — marketplace.json schema and plugin.json schema verified from official Claude Code docs; no library dependencies
- Architecture: HIGH — file structure, path resolution behavior, and $CLAUDE_PLUGIN_ROOT semantics all verified from official docs; path prefix bug derived from documented behavior
- Pitfalls: HIGH (6 of 7) / MEDIUM (1) — most pitfalls are derived from official doc warnings or STATE.md empirical findings; .gitattributes coverage (Pitfall 7) is LOW-impact and LOW-confidence

**Research date:** 2026-03-01
**Valid until:** 2026-04-01 (stable — Claude Code plugin system docs are current; no fast-moving dependencies)

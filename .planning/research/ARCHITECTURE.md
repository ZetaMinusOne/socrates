# Architecture Research

**Domain:** Claude Code plugin distribution — skill packaging with pre-built assets
**Researched:** 2026-03-01
**Confidence:** HIGH (official Claude Code plugin, hooks, skills, and marketplace docs verified from source)

---

## Standard Architecture

### System Overview — Plugin Layer (v1.1 addition)

```
┌────────────────────────────────────────────────────────────────────┐
│                   GitHub Repo (marketplace + plugin)                │
│                                                                      │
│  .claude-plugin/marketplace.json   ← catalog listing socrates        │
│  README.md                         ← install instructions            │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │  socrates/   (plugin root)                                    │   │
│  │                                                               │   │
│  │  .claude-plugin/plugin.json      ← name, version, author     │   │
│  │                                                               │   │
│  │  skills/socrates/SKILL.md        ← entry point (MOVED)       │   │
│  │                                                               │   │
│  │  hooks/hooks.json                ← SessionStart hook config   │   │
│  │  hooks/inject-context.sh         ← context injection script   │   │
│  │                                                               │   │
│  │  protocols/                      ← pre-built distribution     │   │
│  │    dialectics.opt.cue                                         │   │
│  │    routing.opt.cue                                            │   │
│  │    adversarial/{atp,cbp,cdp,cffp,emp,hep}.opt.cue            │   │
│  │    evaluative/{aap,cgp,ifa,ovp,ptp,rcp}.opt.cue              │   │
│  │    exploratory/adp.opt.cue                                    │   │
│  │                                                               │   │
│  │  dialectics/   (git submodule — dev-only, not needed at       │   │
│  │    dialectics.cue               runtime by consumers)         │   │
│  │    governance/routing.cue                                     │   │
│  │    governance/recording.cue                                   │   │
│  │    protocols/**/*.cue                                         │   │
│  │                                                               │   │
│  │  scripts/strip_cue.py            ← build step (maintainer)   │   │
│  └──────────────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────────────┘

Consumer install cache (after /plugin install):
~/.claude/plugins/cache/socrates/
  skills/socrates/SKILL.md           ← paths use $CLAUDE_PLUGIN_ROOT
  protocols/**/*.opt.cue             ← all pre-built files present
  hooks/hooks.json
  hooks/inject-context.sh
  dialectics/governance/recording.cue  ← needed for --record flag
  (dialectics/ rest of submodule also copied, unused)
```

### System Overview — Reasoning Layer (v1.0, unchanged)

```
┌─────────────────────────────────────────────────────────────────────┐
│                      User Interaction Layer                          │
│  User types /socrates [problem description] [--structured] [--record]│
├─────────────────────────────────────────────────────────────────────┤
│                      Skill Entry Point                               │
│  $CLAUDE_PLUGIN_ROOT/skills/socrates/SKILL.md                       │
│  (frontmatter: name, disable-model-invocation: true, allowed-tools) │
├───────────────────┬─────────────────────────────────────────────────┤
│  Routing Layer    │         Protocol Execution Layer                 │
│                   │                                                  │
│  routing.opt.cue  │  protocols/adversarial/   protocols/evaluative/ │
│  (stripped)       │  cffp  cdp  cbp           aap  ifa  rcp         │
│                   │  hep   atp  emp            cgp  ptp  ovp         │
│  Claude reads to  │                                                  │
│  select protocol  │  protocols/exploratory/adp.opt.cue              │
│                   │                                                  │
├───────────────────┴─────────────────────────────────────────────────┤
│                      Recording Layer (--record only)                 │
│  $CLAUDE_PLUGIN_ROOT/dialectics/governance/recording.cue            │
│  (raw .cue — not stripped, loaded only when --record flag present)  │
├─────────────────────────────────────────────────────────────────────┤
│                      Output Layer                                    │
│  Narrative (default): prose explanation of protocol + result        │
│  Structured (--structured): typed output per CUE schema             │
│  Record (--record): #Record compatible with recording.cue           │
└─────────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Status |
|-----------|---------------|--------|
| `.claude-plugin/marketplace.json` (repo root) | Marketplace catalog: lists socrates plugin with `source: "./socrates"`, version, description | New in v1.1 |
| `socrates/.claude-plugin/plugin.json` | Plugin manifest: name, version, author — enables `/plugin install` discovery | New in v1.1 |
| `socrates/skills/socrates/SKILL.md` | Skill definition: frontmatter, preflight, routing instructions, protocol file references via `$CLAUDE_PLUGIN_ROOT` | Moved + modified in v1.1 |
| `socrates/protocols/**/*.opt.cue` | Pre-built distribution files: stripped CUE schemas for runtime reading | Existing, unchanged content |
| `socrates/hooks/hooks.json` | SessionStart hook config pointing to inject-context.sh | New in v1.1 |
| `socrates/hooks/inject-context.sh` | Shell script: outputs `additionalContext` JSON at session start | New in v1.1 |
| `socrates/scripts/strip_cue.py` | Build step: reads `dialectics/` source, writes `protocols/` distribution; maintainer-only | Existing, minor comment update |
| `socrates/dialectics/` | Git submodule: upstream .cue source; dev-only; consumers never initialize it | Existing, unchanged |

---

## Recommended Project Structure

Target layout after v1.1. The repo root acts as the marketplace; `socrates/` is the plugin root.

```
/                                       # repo root = marketplace
├── .claude-plugin/
│   └── marketplace.json                # NEW: marketplace catalog
├── socrates/                           # plugin root (existing dir, restructured)
│   ├── .claude-plugin/
│   │   └── plugin.json                 # NEW: plugin manifest
│   ├── skills/
│   │   └── socrates/
│   │       └── SKILL.md                # MOVED from socrates/SKILL.md
│   │                                   #   + all path references updated
│   ├── protocols/                      # UNCHANGED: pre-built files stay here
│   │   ├── dialectics.opt.cue
│   │   ├── routing.opt.cue
│   │   ├── adversarial/
│   │   │   ├── atp.opt.cue
│   │   │   ├── cbp.opt.cue
│   │   │   ├── cdp.opt.cue
│   │   │   ├── cffp.opt.cue
│   │   │   ├── emp.opt.cue
│   │   │   └── hep.opt.cue
│   │   ├── evaluative/
│   │   │   ├── aap.opt.cue
│   │   │   ├── cgp.opt.cue
│   │   │   ├── ifa.opt.cue
│   │   │   ├── ovp.opt.cue
│   │   │   ├── ptp.opt.cue
│   │   │   └── rcp.opt.cue
│   │   └── exploratory/
│   │       └── adp.opt.cue
│   ├── hooks/                          # NEW: plugin hooks directory
│   │   ├── hooks.json                  # NEW: hook config (SessionStart)
│   │   └── inject-context.sh           # NEW: context injection script
│   ├── scripts/
│   │   └── strip_cue.py                # EXISTING: comment update only
│   └── dialectics/                     # EXISTING: git submodule
│       ├── dialectics.cue
│       ├── governance/
│       │   ├── routing.cue
│       │   └── recording.cue
│       └── protocols/**/*.cue
└── README.md                           # MODIFIED: add /plugin install instructions
```

### Structure Rationale

- **`.claude-plugin/` inside `socrates/`**: The plugin framework looks for `plugin.json` at `<plugin-root>/.claude-plugin/plugin.json`. Only `plugin.json` goes here. All other directories (`skills/`, `hooks/`, `protocols/`, `scripts/`) must be at the plugin root (`socrates/`), not inside `.claude-plugin/`.

- **`.claude-plugin/` at repo root**: The marketplace.json lives here, making the entire repo a discoverable marketplace. This is separate from `socrates/.claude-plugin/plugin.json` — both dirs can coexist.

- **`skills/socrates/SKILL.md`**: Plugin framework auto-discovers skills as `skills/<name>/SKILL.md`. The folder name becomes the skill name, which under a plugin becomes `/socrates` (the plugin name is `socrates`, skill name is `socrates`, combined as `socrates:socrates` — but since plugin name matches skill name, Claude Code may simplify this; verify during testing).

- **`protocols/` stays at plugin root**: All `.opt.cue` files stay in `socrates/protocols/`. The plugin directory is cached wholesale to `~/.claude/plugins/cache/socrates/` on install, so `$CLAUDE_PLUGIN_ROOT/protocols/` resolves correctly without any symlinks.

- **`dialectics/` submodule stays inside `socrates/`**: Consumers never need to initialize this submodule because `protocols/` has all pre-built files. However, the `--record` flag causes SKILL.md to read `$CLAUDE_PLUGIN_ROOT/dialectics/governance/recording.cue`. This raw `.cue` file (not stripped) is inside the submodule. Since the submodule directory is copied into the plugin cache during install (as regular files, not as an active submodule), `recording.cue` will be available. The submodule is NOT excluded from the cache copy — verify this holds true during end-to-end install testing.

- **`hooks/` at plugin root**: Default hook discovery path is `hooks/hooks.json`. No custom path configuration needed.

---

## Architectural Patterns

### Pattern 1: Source vs. Distribution Separation

**What:** Two parallel file trees exist for CUE content. `dialectics/` is the upstream source (annotated, versioned by the riverline-labs/dialectics submodule). `protocols/` is the distribution (stripped, committed, consumer-facing). `scripts/strip_cue.py` is the only bridge — a maintainer-only build step.

**When to use:** Any plugin that ships pre-processed assets to eliminate consumer build steps.

**Trade-offs:**
- Consumers get zero-setup install (correct for a plugin)
- Committed build artifacts can diverge from source if maintainer forgets to rebuild after pulling submodule updates
- Slightly larger repo from duplicate content (acceptable given file sizes)

**Build trigger:** Manual. After pulling submodule updates, maintainer runs:
```bash
cd /repo/socrates
python scripts/strip_cue.py
git add protocols/
git commit -m "rebuild: update stripped protocols from dialectics vX.Y.Z"
```

**Path correctness after restructure:** `strip_cue.py` computes `BASE_DIR = os.path.dirname(SCRIPT_DIR)`. After moving SKILL.md but keeping the script at `socrates/scripts/strip_cue.py`, `SCRIPT_DIR` = `socrates/scripts/` and `BASE_DIR` = `socrates/`. The FILE_MAP entries like `("dialectics/dialectics.cue", "protocols/dialectics.opt.cue")` resolve to `socrates/dialectics/dialectics.cue` → `socrates/protocols/dialectics.opt.cue`. No code changes needed in the script. Only the comment on line 21 (`# Script lives at .claude/skills/socrates/scripts/strip_cue.py`) needs updating.

### Pattern 2: $CLAUDE_PLUGIN_ROOT Path Migration in SKILL.md

**What:** All Read tool path references in SKILL.md must migrate from the v1.0 standalone format to the plugin-relative format using `$CLAUDE_PLUGIN_ROOT`.

**Why:** When Claude Code installs a plugin from the marketplace, it copies the plugin to `~/.claude/plugins/cache/<plugin-name>/`. The old hardcoded path `.claude/skills/socrates/protocols/` no longer exists in the cache. Claude Code resolves `$CLAUDE_PLUGIN_ROOT` to the plugin's actual cache location before executing skill content.

**Migration — exact substitution:**

```
Old (v1.0 standalone):   .claude/skills/socrates/protocols/
New (v1.1 plugin):       $CLAUDE_PLUGIN_ROOT/protocols/

Old (v1.0 standalone):   .claude/skills/socrates/dialectics/governance/recording.cue
New (v1.1 plugin):       $CLAUDE_PLUGIN_ROOT/dialectics/governance/recording.cue
```

**Complete list of affected path occurrences in SKILL.md (~18 total):**

| Line context | Old reference | New reference |
|---|---|---|
| Preflight read instruction | `.claude/skills/socrates/protocols/dialectics.opt.cue` | `$CLAUDE_PLUGIN_ROOT/protocols/dialectics.opt.cue` |
| Preflight error message (2 mentions) | `.claude/skills/socrates/protocols/dialectics.opt.cue` | `$CLAUDE_PLUGIN_ROOT/protocols/dialectics.opt.cue` |
| --record flag conditional read | `.claude/skills/socrates/dialectics/governance/recording.cue` | `$CLAUDE_PLUGIN_ROOT/dialectics/governance/recording.cue` |
| Protocol Files header | `.claude/skills/socrates/protocols/` | `$CLAUDE_PLUGIN_ROOT/protocols/` |
| Kernel: dialectics.opt.cue | `.claude/skills/socrates/protocols/dialectics.opt.cue` | `$CLAUDE_PLUGIN_ROOT/protocols/dialectics.opt.cue` |
| Routing: routing.opt.cue | `.claude/skills/socrates/protocols/routing.opt.cue` | `$CLAUDE_PLUGIN_ROOT/protocols/routing.opt.cue` |
| 6 adversarial protocol paths | `.claude/skills/socrates/protocols/adversarial/<name>.opt.cue` | `$CLAUDE_PLUGIN_ROOT/protocols/adversarial/<name>.opt.cue` |
| 6 evaluative protocol paths | `.claude/skills/socrates/protocols/evaluative/<name>.opt.cue` | `$CLAUDE_PLUGIN_ROOT/protocols/evaluative/<name>.opt.cue` |
| 1 exploratory protocol path | `.claude/skills/socrates/protocols/exploratory/adp.opt.cue` | `$CLAUDE_PLUGIN_ROOT/protocols/exploratory/adp.opt.cue` |
| Routing section read instruction | `.claude/skills/socrates/protocols/routing.opt.cue` | `$CLAUDE_PLUGIN_ROOT/protocols/routing.opt.cue` |

**Preflight error message update:** The current error says "Run: git submodule update --init --recursive". Plugin-installed consumers will never see this error (protocols/ is pre-committed). The error message should be updated to reflect the plugin context: if the file is missing, the plugin installation is corrupted and the user should reinstall.

### Pattern 3: SessionStart Hook for Context Injection

**What:** A `SessionStart` hook fires when Claude Code starts a session. The hook script outputs a JSON object with `hookSpecificOutput.additionalContext` — Claude Code prepends this string to Claude's context before any user interaction.

**When to use:** When the skill should be available without explicit invocation, or when priming Claude's awareness of available tools at session start is valuable. Hooks run outside the context window — zero token overhead.

**Implementation:**

`socrates/hooks/hooks.json`:
```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/inject-context.sh",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

`socrates/hooks/inject-context.sh`:
```bash
#!/usr/bin/env bash
# Inject Socrates context at session start.
# Uses printf for cross-platform JSON output (avoids echo -e portability issues).
printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"The /socrates skill is available for structured dialectic reasoning. Invoke it when facing competing design candidates, argument stress-testing, assumption audits, causal claims, analogy evaluation, formalization, or possibility mapping. Use /socrates --structured for typed output, /socrates --record for audit trail format."}}\n'
```

**Cross-platform requirements:**
- Shebang must be `#!/usr/bin/env bash` (not `/bin/bash`) — `/bin/bash` absent on some systems
- `printf` preferred over `echo` for JSON output — `echo` behavior with escape sequences varies across shells
- `chmod +x inject-context.sh` required — Claude Code will silently skip non-executable hooks
- Use `${CLAUDE_PLUGIN_ROOT}` (with braces) in `hooks.json` command strings — consistent with the plugin framework's variable expansion

**Matcher choice:** `"matcher": "startup"` fires only on new sessions, not on `/resume`, `/clear`, or compaction. This is the right default — no need to re-inject context every time the user clears the conversation. If broader coverage is needed, omit the matcher entirely (fires on all `SessionStart` triggers).

**Trade-offs:**
- Pro: Context available without explicit `/socrates` invocation at session start
- Pro: Zero token overhead (runs as shell command outside context window)
- Con: Fires for all projects where the plugin is enabled — if user-scoped installation, this runs in every session across all projects

### Pattern 4: Single-Repo Marketplace

**What:** The repo root doubles as both the plugin source and the marketplace catalog. `marketplace.json` lives at `/.claude-plugin/marketplace.json` and points to `./socrates` as the plugin source.

**Implementation:**

`.claude-plugin/marketplace.json` (at repo root):
```json
{
  "name": "socrates-marketplace",
  "owner": {
    "name": "riverline-labs"
  },
  "plugins": [
    {
      "name": "socrates",
      "source": "./socrates",
      "description": "Structured dialectic reasoning via /socrates. Auto-routes problems through 13 CUE-schema-defined protocols.",
      "version": "1.1.0",
      "repository": "https://github.com/riverline-labs/socrates"
    }
  ]
}
```

Users install via:
```
/plugin marketplace add riverline-labs/socrates
/plugin install socrates@socrates-marketplace
```

**Critical constraint:** Relative `source` paths only work when the marketplace is added via Git (e.g., `/plugin marketplace add owner/repo`). URL-based marketplace addition (`/plugin marketplace add https://example.com/marketplace.json`) does NOT download plugin files — only the JSON itself. The GitHub path form is the correct distribution approach here.

**Version placement:** Set `version` only in `marketplace.json`, not in `plugin.json`. For relative-path plugins, the docs explicitly warn against setting it in both places — `plugin.json` always wins silently, causing the marketplace version to be ignored by update detection.

---

## Data Flow

### Build Flow (Maintainer Only)

```
riverline-labs/dialectics (upstream GitHub)
    |
    | git submodule update --remote
    v
socrates/dialectics/**/*.cue   (raw annotated source)
    |
    | python socrates/scripts/strip_cue.py
    v
socrates/protocols/**/*.opt.cue  (stripped distribution files)
    |
    | git add protocols/ && git commit
    v
Committed to repo — always install-ready
```

### Consumer Install Flow

```
/plugin marketplace add riverline-labs/socrates
    |
    | Claude Code clones repo
    v
~/.claude/plugins/cache/socrates/
  skills/socrates/SKILL.md
  protocols/**/*.opt.cue
  hooks/hooks.json + inject-context.sh
  dialectics/governance/recording.cue
  (no submodule init needed — files copied as-is)
    |
    | Plugin enabled
    v
hooks registered → SessionStart fires on next session start
/socrates available in slash command menu
```

### Runtime Flow (per /socrates invocation)

```
Session start:
  SessionStart hook → inject-context.sh → additionalContext in Claude's context
      (primes Claude about /socrates availability)

/socrates <problem> [flags]:
    |
    v
SKILL.md loaded from $CLAUDE_PLUGIN_ROOT/skills/socrates/SKILL.md
    |
    v
Preflight: Claude reads $CLAUDE_PLUGIN_ROOT/protocols/dialectics.opt.cue
  (if missing → error message → stop)
    |
    | (if --record flag)
    v
Claude reads $CLAUDE_PLUGIN_ROOT/dialectics/governance/recording.cue
    |
    v
Claude reads $CLAUDE_PLUGIN_ROOT/protocols/routing.opt.cue
  → selects protocol based on structural features
    |
    v
Claude reads $CLAUDE_PLUGIN_ROOT/protocols/<category>/<name>.opt.cue
  → executes selected protocol phases
    |
    v
Output: narrative | structured | record
```

---

## Integration Points

### New Files (Create in v1.1)

| File | Purpose | Notes |
|------|---------|-------|
| `socrates/.claude-plugin/plugin.json` | Plugin manifest | `name`, `version`, `description`, `author` only. No `version` — set in marketplace.json instead |
| `socrates/hooks/hooks.json` | SessionStart hook config | Points to `${CLAUDE_PLUGIN_ROOT}/hooks/inject-context.sh` |
| `socrates/hooks/inject-context.sh` | Context injection script | Must be executable (`chmod +x`); outputs additionalContext JSON |
| `.claude-plugin/marketplace.json` | Marketplace catalog at repo root | `source: "./socrates"` relative path — only works via git-based marketplace add |

### Modified Files (Update in v1.1)

| File | Change Required | Scope |
|------|----------------|-------|
| `socrates/SKILL.md` | **Move** to `socrates/skills/socrates/SKILL.md` AND replace all ~18 path occurrences of `.claude/skills/socrates/` with `$CLAUDE_PLUGIN_ROOT/` — also update preflight error message | High-touch but mechanical |
| `socrates/scripts/strip_cue.py` | Update comment on line 21 from old path to `socrates/scripts/strip_cue.py`. No functional changes. | Trivial |
| `README.md` | Add `/plugin install` instructions, remove or annotate old `.claude/skills/` setup instructions | Documentation only |

### Unchanged (No Action Required)

| File | Status |
|------|--------|
| `socrates/protocols/**/*.opt.cue` (15 files) | Content unchanged — only their reference paths in SKILL.md change |
| `socrates/dialectics/` (submodule) | Unchanged — stays at same location inside plugin root |
| `socrates/scripts/strip_cue.py` (logic) | Path computation works correctly after restructure — BASE_DIR resolves to `socrates/` |

---

## Suggested Build Order for Phases

Four sequential phases with hard dependencies:

```
Phase A — Plugin Manifest + Directory Restructure
  1. Create socrates/.claude-plugin/plugin.json
  2. Create socrates/skills/socrates/ directory
  3. Move socrates/SKILL.md to socrates/skills/socrates/SKILL.md
     (DO NOT update paths yet — verify structure first)
  4. Test: claude --plugin-dir ./socrates
     → /socrates should appear in command list
     → preflight will fail (old paths), confirming structure is wired
  Dependencies: None — first phase

Phase B — Path Migration in SKILL.md
  1. Replace all .claude/skills/socrates/ → $CLAUDE_PLUGIN_ROOT/
     (18 occurrences, mechanical find/replace)
  2. Update preflight error message for plugin context
  3. Test: claude --plugin-dir ./socrates, then /socrates <problem>
     → Full execution must succeed end-to-end
  Dependencies: Phase A complete and plugin loading verified

Phase C — SessionStart Hook
  1. Create socrates/hooks/hooks.json
  2. Create socrates/hooks/inject-context.sh
  3. chmod +x socrates/hooks/inject-context.sh
  4. Test: claude --plugin-dir ./socrates
     → At session start, verify additionalContext appears
  5. Test cross-platform hook script (bash portability)
  Dependencies: Phase A + B complete (clean plugin baseline before adding hooks)

Phase D — Marketplace Structure
  1. Create .claude-plugin/marketplace.json at repo root
  2. Test local: /plugin marketplace add ./  then /plugin install socrates@socrates-marketplace
  3. Push to GitHub
  4. Test remote: /plugin marketplace add <github-org>/<repo>
     → Consumer install with no submodule init, no build step
  5. Verify recording.cue readable after install (--record flag test)
  Dependencies: Phases A + B + C complete — validates full install path
```

**Why this order:**
- A before B: Moving the file first, then patching it, avoids editing a file that gets moved. Simpler git history. The failing preflight (wrong paths) confirms the directory structure is wired before path migration begins.
- B before C: Hook testing requires the skill to work correctly under plugin paths. Testing both at once makes failures harder to isolate.
- D last: The marketplace end-to-end test (`/plugin install`) validates everything: manifest, skill paths, hooks, and pre-built files all working together without submodule init.

---

## Anti-Patterns

### Anti-Pattern 1: Directories Inside .claude-plugin/

**What people do:** Place `skills/`, `hooks/`, or `protocols/` inside `.claude-plugin/` alongside `plugin.json`.

**Why it's wrong:** Claude Code only looks for `plugin.json` inside `.claude-plugin/`. All other plugin component directories must be at the plugin root (e.g., `socrates/skills/`, `socrates/hooks/`). Components inside `.claude-plugin/` are silently ignored.

**Do this instead:** Only `plugin.json` (and `marketplace.json`) go inside `.claude-plugin/`. Everything else goes at the plugin root.

### Anti-Pattern 2: Hardcoded Paths in SKILL.md After Plugin Conversion

**What people do:** Leave `.claude/skills/socrates/protocols/` paths in SKILL.md after packaging as a plugin, or use `./protocols/` relative paths.

**Why it's wrong:** The plugin cache location (`~/.claude/plugins/cache/socrates/`) differs from the standalone path (`.claude/skills/socrates/`). Relative paths (`./protocols/`) resolve relative to the working directory at invocation time, not to the plugin root. Both fail silently — the Read tool returns empty, the preflight fires, and the skill aborts with a misleading setup error.

**Do this instead:** All Read tool path instructions in SKILL.md must use `$CLAUDE_PLUGIN_ROOT/protocols/...`. Claude Code resolves this variable to the plugin's actual cache location before executing skill content.

### Anti-Pattern 3: Setting Version in Both plugin.json and marketplace.json

**What people do:** Define `"version": "1.1.0"` in both `socrates/.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`.

**Why it's wrong:** `plugin.json` version always wins silently. When the maintainer bumps the marketplace version (e.g., for a patch) but forgets `plugin.json`, Claude Code's update detection sees no change and existing users never receive the update.

**Do this instead:** For relative-path plugins, set version only in `marketplace.json`. Omit `version` from `plugin.json` entirely.

### Anti-Pattern 4: Moving dialectics/ Outside the Plugin Root

**What people do:** Move the `dialectics/` submodule to the repo root (above `socrates/`) to avoid including it in the plugin install cache.

**Why it's wrong:** Plugin caching copies only the plugin root directory. Files outside `socrates/` are not copied. SKILL.md references `$CLAUDE_PLUGIN_ROOT/dialectics/governance/recording.cue` for the `--record` flag — if that file is above the plugin root, it is absent in the cache and the `--record` flag silently fails.

**Do this instead:** Keep `dialectics/` inside `socrates/`. Consumers never need to initialize the submodule (protocols/ has the pre-built files), but the raw `recording.cue` (not processed by strip_cue.py) must be accessible at `$CLAUDE_PLUGIN_ROOT/dialectics/governance/recording.cue` for the --record path.

### Anti-Pattern 5: URL-Based Marketplace Distribution for Relative-Path Plugins

**What people do:** Distribute the marketplace by sharing a raw URL to `marketplace.json` (e.g., a GitHub raw file URL) and instructing users to `/plugin marketplace add <url>`.

**Why it's wrong:** URL-based marketplace add downloads only the `marketplace.json` file. It does not clone the repository. The `source: "./socrates"` relative path references files that are not downloaded — plugin installation fails with "path not found".

**Do this instead:** Distribute via the GitHub repository path: `/plugin marketplace add riverline-labs/socrates`. This triggers a git clone of the full repo, making relative paths work.

---

## Scaling Considerations

This is a plugin with no server-side infrastructure — scaling means "more users installing the plugin", not "more load on a service".

| Concern | Now (< 100 installs) | Later (1k+ installs) |
|---------|---------------------|---------------------|
| Plugin distribution | Single-repo marketplace is sufficient | Same approach scales indefinitely — git clone is stateless |
| Protocol updates | Manual build step + commit | Consider adding a pre-commit hook or CI step to auto-rebuild when dialectics/ changes |
| Submodule drift | Manual `git submodule update --remote` + rebuild | Pin submodule to tagged releases rather than main for stability |
| Plugin version updates | Users update with `/plugin update socrates@socrates-marketplace` | No changes needed — standard plugin versioning handles this |

---

## Sources

- [Claude Code Plugins Reference](https://code.claude.com/docs/en/plugins-reference) — HIGH confidence, official docs. Manifest schema, directory layout rules (CRITICAL: components must be at plugin root, not inside .claude-plugin/), `$CLAUDE_PLUGIN_ROOT` variable, path traversal constraints, version management warning.
- [Create Plugins](https://code.claude.com/docs/en/plugins) — HIGH confidence, official docs. Plugin structure walkthrough, `skills/` directory autodiscovery, migration from standalone `.claude/` to plugin, `--plugin-dir` testing flag.
- [Plugin Marketplaces](https://code.claude.com/docs/en/plugin-marketplaces) — HIGH confidence, official docs. `marketplace.json` schema, relative-path source constraints, single-repo marketplace pattern, version-in-one-place warning.
- [Hooks Reference](https://code.claude.com/docs/en/hooks) — HIGH confidence, official docs. `SessionStart` event, `additionalContext` field, `${CLAUDE_PLUGIN_ROOT}` in command strings, `matcher` values, hook location scoping.
- [Skills Reference](https://code.claude.com/docs/en/skills) — HIGH confidence, official docs. SKILL.md format, `$CLAUDE_PLUGIN_ROOT` in skill content, `allowed-tools` frontmatter, plugin skill namespacing (`plugin-name:skill-name`).

---

*Architecture research for: Socrates v1.1 plugin distribution infrastructure*
*Researched: 2026-03-01*

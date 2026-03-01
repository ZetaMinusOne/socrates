# Stack Research

**Domain:** Claude Code plugin distribution — manifest, hooks, marketplace, cross-platform scripting, build pipeline
**Researched:** 2026-03-01
**Confidence:** HIGH (all formats verified against official Claude Code plugin documentation and obra/superpowers reference implementation)

---

> **Scope:** This file covers v1.1 stack additions only. v1.0 stack (SKILL.md format, CUE interpretation, git submodule) is documented in the original STACK.md (2026-02-28). Do not re-research those topics here.

---

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| `.claude-plugin/plugin.json` | Claude Code plugin standard (current) | Plugin manifest — metadata and component declarations | Required for `/plugin install` discovery. The manifest is optional (Claude Code auto-discovers standard dirs), but `name` is needed for namespacing and marketplace identity. The `name` field becomes the plugin identifier in `plugin@marketplace` install syntax. |
| `.claude-plugin/marketplace.json` | Claude Code marketplace standard (current) | Single-repo marketplace catalog | Allows the same repo to serve as both plugin and marketplace. Users add the repo as a marketplace and install `socrates@socrates-marketplace`. Relative `source: "./"` path means the plugin directory is the repo root — no separate plugins subdirectory needed. |
| `hooks/hooks.json` | Claude Code hooks standard (current) | SessionStart hook declaration | Auto-discovered at `hooks/hooks.json` in plugin root. Declares the SessionStart event handler that injects SKILL.md content into Claude's context at session start. No manifest path override needed — default location works. |
| `hooks/run-hook.cmd` | Polyglot shell/batch pattern (no version) | Cross-platform hook dispatcher | A single file that functions as both a Windows `.cmd` batch script and a Unix shell script. Eliminates the need for platform-specific files. The `.cmd` extension triggers Windows batch execution; the polyglot header (`:<< 'CMDBLOCK'`) makes Unix bash skip the Windows section. Extensionless hook scripts (like `session-start`) avoid Claude Code's Windows auto-detection that would prepend `bash` unnecessarily. |
| `hooks/session-start` (no extension) | bash | Context injection at session start | Reads SKILL.md content, JSON-escapes it, and outputs `hookSpecificOutput.additionalContext` JSON for Claude to receive as session context. No extension prevents Windows auto-detection. Called by `run-hook.cmd session-start`. Path resolved dynamically from `$0` — no `CLAUDE_PLUGIN_ROOT` dependency in the script itself (see pitfall below). |
| `scripts/strip_cue.py` | Python 3.x (existing) | Build tool — strips CUE files for distribution | Already exists in `socrates/scripts/`. Strips comments and whitespace from `.cue` source files into `.opt.cue` output files. Pre-built `.opt.cue` files committed to git so consumers never need to run the build or initialize the submodule. |

### File Formats

#### `.claude-plugin/plugin.json` — Plugin Manifest

```json
{
  "name": "socrates",
  "description": "Structured dialectic reasoning for Claude Code — auto-routes problems to the correct protocol from 13 CUE-schema reasoning protocols",
  "version": "1.1.0",
  "author": {
    "name": "Your Name",
    "email": "you@example.com"
  },
  "homepage": "https://github.com/your-org/socrates",
  "repository": "https://github.com/your-org/socrates",
  "license": "MIT",
  "keywords": ["dialectics", "reasoning", "protocols", "argumentation"]
}
```

**Field notes:**
- `name` is the only required field. It becomes the plugin identifier: `socrates@marketplace-name`.
- `version` must be bumped on every change — Claude Code uses version to detect updates and skip re-caching unchanged plugins. Without a version bump, existing users won't receive changes.
- Component paths (`skills`, `hooks`) are omitted here because the default auto-discovery locations (`skills/`, `hooks/hooks.json`) are used. Only specify these when using non-standard paths.
- The manifest lives in `.claude-plugin/` but all other directories (`skills/`, `hooks/`, `scripts/`) are at the plugin root — not inside `.claude-plugin/`.

#### `.claude-plugin/marketplace.json` — Marketplace Catalog

```json
{
  "name": "socrates-marketplace",
  "owner": {
    "name": "Your Name",
    "email": "you@example.com"
  },
  "plugins": [
    {
      "name": "socrates",
      "description": "Structured dialectic reasoning — 13 protocols, auto-routing, zero setup",
      "version": "1.1.0",
      "source": "./"
    }
  ]
}
```

**Field notes:**
- `name` is the marketplace identifier. Users install with `/plugin install socrates@socrates-marketplace`.
- `source: "./"` points to the repo root as the plugin directory. This is the single-repo pattern — same repo serves as both plugin and marketplace.
- Reserved marketplace names to avoid: `claude-code-marketplace`, `claude-code-plugins`, `anthropic-marketplace`, and similar official-sounding names.
- `version` here is advisory when `plugin.json` also declares a version — `plugin.json` always wins. For relative-path plugins, set version in `marketplace.json` only (omit from `plugin.json`) to avoid silent version shadowing.
- Relative `source` paths only work when users add the marketplace via git (GitHub or git URL). URL-based marketplace addition does not download relative-path plugin files. This is acceptable — instruct users to add via `github` source.

#### `hooks/hooks.json` — Hook Configuration

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume|clear|compact",
        "hooks": [
          {
            "type": "command",
            "command": "'${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd' session-start",
            "async": false
          }
        ]
      }
    ]
  }
}
```

**Field notes:**
- `matcher` regex matches all session start types: new sessions (`startup`), resumed (`resume`), after `/clear` (`clear`), after compaction (`compact`). This ensures the skill context is injected whenever a session begins.
- `"async": false` keeps the hook synchronous — required because context injection must complete before Claude's first response.
- `${CLAUDE_PLUGIN_ROOT}` is valid in `hooks.json` for the command field. HOWEVER: there is a confirmed open bug (anthropics/claude-code#27145) where `CLAUDE_PLUGIN_ROOT` is not set during `SessionStart` execution at the shell level, even though the path in hooks.json resolves correctly. The `run-hook.cmd` script must derive its own root from `$0` or `BASH_SOURCE[0]` rather than relying on `$CLAUDE_PLUGIN_ROOT` inside the shell script.
- The single-quotes around `${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd` in the command string handle paths with spaces on macOS/Linux. This is the pattern used by superpowers.

#### `hooks/run-hook.cmd` — Cross-Platform Dispatcher

This is a polyglot file that functions as both a Windows batch script and a bash script. Structure:

```
: << 'CMDBLOCK'
@echo off
REM Windows section: find bash.exe in Git for Windows locations
REM Try C:\Program Files\Git\bin\bash.exe
REM Try C:\Program Files (x86)\Git\bin\bash.exe
REM Fall back to PATH (MSYS2, Cygwin, etc.)
REM If no bash found, exit 0 (silent degradation)
REM Pass all arguments: %1 %2 %3 ... %9
CMDBLOCK

# Unix section: runs when bash processes the file
# The : << 'CMDBLOCK' ... CMDBLOCK is a no-op here-doc in bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
exec bash "$PLUGIN_ROOT/hooks/$1" "${@:2}"
```

**Why this pattern:**
- One file handles macOS, Linux, and Windows — no platform detection needed in CI or install scripts.
- The `:` no-op plus here-doc `<< 'CMDBLOCK'` causes bash to skip the Windows batch block entirely.
- Windows cmd.exe reads the batch block (searches for bash.exe in Git for Windows paths) and delegates to bash.
- If no bash is found on Windows, exits with code 0 (non-blocking error) — the plugin degrades gracefully rather than failing session start.
- Extensionless scripts (hook names like `session-start` without `.sh`) prevent Claude Code on Windows from auto-prepending `bash` to the command, which would double-invoke bash.
- The Unix section derives `PLUGIN_ROOT` from `BASH_SOURCE[0]` — immune to the `CLAUDE_PLUGIN_ROOT` unset bug.

#### `hooks/session-start` — Context Injection Script (no extension)

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SKILL_CONTENT="$(cat "$PLUGIN_ROOT/skills/socrates/SKILL.md")"

escape_for_json() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\t'/\\t}"
  echo "$s"
}

ESCAPED_SKILL="$(escape_for_json "$SKILL_CONTENT")"

cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "$ESCAPED_SKILL"
  }
}
EOF
```

**Why this structure:**
- No shebang with `/bin/bash` — uses `#!/usr/bin/env bash` for portability across macOS and Linux where bash may not be at `/bin/bash`.
- `set -euo pipefail` prevents silent failures — if SKILL.md cannot be read, the script fails with exit code 1 (non-blocking per `SessionStart` error handling, stderr shown in verbose mode only).
- Derives path from `BASH_SOURCE[0]` — immune to `CLAUDE_PLUGIN_ROOT` not being set in session-start shell context.
- `hookSpecificOutput.additionalContext` is the correct field per official docs (verified). The superpowers implementation outputs both `additional_context` (Cursor compat) and `hookSpecificOutput.additionalContext` — for Socrates (Claude Code only), only the Claude field is needed.
- The JSON output must be the only thing on stdout. Shell profile output can interfere — `set -euo pipefail` helps catch issues early.

**Known bug to be aware of (MEDIUM confidence — active open issue):**
- Issue #16538: `hookSpecificOutput.additionalContext` from plugin-based SessionStart hooks is not reliably surfaced to Claude — the hook may run successfully but context may not reach Claude's context window. The workaround is to register the hook in `~/.claude/settings.json` directly for affected users, but this defeats plugin distribution.
- Issue #11509: Local file-based marketplace plugins (added via local path) may not have their hooks registered at all. Git-based marketplace installation (via GitHub) does not have this problem.
- **Mitigation:** SKILL.md content should also be readable via the `Read` tool as a fallback — the Preflight section in SKILL.md already does this. The hook provides convenience; the skill remains functional without it.

### Build Pipeline

| Component | Technology | Purpose | Notes |
|-----------|------------|---------|-------|
| `scripts/strip_cue.py` | Python 3.x | Strip `.cue` → `.opt.cue` | Already exists at `socrates/scripts/strip_cue.py`. Run once when upstream dialectics changes. Output `.opt.cue` files committed to git. |
| Pre-built `.opt.cue` files | n/a (committed artifacts) | Consumer-ready protocol files | Located at `skills/socrates/protocols/`. Consumers get these files directly — no submodule init, no build step. |
| `dialectics/` submodule | git submodule | Upstream source for `.cue` files | Developer-only. Consumers never initialize this. The submodule stays as the authoritative source for re-running the build when upstream changes. |

**Build invocation (developer only):**
```bash
# From repo root, after submodule is initialized
python3 scripts/strip_cue.py
# Commit the resulting .opt.cue files
git add skills/socrates/protocols/
git commit -m "build: rebuild optimized protocol files from upstream"
```

### Plugin Directory Structure (Target State)

```
socrates/                              # Plugin root (also serves as repo root)
├── .claude-plugin/
│   ├── plugin.json                    # Plugin manifest
│   └── marketplace.json              # Single-repo marketplace catalog
├── skills/
│   └── socrates/
│       ├── SKILL.md                  # Skill entrypoint (paths updated for plugin-relative)
│       └── protocols/
│           ├── dialectics.opt.cue    # Kernel primitives (pre-built)
│           ├── routing.opt.cue       # Routing logic (pre-built)
│           ├── adversarial/
│           │   ├── atp.opt.cue
│           │   ├── cbp.opt.cue
│           │   ├── cdp.opt.cue
│           │   ├── cffp.opt.cue
│           │   ├── emp.opt.cue
│           │   └── hep.opt.cue
│           ├── evaluative/
│           │   ├── aap.opt.cue
│           │   ├── cgp.opt.cue
│           │   ├── ifa.opt.cue
│           │   ├── ovp.opt.cue
│           │   ├── ptp.opt.cue
│           │   └── rcp.opt.cue
│           └── exploratory/
│               └── adp.opt.cue
├── hooks/
│   ├── hooks.json                    # Hook event declarations
│   ├── run-hook.cmd                  # Cross-platform dispatcher (polyglot)
│   └── session-start                 # Context injection script (no extension)
├── scripts/
│   └── strip_cue.py                  # Build tool (developer-only)
├── dialectics/                        # Git submodule (developer-only, gitignored for consumers)
│   └── ...                           # riverline-labs/dialectics source
└── README.md
```

**Key structural rules (verified against official docs):**
- `.claude-plugin/` contains ONLY `plugin.json` and `marketplace.json`. No components live inside it.
- `skills/` is at the plugin root (not inside `.claude-plugin/`).
- `hooks/` is at the plugin root. `hooks.json` auto-discovered there.
- `skills/socrates/` is the skill directory — SKILL.md goes inside a named subdirectory, not directly in `skills/`.

### SKILL.md Path Update Required

The existing `SKILL.md` uses hardcoded paths from the v1.0 `.claude/skills/socrates/` location:

```
# Current (v1.0 paths — must update):
.claude/skills/socrates/protocols/dialectics.opt.cue
.claude/skills/socrates/protocols/routing.opt.cue
.claude/skills/socrates/dialectics/governance/recording.cue

# Target (v1.1 plugin-relative paths):
${CLAUDE_PLUGIN_ROOT}/skills/socrates/protocols/dialectics.opt.cue
${CLAUDE_PLUGIN_ROOT}/skills/socrates/protocols/routing.opt.cue
${CLAUDE_PLUGIN_ROOT}/skills/socrates/protocols/evaluative/rcp.opt.cue  # recording.cue merged into pre-built evaluative/rcp.opt.cue or kept as separate file
```

**Path strategy:** Use `${CLAUDE_PLUGIN_ROOT}` for all file references in SKILL.md. This variable is set correctly by Claude Code when reading skill files (distinct from the SessionStart hook execution context bug).

---

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| Single-repo marketplace (`.claude-plugin/marketplace.json` at root, `source: "./"`) | Separate marketplace repo | Only when distributing multiple unrelated plugins from one catalog. For Socrates, one plugin = one repo = one marketplace is simpler. |
| Pre-built `.opt.cue` files committed to git | Consumers run `python3 scripts/strip_cue.py` | Never for plugin distribution — requires Python and build awareness. Plugin must be install-ready. |
| Pre-built `.opt.cue` files committed to git | CI/CD pipeline builds and publishes artifacts | Out of scope per PROJECT.md. CI adds release complexity. Direct commit is simpler and sufficient. |
| `hooks/run-hook.cmd` polyglot dispatcher | Platform-specific `run-hook.sh` and `run-hook.bat` | Only if targeting a known-Unix-only audience and Windows support is explicitly out of scope. The polyglot approach has zero overhead on Unix. |
| `hooks/session-start` (no extension) | `hooks/session-start.sh` | Never — `.sh` extension causes Claude Code on Windows to auto-prepend `bash`, breaking the polyglot dispatch chain. |
| `hookSpecificOutput.additionalContext` JSON output | Plain stdout text output | Plain stdout text is also added as context for SessionStart per official docs. Either works. JSON output is preferred for compatibility with the `hookSpecificOutput` pattern and future dual-format (Claude + Cursor) expansion. |
| `${CLAUDE_PLUGIN_ROOT}` paths in SKILL.md | Relative paths like `protocols/dialectics.opt.cue` | Relative paths depend on working directory at invocation time. `${CLAUDE_PLUGIN_ROOT}` is always the plugin install directory regardless of where the user runs Claude Code. |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Separate marketplace repo | Adds a second repo to maintain with no benefit for a single-plugin distribution. Single-repo pattern serves both purposes. | `source: "./"` in `marketplace.json` at the repo root |
| CI/release pipeline for `.opt.cue` builds | Explicitly out of scope in PROJECT.md. Adds pipeline complexity, secrets management, and release ceremony. | Commit pre-built `.opt.cue` files directly to git on each upstream change |
| `CLAUDE_PLUGIN_ROOT` inside `session-start` script | Known open bug: `CLAUDE_PLUGIN_ROOT` is not set in shell context during `SessionStart` hook execution (issue #27145). Will cause `session-start` to fail silently. | Derive plugin root from `BASH_SOURCE[0]` in the script itself |
| `.sh` extension on hook scripts | Claude Code on Windows auto-prepends `bash` to `.sh` files, breaking the `run-hook.cmd` polyglot dispatch. The script gets executed twice. | Extensionless script names (`session-start` not `session-start.sh`) |
| Relative source paths in marketplace.json for URL-based marketplace | URL-based marketplace add only downloads `marketplace.json` — not relative plugin files. Install fails. | Instruct users to add marketplace via GitHub (`/plugin marketplace add owner/repo`) not via URL |
| MCP server packaging | Out of scope per PROJECT.md. Adds `node` or other runtime dependency. Plugin distribution covers the current goal. | `/plugin` system with skill + hooks |
| Claude Desktop support | Out of scope per PROJECT.md. Plugin format targets Claude Code only. | n/a |
| Submodule initialization requirement for consumers | Defeats zero-setup install goal. Consumers cannot initialize git submodules inside the plugin cache. | Pre-built `.opt.cue` files committed to git |

---

## Known Issues and Mitigations

| Issue | Severity | Status | Mitigation |
|-------|----------|--------|------------|
| `CLAUDE_PLUGIN_ROOT` not set during SessionStart shell execution (issue #27145) | Medium | Open (no fix as of 2026-03-01) | Derive paths from `BASH_SOURCE[0]` in hook scripts. Do not use `$CLAUDE_PLUGIN_ROOT` inside the bash session-start script. |
| `hookSpecificOutput.additionalContext` from plugin SessionStart may not reach Claude (issue #16538) | Medium | Open (no fix as of 2026-03-01) | Design SKILL.md Preflight section to remain functional via Read tool as fallback. Session-start hook is a UX enhancement, not a hard requirement. |
| Local file-based marketplace plugin hooks not registered (issue #11509) | Medium | Open | Instruct users to install via GitHub-based marketplace, not local path. Avoid testing with `source: "/absolute/path"`. |

---

## Version Compatibility

| Component | Compatible With | Notes |
|-----------|-----------------|-------|
| `plugin.json` + `marketplace.json` | Claude Code current (2025-2026) | Official plugin format, actively maintained |
| `hooks/hooks.json` SessionStart | Claude Code current | SessionStart `additionalContext` injection documented but has open bugs for plugin-based hooks |
| `${CLAUDE_PLUGIN_ROOT}` in hooks.json | Claude Code current | Works in hooks.json command field; broken in SessionStart shell env (use BASH_SOURCE workaround) |
| `run-hook.cmd` polyglot pattern | bash + Windows cmd.exe | Requires Git for Windows on Windows (standard developer setup). Silent degradation if no bash found. |
| Pre-built `.opt.cue` files | n/a | Static files — no version constraint |
| Python 3 (strip_cue.py) | Python 3.6+ | Developer-only build tool; not shipped to consumers |
| Relative `source: "./"` in marketplace.json | Git-based marketplace add | Does not work with URL-based marketplace add |

---

## Sources

- [Claude Code Plugin Reference — Official Docs](https://code.claude.com/docs/en/plugins-reference) — Complete plugin.json schema, directory structure rules, CLAUDE_PLUGIN_ROOT variable, common issues table (HIGH confidence)
- [Claude Code Plugin Marketplaces — Official Docs](https://code.claude.com/docs/en/plugin-marketplaces) — marketplace.json schema, single-repo pattern, relative path source, strict mode (HIGH confidence)
- [Claude Code Hooks Reference — Official Docs](https://code.claude.com/docs/en/hooks) — SessionStart event schema, hookSpecificOutput.additionalContext format, exit code behavior, matcher values (HIGH confidence)
- [obra/superpowers — Reference Implementation](https://github.com/obra/superpowers) — `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `hooks/hooks.json`, `hooks/run-hook.cmd`, `hooks/session-start` examined directly via GitHub API and raw file fetches (HIGH confidence)
- [anthropics/claude-code issue #27145](https://github.com/anthropics/claude-code/issues/27145) — CLAUDE_PLUGIN_ROOT not set during SessionStart; workaround: derive from absolute path (MEDIUM confidence — open issue, community-reported)
- [anthropics/claude-code issue #11509](https://github.com/anthropics/claude-code/issues/11509) — Local file-based marketplace plugin hooks never execute (MEDIUM confidence — open issue, multiple reporters)
- [anthropics/claude-code issue #16538](https://github.com/anthropics/claude-code/issues/16538) — hookSpecificOutput.additionalContext not reaching Claude from plugin SessionStart hooks (MEDIUM confidence — open issue, has repro)

---

*Stack research for: Socrates v1.1 — Claude Code plugin distribution additions*
*Researched: 2026-03-01*

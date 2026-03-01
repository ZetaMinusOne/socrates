# Feature Research

**Domain:** Claude Code plugin distribution — installable skill via `/plugin`
**Researched:** 2026-03-01
**Confidence:** HIGH (official Claude Code plugin docs; obra/superpowers reference implementation directly inspected)

---

## Context: What Already Exists (v1.0)

These features are **shipped and out of scope** for this milestone. They are noted only to clarify boundaries.

- `/socrates` slash command with SKILL.md frontmatter
- Auto-routing via governance/routing.cue
- All 13 dialectic protocols executing with obligation gates and revision loops
- Narrative prose output, `--structured` typed output, `--record` audit trail output
- `strip_cue.py` that generates `.opt.cue` files from raw CUE schemas
- Git submodule for dialectics framework

This research covers only what is needed for **v1.1: plugin distribution**.

---

## Feature Landscape

### Table Stakes (Users Expect These)

Features a `/plugin`-installable Claude Code plugin must have. Missing these = the plugin does not install or cannot be used.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| `.claude-plugin/plugin.json` manifest | The Claude Code plugin system auto-discovers components via `plugin.json`. Without it, `/plugin install` cannot register the plugin. | LOW | Only `name` is required. Metadata fields (`version`, `description`, `author`, `homepage`, `repository`, `license`, `keywords`) are optional but expected by users browsing a marketplace listing. |
| `.claude-plugin/marketplace.json` | Required for a repo to function as a marketplace. Without it, users cannot run `/plugin marketplace add <repo>`. The single-repo pattern means the plugin and marketplace live in the same repo. | LOW | Requires: `name`, `owner.name`, `plugins[]` with at least `name` and `source`. The obra/superpowers marketplace.json is 514 bytes — minimal. |
| `skills/socrates/SKILL.md` at plugin root | Plugin convention: skills live at `<plugin-root>/skills/<skill-name>/SKILL.md`. Current SKILL.md is at `socrates/SKILL.md` — this directory must move or be mapped. Skills directory at root is the auto-discovery location. | LOW | `plugin.json` can specify custom skill paths via `"skills": "./socrates"` — avoids moving the directory. |
| Pre-built protocol files committed to git | Consumers install via `/plugin install`, which clones the repo into `~/.claude/plugins/cache/`. The cloned copy cannot run `git submodule update --init`. Pre-built files (already committed `.opt.cue` outputs) must exist in the repo for consumers to find them. | MEDIUM | The `strip_cue.py` build step already generates these. They must be committed into the repo at `socrates/protocols/`. Path references in SKILL.md must point to `${CLAUDE_PLUGIN_ROOT}/socrates/protocols/` rather than the submodule path. |
| `SessionStart` hook for context injection | The `SessionStart` hook fires at session startup and can inject `additionalContext` for Claude. This is the standard mechanism for injecting skill context automatically. obra/superpowers uses exactly this pattern: reads `skills/using-superpowers/SKILL.md` and returns it as `hookSpecificOutput.additionalContext`. Without this, users must manually invoke `/socrates` before any session has context. | MEDIUM | Hook must: (1) read SKILL.md content, (2) JSON-escape it, (3) return `{ hookSpecificOutput: { hookEventName: "SessionStart", additionalContext: "..." } }`. |
| Cross-platform hook execution | Plugin hooks run on macOS, Linux, and Windows. A plain `.sh` script fails on Windows. obra/superpowers solved this with `run-hook.cmd`: a polyglot batch/bash file that detects Windows and uses Git Bash, or falls directly to bash on Unix. | MEDIUM | Use the polyglot wrapper pattern from superpowers. Extensionless hook scripts are required because Claude Code on Windows auto-prepends "bash" to `.sh` filenames — defeating the cross-platform goal. |
| `hooks/hooks.json` wiring `SessionStart` | The hooks.json in the plugin root wires the `SessionStart` event to the hook script. Without this, the hook script is never called. | LOW | Pattern from superpowers: `{ "hooks": { "SessionStart": [{ "matcher": "startup|resume|clear|compact", "hooks": [{ "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd session-start" }] }] } }` |
| `${CLAUDE_PLUGIN_ROOT}`-relative paths in SKILL.md | Installed plugins are copied to `~/.claude/plugins/cache/<plugin-name>/`. Absolute paths or project-relative paths break. All file references in SKILL.md — the protocol `.opt.cue` file paths — must use `${CLAUDE_PLUGIN_ROOT}` as the prefix. | MEDIUM | SKILL.md currently has paths like `.claude/skills/socrates/protocols/dialectics.opt.cue`. These must become `${CLAUDE_PLUGIN_ROOT}/socrates/protocols/dialectics.opt.cue`. This is a find-and-replace update but must be validated to ensure Claude's Read tool resolves the variable correctly. |
| Semantic versioning in manifest | Claude Code uses `version` in `plugin.json` to detect whether to update a cached plugin. Without version bumps, users with cached installations never receive updates. | LOW | Follow semver. Start at `1.1.0` for this milestone. Update `version` on every substantive change. The warning from official docs: if code changes but version does not, existing users see no update. |

### Differentiators (Competitive Advantage)

Features that distinguish this plugin from a minimal plugin stub and provide a materially better user experience.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Session-start context injection (vs manual invocation) | Standard skill plugins require the user to run `/socrates` before any reasoning context is active. With `SessionStart` injection, Claude knows the skill exists and its routing logic from the moment the session opens — matching the obra/superpowers experience where skills "just work". | MEDIUM | Requires `session-start` hook script reading SKILL.md and returning it as `additionalContext`. The script must handle JSON escaping reliably (bash parameter substitution is faster than per-character processing, as superpowers demonstrates). |
| Single-repo marketplace (plugin is also the marketplace) | Users can both browse the plugin listing (`/plugin marketplace add riverline-labs/socrates`) and install the plugin (`/plugin install socrates@riverline-labs`) from one repo. No separate marketplace repo needed. | LOW | `marketplace.json` with `"source": "./"` points the marketplace at the same repo root. This is exactly the obra/superpowers dev marketplace pattern. |
| Zero consumer setup (no submodule init, no build step) | Installing via `/plugin install` should be one command. Consumers must never see: "run git submodule update --init" or "run python strip_cue.py". Pre-built `.opt.cue` files committed to git achieve this. | LOW (to commit files) / MEDIUM (to keep them current) | The build step becomes a developer workflow step (run before committing), not a consumer requirement. A comment or Makefile target should document this. |
| Protocol files optimized for context window | `.opt.cue` files (stripped of comments and whitespace) are smaller than raw CUE files. This directly affects how many tokens Claude uses per session. The strip_cue.py step already produces these. Committing them preserves the optimization for all consumers. | LOW | Already implemented. The table stakes requirement is that these are pre-committed. The differentiator is that they are also optimized (not just raw CUE copies). |
| `extraKnownMarketplaces` entry in project settings | Committing a `.claude/settings.json` with `extraKnownMarketplaces` wired to the repo means that any user who clones the repo and trusts the project folder is automatically prompted to install the marketplace — zero friction onboarding. | LOW | This is a one-field JSON file. Documented in official Claude Code settings docs. Highest discovery ROI for lowest implementation cost. |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Separate marketplace repo | Feels more "official" or scalable | Adds a second repo to maintain; breaks the relative-path source in marketplace.json (relative paths only work for git-cloned marketplaces, and they point within the same repo); creates version synchronization burden | Single-repo: marketplace.json points to `"./"` — marketplace and plugin are the same repo |
| CI/release pipeline that builds `.opt.cue` files | Automation feels cleaner | Adds GitHub Actions complexity; requires secret management or runner setup; consumers still get the same result — pre-built files in git; the pipeline is solving a developer workflow problem that can be solved with a Makefile | Commit pre-built files manually after running strip_cue.py. Document this in a dev README section or Makefile target. |
| npm package distribution | Familiar install mechanism for JS developers | Plugin sources support npm, but the plugin system already handles git-based installation natively; npm adds a registry publish step, package.json maintenance, and version mirroring burden with no UX benefit for the user | Use github source in marketplace.json: `{ "source": "github", "repo": "owner/socrates" }` |
| Per-session skill loading via `UserPromptSubmit` hook | Feels like "context is always fresh" | `UserPromptSubmit` fires on every prompt submission — injecting SKILL.md content on every prompt wastes tokens and disrupts conversational flow. SessionStart fires once per session, which is the right granularity | Use `SessionStart` hook, which fires once and injects context at the right moment |
| `disable-model-invocation: false` on SKILL.md | Allows Claude to auto-invoke `/socrates` without user typing it | Dialectic reasoning on arbitrary problems without user intent is disruptive. Socrates is a deliberate tool, not ambient behavior. The current `disable-model-invocation: true` is correct | Keep `disable-model-invocation: true`. The SessionStart injection gives Claude awareness without granting invocation authority. |
| Absolute paths in SKILL.md | Easier to write during development | Absolute paths break in plugin cache (`~/.claude/plugins/cache/`) because the plugin is copied, not used in-place. The official docs are explicit: "path traversal outside plugin root" fails. | Use `${CLAUDE_PLUGIN_ROOT}/...` prefix for all file reads in SKILL.md |
| Symlinking dialectics submodule into plugin | Avoids committing generated files | Symlinks to paths outside the plugin directory are followed during cache copy, but the submodule's actual files may not be present in the consumer's environment (they cloned the plugin, not initialized its submodules). Pre-built committed files are simpler and more reliable. | Commit pre-built `.opt.cue` files; keep submodule as dev-only for regeneration |

---

## Feature Dependencies

```
[.claude-plugin/marketplace.json]
    └──required for──> [/plugin marketplace add <repo>]
                           └──required for──> [/plugin install socrates@<marketplace>]

[.claude-plugin/plugin.json]
    └──required for──> [Plugin registration and discovery]
                           └──required for──> [/socrates skill available after install]

[Pre-built .opt.cue files committed to git]
    └──required by──> [SKILL.md file reads via ${CLAUDE_PLUGIN_ROOT}]
                          └──required by──> [Protocol execution post-install]

[hooks/hooks.json SessionStart wiring]
    └──required by──> [session-start hook script execution]
                          └──required by──> [Automatic context injection at session open]

[session-start hook script]
    └──depends on──> [${CLAUDE_PLUGIN_ROOT}/socrates/SKILL.md readable]
    └──depends on──> [Cross-platform execution (run-hook.cmd wrapper)]

[${CLAUDE_PLUGIN_ROOT}-relative paths in SKILL.md]
    └──required by──> [Protocol file reads from plugin cache]
    └──conflicts with──> [Existing dev paths (.claude/skills/socrates/...)]

[Semantic version in plugin.json]
    └──required by──> [Update detection for cached installations]

[extraKnownMarketplaces in .claude/settings.json]
    └──enhances──> [/plugin marketplace add discoverability]
    (optional but highest ROI for zero-friction onboarding)
```

### Dependency Notes

- **marketplace.json is the install entry point:** Without it, `/plugin install` cannot find the plugin. This is the first file to create.
- **plugin.json enables skill discovery:** Claude Code auto-discovers `skills/` directories, but `plugin.json` provides the name, version, and metadata for the marketplace listing.
- **Pre-built files must exist before paths can work:** Updating SKILL.md paths to use `${CLAUDE_PLUGIN_ROOT}` is pointless if the files at those paths don't exist in the committed repo.
- **SessionStart hook depends on cross-platform wrapper:** The hook fires on macOS, Linux, and Windows. The run-hook.cmd polyglot wrapper must exist before the hook is wired in hooks.json.
- **Path migration is a breaking change for existing dev setup:** SKILL.md currently uses `.claude/skills/socrates/` paths. After migration to `${CLAUDE_PLUGIN_ROOT}/socrates/`, the dev setup must be updated too (or the developer installs the plugin locally for testing via `claude --plugin-dir ./`).

---

## User Journey: Install to First Use

This is the complete flow a new user experiences. Each step must work without documentation or setup instructions.

```
1. Discovery
   User finds the repo (GitHub search, word of mouth, marketplace browse)

2. Marketplace registration
   /plugin marketplace add riverline-labs/socrates
   → Claude Code clones .claude-plugin/marketplace.json
   → Marketplace "riverline-labs" now known to Claude Code

3. Plugin installation
   /plugin install socrates@riverline-labs
   → Claude Code clones the full repo into ~/.claude/plugins/cache/
   → plugin.json read: name, version, skills path registered
   → hooks/hooks.json read: SessionStart hook registered
   → /socrates command now available

4. Session open (next time user opens Claude Code)
   → SessionStart hook fires (matcher: startup|resume|clear|compact)
   → run-hook.cmd invokes session-start bash script
   → Script reads ${CLAUDE_PLUGIN_ROOT}/socrates/SKILL.md
   → Returns additionalContext JSON
   → Claude now has Socrates skill context in its system prompt

5. First use
   /socrates Should I use a monorepo or separate repos for this project?
   → Claude reads dialectics.opt.cue (kernel primitives)
   → Claude reads routing.opt.cue (routing logic)
   → Routes to appropriate protocol (e.g., OVP for trade-off evaluation)
   → Claude reads evaluative/ovp.opt.cue
   → Executes protocol: structured evaluation cycle
   → Returns narrative output with reasoning and conclusion

6. Update (when new version published)
   /plugin update socrates@riverline-labs
   → Claude Code checks version in plugin.json
   → If version bumped: re-clones to cache
   → New protocol files and updated SKILL.md take effect next session
```

**Failure modes to prevent:**
- Step 3 fails if pre-built `.opt.cue` files are not committed (Claude can't read them from cache)
- Step 4 fails if session-start script has path errors or JSON escaping bugs
- Step 5 fails if SKILL.md paths use `.claude/skills/socrates/` instead of `${CLAUDE_PLUGIN_ROOT}/socrates/`
- Step 6 is silently broken if version in plugin.json is not bumped

---

## MVP Definition

### Launch With (v1.1)

Minimum viable plugin that installs, activates, and executes without manual setup steps.

- [ ] `.claude-plugin/plugin.json` — name, version, description, author, homepage, repository
- [ ] `.claude-plugin/marketplace.json` — marketplace name, owner, single plugin entry with `"source": "./"`
- [ ] Pre-built `.opt.cue` files committed at `socrates/protocols/` (all 13 protocols + dialectics.opt.cue + routing.opt.cue)
- [ ] SKILL.md paths migrated from `.claude/skills/socrates/` to `${CLAUDE_PLUGIN_ROOT}/socrates/`
- [ ] `hooks/hooks.json` wiring `SessionStart` to `${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd session-start`
- [ ] `hooks/run-hook.cmd` — polyglot Windows batch / Unix bash wrapper
- [ ] `hooks/session-start` — reads SKILL.md, returns `additionalContext` JSON (extensionless, executable)
- [ ] `plugin.json` `"skills"` field pointing to `./socrates` if skill is not at default `skills/` path

### Add After Validation (v1.x)

- [ ] `.claude/settings.json` with `extraKnownMarketplaces` — add once plugin is publicly accessible at a stable URL; highest discovery ROI, zero implementation cost
- [ ] `CHANGELOG.md` — add after first update cycle proves versioning works correctly

### Future Consideration (v2+)

- [ ] Multiple plugins in the marketplace (if riverline-labs builds more tools, the marketplace.json can list them)
- [ ] Release channel support (stable/latest via separate marketplace.json refs) — only if there is a user base that needs differentiated update cadences
- [ ] npm distribution — only if users specifically request it and the git-based install proves insufficient

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| plugin.json manifest | HIGH | LOW | P1 |
| marketplace.json | HIGH | LOW | P1 |
| Pre-built .opt.cue files committed | HIGH | LOW | P1 |
| SKILL.md path migration to ${CLAUDE_PLUGIN_ROOT} | HIGH | LOW | P1 |
| hooks/hooks.json SessionStart wiring | HIGH | LOW | P1 |
| session-start hook script | HIGH | MEDIUM | P1 |
| Cross-platform run-hook.cmd wrapper | HIGH | MEDIUM | P1 |
| Semantic version in plugin.json | MEDIUM | LOW | P1 |
| extraKnownMarketplaces in .claude/settings.json | MEDIUM | LOW | P2 |
| CHANGELOG.md | LOW | LOW | P2 |
| npm distribution | LOW | MEDIUM | P3 |
| Separate marketplace repo | LOW | HIGH | P3 (anti-feature) |

**Priority key:**
- P1: Must have for install to work end-to-end
- P2: Should have for full UX polish
- P3: Defer or avoid

---

## Competitor Feature Analysis

obra/superpowers is the direct reference implementation. It is the only known public plugin using the full `.claude-plugin/` + `hooks/` + `skills/` pattern.

| Feature | obra/superpowers | Socrates v1.1 |
|---------|-----------------|---------------|
| marketplace.json | Yes — `superpowers-dev` marketplace, single plugin, `"source": "./"` | Yes — same single-repo pattern |
| plugin.json | Yes — name, version, author, description, keywords | Yes — same fields |
| SessionStart hook | Yes — reads `skills/using-superpowers/SKILL.md`, injects as `additionalContext` | Yes — reads `socrates/SKILL.md`, injects routing context |
| Cross-platform hook | Yes — `run-hook.cmd` polyglot wrapper, extensionless hook scripts | Yes — adopt run-hook.cmd pattern verbatim |
| Skills directory | Yes — 14 skills at `skills/<name>/SKILL.md` | Yes — single skill at `socrates/SKILL.md` (may need `plugin.json` path override) |
| Pre-built protocol files | N/A (superpowers has no CUE schemas) | Yes — strip_cue.py output committed at `socrates/protocols/` |
| Zero consumer setup | Yes — install and done | Yes — no submodule init, no build step for consumers |

**Key difference:** Socrates adds a build artifact layer (pre-built `.opt.cue` files) that superpowers does not need. The session-start hook must inject context that gives Claude enough information to find and use those files correctly via `${CLAUDE_PLUGIN_ROOT}`.

---

## Implementation Notes and Dependencies on Existing Code

### SKILL.md path migration

The existing SKILL.md (v1.0) has hardcoded paths like:
```
.claude/skills/socrates/protocols/dialectics.opt.cue
```

These must become:
```
${CLAUDE_PLUGIN_ROOT}/socrates/protocols/dialectics.opt.cue
```

This is a global find-and-replace in the SKILL.md file. Requires verifying that Claude's `Read` tool correctly expands `${CLAUDE_PLUGIN_ROOT}` when reading file paths from skill instructions. **Confidence: HIGH** — official docs confirm `${CLAUDE_PLUGIN_ROOT}` is supported in hooks. Needs verification for SKILL.md `Read` tool arguments specifically.

### strip_cue.py build workflow

`strip_cue.py` already exists at `socrates/scripts/strip_cue.py`. It generates `.opt.cue` files from the dialectics submodule. The build step must:
1. Run `strip_cue.py` to regenerate protocol files
2. Commit the output to `socrates/protocols/`

This is a developer responsibility before each release. The submodule remains as dev-only infrastructure — consumers never touch it.

### Session-start hook script

The script must handle JSON escaping correctly. The superpowers approach (bash parameter substitution) is:
```bash
content="${content//\\/\\\\}"   # escape backslashes
content="${content//\"/\\\"}"   # escape double quotes
content="${content//$'\n'/\\n}" # escape newlines
content="${content//$'\t'/\\t}" # escape tabs
```

This is significantly faster than per-character processing and avoids `jq` as a runtime dependency.

### Plugin path for skills directory

The current skill lives at `socrates/SKILL.md` (at repo root), not `skills/socrates/SKILL.md`. Two options:
1. Add `"skills": "./socrates"` to `plugin.json` to override the default skills path — LOW cost
2. Move the skill to `skills/socrates/SKILL.md` — LOW cost but requires updating all references

Option 1 is lower risk (no directory move). Option 2 is cleaner for convention compliance. Either works — the `plugin.json` path override is documented in official Claude Code specs.

---

## Sources

- [Claude Code Plugins Reference](https://code.claude.com/docs/en/plugins-reference) — HIGH confidence; official Anthropic documentation, fetched 2026-03-01
- [Claude Code Plugin Marketplaces](https://code.claude.com/docs/en/plugin-marketplaces) — HIGH confidence; official Anthropic documentation, fetched 2026-03-01
- [Claude Code Skills](https://code.claude.com/docs/en/skills) — HIGH confidence; official Anthropic documentation, fetched 2026-03-01
- [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks) — HIGH confidence; official Anthropic documentation, fetched 2026-03-01
- [obra/superpowers — plugin.json](https://raw.githubusercontent.com/obra/superpowers/main/.claude-plugin/plugin.json) — HIGH confidence; direct file fetch 2026-03-01
- [obra/superpowers — marketplace.json](https://raw.githubusercontent.com/obra/superpowers/main/.claude-plugin/marketplace.json) — HIGH confidence; direct file fetch 2026-03-01
- [obra/superpowers — hooks/hooks.json](https://raw.githubusercontent.com/obra/superpowers/main/hooks/hooks.json) — HIGH confidence; direct file fetch 2026-03-01
- [obra/superpowers — hooks/session-start](https://raw.githubusercontent.com/obra/superpowers/main/hooks/session-start) — HIGH confidence; direct file fetch 2026-03-01
- [obra/superpowers — hooks/run-hook.cmd](https://raw.githubusercontent.com/obra/superpowers/main/hooks/run-hook.cmd) — HIGH confidence; direct file fetch 2026-03-01

---
*Feature research for: Claude Code plugin distribution (Socrates v1.1)*
*Researched: 2026-03-01*

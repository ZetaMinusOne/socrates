# Pitfalls Research

**Domain:** Claude Code plugin distribution — adding `/plugin` distribution to an existing Claude Code skill
**Researched:** 2026-03-01
**Confidence:** HIGH (official Claude Code docs verified; multiple GitHub issues verified against official repo; obra/superpowers implementation inspected)

---

## Critical Pitfalls

### Pitfall 1: SKILL.md Paths Still Reference `.claude/skills/` After Plugin Migration

**What goes wrong:**
The existing SKILL.md has hardcoded paths like `.claude/skills/socrates/protocols/dialectics.opt.cue`. When installed as a plugin, the skill lives at `~/.claude/plugins/cache/socrates-plugin/<version>/skills/socrates/SKILL.md`. Every `Read` tool call in SKILL.md fails with "file not found" because the old relative paths point to a location that no longer exists. Claude encounters the missing-file error on the very first step (the preflight check for `dialectics.opt.cue`), surfaces the setup-required error message, and stops. The skill is completely broken for every installed consumer.

**Why it happens:**
The local skill assumed it would live at `.claude/skills/socrates/` relative to the project root. That assumption is embedded in every file path in SKILL.md (16 paths: dialectics.opt.cue, routing.opt.cue, 13 protocol files, recording.cue). Plugin installation breaks all of them. Developers testing locally with `--plugin-dir` also encounter this because the working directory during skill execution is the user's project, not the plugin directory.

**How to avoid:**
Replace all hardcoded paths in SKILL.md with paths relative to the skill's `SKILL.md` location. Plugins support relative paths from `SKILL.md` itself — use `protocols/dialectics.opt.cue` (not `.claude/skills/socrates/protocols/dialectics.opt.cue`). The `skills/socrates/` directory becomes the skill root after installation. All `Read` directives should reference files within the skill's own directory tree using bare relative paths (no leading `.claude/skills/socrates/` prefix). Verify with `--plugin-dir` before publishing.

**Warning signs:**
- The preflight check at the top of SKILL.md fires on every invocation ("Setup required: submodule not initialized...")
- `Read` tool calls return "file not found" or "path does not exist" even though the plugin was installed successfully
- Skill works when tested locally via `--plugin-dir` with CWD set to the plugin root, but breaks when installed via marketplace
- Protocol files appear to load in development but not in production installs

**Phase to address:** Phase 1 (plugin scaffold and path migration). This is the first thing to fix — nothing else works until paths resolve correctly.

---

### Pitfall 2: Plugin Copies Files But Not the Submodule — Protocol Files Missing

**What goes wrong:**
The current repo has a `socrates/dialectics/` git submodule pointing to riverline-labs/dialectics. When Claude Code installs the plugin, it copies the plugin directory to its cache (`~/.claude/plugins/cache/`). Git submodules are not followed during this copy — the `dialectics/` directory is either empty or absent in the installed cache. The optimized `.opt.cue` protocol files (which live in `socrates/protocols/`) do get copied, but only if they are committed to git. Any file that is gitignored or only exists in the submodule will be missing.

**Why it happens:**
Plugin installation performs a git clone or directory copy of the plugin source. Submodule directories appear in the directory listing but their contents are only present if `git submodule update --init` has been run. In a freshly cloned repo that consumers never touch beyond `/plugin install`, submodules are never initialized. This is documented behavior: "Installed plugins cannot reference files outside their directory" and submodule contents are not automatically fetched.

**How to avoid:**
Pre-build strategy: run `strip_cue.py` before committing and commit the output to `socrates/protocols/`. The pre-built `.opt.cue` files must be in git (not gitignored, not in the submodule). Consumers install the plugin and get the pre-built files without any submodule interaction. Add a CI check (or at minimum a pre-commit reminder) that verifies `protocols/` is up to date before any release. The submodule remains in the repo for development use only — it is a build-time dependency, not a runtime dependency for consumers.

**Warning signs:**
- `ls socrates/protocols/` shows `.opt.cue` files locally but the installed plugin cache has an empty `protocols/` directory
- Fresh install from the marketplace produces "file not found" on the first protocol `Read` call
- `git ls-files socrates/protocols/` returns nothing (files are not committed)
- Running `git status` after `strip_cue.py` shows generated files as untracked (not staged)

**Phase to address:** Phase 1 (build step and file commit). Resolve before any marketplace testing. Verify by doing a clean install from a fresh repo clone.

---

### Pitfall 3: SessionStart Hook Does Not Fire for Brand New Conversations

**What goes wrong:**
The session-start hook is designed to inject skill context before the agent's first turn. It works for `/clear`, `/compact`, and `--resume` sessions — but silently fails for brand new interactive conversations. The hook executes, its output is discarded, and Claude starts the session with no injected context. This is a confirmed bug in Claude Code's `cli.js` where `qz("startup")` is never called for new sessions (only for the three resumption paths).

**Why it happens:**
The `wm6()` function that initializes new conversations only replays hook responses from message history and never calls the SessionStart hook execution path. This is a known, reported issue (GitHub issue #10373) that has not been resolved as of early 2026. The symptom is invisible — the hook runs (exit code 0, no errors) but its `additionalContext` output is never processed into Claude's context.

**How to avoid:**
Do not rely on SessionStart as the sole mechanism for injecting skill context into new sessions. Design the hook to be a "nice to have" enhancement, not a requirement. The skill must work correctly without the hook firing. As a workaround, document that users can run `/clear` immediately after starting a new session to trigger the hook. For context injection that must reliably work, use SKILL.md's invocation mechanism (the skill is always loaded when users run `/socrates`) rather than the session hook.

**Warning signs:**
- Hook script exits with code 0 and produces valid JSON, but Claude shows no sign of having received the context
- Behavior is inconsistent: session after `/clear` has context, fresh session does not
- Testing the hook in isolation works but end-to-end behavior differs by session type

**Phase to address:** Phase 3 (session hook). Design around this limitation from the start. Do not build the session hook as a hard dependency for skill functionality.

---

### Pitfall 4: Hook Script Line Endings Break Bash on Windows Checkout

**What goes wrong:**
Shell scripts with Windows CRLF line endings (`\r\n`) fail on Git Bash on Windows with errors like `$'\r': command not found` or scripts that produce malformed JSON output. The scripts appear correct in any editor but fail at runtime. This can also corrupt JSON output from hooks when the `\r` character is included in JSON strings, causing Claude Code to silently discard the hook output.

**Why it happens:**
Git on Windows defaults to `core.autocrlf=true`, which converts LF to CRLF on checkout. Shell scripts committed on macOS/Linux with LF endings get CRLF endings on Windows. Bash on Windows (Git Bash, WSL) requires LF line endings in scripts. Without explicit `.gitattributes` configuration, each developer's git config determines what line endings they get — meaning scripts work on the committing developer's machine but fail on Windows consumers.

**How to avoid:**
Add a `.gitattributes` file that forces LF line endings for all shell scripts:
```
*.sh text eol=lf
hooks/*.json text eol=lf
```
Commit this before adding any hook scripts. The obra/superpowers project required this fix after discovering the issue in production (added `.gitattributes` as an explicit fix). Also set a shebang on every script: `#!/usr/bin/env bash` (not `/bin/bash` which may not exist on all Windows Git Bash installations).

**Warning signs:**
- Hook scripts work on macOS/Linux but fail silently on Windows
- `file session-start.sh` shows "CRLF line terminators" instead of "LF line terminators"
- Windows users report hook not injecting context
- JSON output from hooks contains `\r` characters that break parsing

**Phase to address:** Phase 3 (session hook). Set `.gitattributes` before writing any hook scripts.

---

### Pitfall 5: Async Hook Execution Creates Race Condition — Bootstrap Context Missing

**What goes wrong:**
If the session-start hook is configured as async (or executed non-blocking), it may not complete before Claude processes its first user turn. Claude responds to the user's initial message before the hook's injected context arrives in the conversation. The skill context is injected mid-conversation (or never injected if the hook times out), causing the first response to be uninformed and potentially incorrect.

**Why it happens:**
Async execution is tempting because synchronous hooks delay session startup. This is a known failure mode: obra/superpowers v4.2.0 introduced async execution to reduce Windows terminal freeze time, then v4.3.0 reverted to synchronous after discovering "async execution created race condition — hook could fail to complete before agent's first turn, leaving bootstrap context missing." The session-start hook's value is only realized if it completes before Claude's first response.

**How to avoid:**
Use synchronous hook execution (the default). Accept the brief startup delay rather than risking missed context injection. If performance is a concern, optimize the hook script itself (faster JSON generation, minimal file reads) rather than making execution async. Keep the session hook fast: read only what is needed, avoid expensive shell operations, and pre-process content at build time rather than at hook runtime.

**Warning signs:**
- Hook output appears in the conversation after Claude's first response
- Context injection is intermittent — works sometimes, fails other times (timing-dependent)
- On slow machines or Windows, context injection succeeds less often

**Phase to address:** Phase 3 (session hook). Default to synchronous and only consider async after measuring actual startup delay.

---

### Pitfall 6: Plugin Name Collides With Marketplace Name — Silent Install Failure on Linux

**What goes wrong:**
When the `name` field in `.claude-plugin/plugin.json` matches the marketplace name, plugin installation fails on Linux with an opaque error: `EXDEV: cross-device link not permitted`. The plugin appears to install successfully in the UI but is not accessible. On macOS this silently succeeds but may produce incorrect paths.

**Why it happens:**
The installer stages plugin files at `cache/<plugin.json name>`, then renames the staging directory to `cache/<marketplace>/<plugin>/<version>`. When the plugin name matches the marketplace name, the final destination path falls inside the staging path. This triggers a fallback using `os.tmpdir()` for the intermediate step, which crosses filesystem boundaries on Linux systems with tmpfs `/tmp` (Ubuntu, Fedora, Arch defaults). The result is an EXDEV error. This is documented in GitHub issue #24389 with no fix timeline.

**How to avoid:**
Give the plugin a name that differs from the marketplace name. For Socrates: if the marketplace is named `socrates` (or the repo is `riverline-labs/socrates`), name the plugin `socrates-skill` or `socrates-dialectics` in `plugin.json`. This is a simple naming convention but easy to miss when the plugin and marketplace live in the same repo.

**Warning signs:**
- Plugin install reports success but the plugin does not appear in `/plugin list`
- `EXDEV: cross-device link not permitted` errors in Claude Code debug logs on Linux
- Plugin works on macOS for the author but fails for Linux users

**Phase to address:** Phase 1 (plugin scaffold). Set non-colliding names in `plugin.json` from the beginning.

---

### Pitfall 7: Relative Path Sources Fail When Marketplace Added via URL Instead of Git

**What goes wrong:**
The single-repo approach requires the marketplace to reference the plugin via a relative path: `"source": "./socrates"`. When a user adds the marketplace via a direct URL to `marketplace.json` (e.g., `https://raw.githubusercontent.com/.../marketplace.json`), relative paths cannot resolve — only the JSON file is fetched, not the rest of the repo. Plugin installation fails with "Plugin directory not found."

**Why it happens:**
URL-based marketplace addition only downloads the `marketplace.json` file itself. Relative paths in the plugin source fields are relative to the repository root — they work when the entire repo is cloned (via git URL or GitHub source), but not when only the manifest file is fetched via HTTP. This is documented in the official Claude Code plugin marketplace docs under "Troubleshooting."

**How to avoid:**
Use the GitHub source type in the marketplace.json plugin entry rather than a relative path, so the plugin is fetched independently:
```json
{
  "name": "socrates-skill",
  "source": {
    "source": "github",
    "repo": "owner/socrates"
  }
}
```
Alternatively, document that users must add the marketplace using the git URL form (`/plugin marketplace add owner/socrates`) not a direct URL. The GitHub source approach is more robust and works regardless of how the marketplace was added.

**Warning signs:**
- Marketplace adds successfully but plugin installation produces "Plugin directory not found"
- Works for users who clone the repo, fails for users who add via URL
- Error occurs consistently when the marketplace URL starts with `https://raw.githubusercontent.com/`

**Phase to address:** Phase 1 (marketplace manifest design). Choose the GitHub source type from the start rather than retrofitting later.

---

### Pitfall 8: Plugin Cache Staleness — Updated Files Not Reflected After Version Bump

**What goes wrong:**
A developer updates protocol files (re-runs `strip_cue.py`, commits new `.opt.cue` files), bumps the version in `plugin.json`, and pushes. Existing users run `/plugin update` and the plugin reports as updated — but the cached files are the old version. The plugin appears to update (version number changes) without actually refreshing file content.

**Why it happens:**
This is a documented bug: Claude Code updates the `installed_plugins.json` version number and refreshes the marketplace clone but does not re-download the actual plugin files unless the cache directory is explicitly invalidated. The symptom is that the plugin "version" is updated but protocol files reflect the old content. Issue #14061 and #19197 both track this behavior as unfixed.

**How to avoid:**
Until the bug is fixed, advise users to manually clear the plugin cache after updates: `rm -rf ~/.claude/plugins/cache/socrates-skill` and reinstall. Document this in the plugin README. For pre-built protocol files specifically, include a version comment at the top of each `.opt.cue` file so users can verify which version they are running. Consider embedding the build date in `dialectics.opt.cue` as a comment.

**Warning signs:**
- `/plugin update` reports success but protocol behavior is unchanged
- Version in cache metadata reflects new version but file `mtime` timestamps are old
- Users report bugs that the developer thought were fixed in the latest release

**Phase to address:** Phase 2 (pre-built protocol files build step). Document the cache clearing workaround alongside the update instructions.

---

### Pitfall 9: Plugin Skills Use Namespace Prefix — `/socrates:socrates` Not `/socrates`

**What goes wrong:**
The local skill is invoked as `/socrates`. After packaging as a plugin with `name: "socrates"` in `plugin.json`, the skill becomes `/socrates:socrates` (plugin namespace + skill directory name). Existing documentation, user muscle memory, and SKILL.md internal references that use the `/socrates` command format all break. There is also a known bug (issue #17271, open as of Feb 2026) where plugin skills with a `name` field in their frontmatter lose their namespace prefix entirely and appear inconsistently in autocomplete.

**Why it happens:**
Plugin skills are always namespaced: `<plugin-name>:<skill-name>`. This prevents conflicts when multiple plugins define skills with the same name. The convention is different from local standalone skills which use bare names. When a skill SKILL.md has a `name` field in its YAML frontmatter, there is currently a bug where the name overrides the namespace prefix, making the command appear as `/socrates` (from the frontmatter `name` field) but without its namespace, causing inconsistency in the plugin command list.

**How to avoid:**
Two strategies:
1. **Accept the namespace**: Name the plugin `socrates-plugin` or `socrates-dialectics` so the invocation becomes `/socrates-plugin:socrates` or abbreviate by naming the skill directory `sk` for `/socrates-plugin:sk`. Document the new command in the README.
2. **Remove the `name` field from SKILL.md frontmatter**: The `name` field in the existing SKILL.md frontmatter is what currently registers it as `/socrates` for the local skill. If omitted in the plugin version, the skill directory name becomes the command. Name the skill directory `socrates` within the plugin and the plugin `socrates-skill` — this produces `/socrates-skill:socrates`.

Test the exact invocation form with `--plugin-dir` before publishing, since this behavior has active bugs.

**Warning signs:**
- Skill works when invoked directly but does not appear in `/help` command list
- Invocation produces "unknown command" error
- Command appears in autocomplete without namespace prefix (symptom of frontmatter name field conflict)
- README says `/socrates` but the actual command is `/plugin-name:socrates`

**Phase to address:** Phase 1 (plugin scaffold). Name the plugin and skill directory deliberately and test the invocation form before building anything else.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Keep old SKILL.md paths (`.claude/skills/socrates/...`) as-is | No migration work | All `Read` calls fail for every consumer install | Never — must be updated before any plugin testing |
| Rely on SessionStart hook for mandatory context injection | Elegant initialization | Context missing for all new sessions (confirmed bug) | Never for mandatory context; OK for optional enhancement |
| Use relative path source in marketplace.json | Simpler manifest | Fails for URL-added marketplaces; less robust than GitHub source type | Only if you control how users add the marketplace (git clone only) |
| Skip `.gitattributes` for shell scripts | Less setup overhead | CRLF breaks hook scripts on Windows; silent failure | Never — add before writing first script |
| Use same name for plugin and marketplace | Consistent naming | EXDEV install failure on Linux tmpfs | Never — use distinct names |
| Keep submodule in place and don't pre-build | Less build infrastructure | Protocol files missing for all consumers | Never — pre-build is required for plugin distribution |
| Set version in both `plugin.json` and `marketplace.json` | Explicit everywhere | `plugin.json` wins silently; confusing version mismatch | Never — set version in one place only |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Plugin cache (`~/.claude/plugins/cache/`) | Assuming relative paths from SKILL.md work the same as in local development | Test with `--plugin-dir`, then verify with a clean install from the marketplace |
| Git submodule (dialectics) | Shipping the plugin expecting consumers to initialize the submodule | Pre-build all `.opt.cue` files and commit them to git before tagging any release |
| `$CLAUDE_PLUGIN_ROOT` in hooks | Using hardcoded paths or relative paths in hook `command` fields | Use `${CLAUDE_PLUGIN_ROOT}/hooks/session-start.sh` in every hook command reference |
| SessionStart hook and new conversations | Treating hook output as guaranteed context for all sessions | Design skill to be fully functional without hook context; hook is enhancement only |
| Marketplace relative path resolution | Setting `"source": "./socrates"` in marketplace.json | Test with both `/plugin marketplace add ./path` AND `/plugin marketplace add owner/repo` |
| Plugin namespace vs skill command name | Assuming `/socrates` works after plugin packaging | Explicitly test the namespaced invocation form; document the correct command |
| SKILL.md `name` frontmatter field | Leaving `name: socrates` in SKILL.md when converting to plugin | The `name` field conflicts with plugin namespace resolution (bug #17271); test carefully |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Slow session hook causes startup delay | Users wait 5-30 seconds for every new session before Claude responds | Keep hook fast: read only one small file, use parameter substitution not loops for JSON escaping | Every session — linear with hook script complexity |
| JSON escaping loop in hook script | Hook takes 60+ seconds on Windows Git Bash | Use bash parameter substitution (`${s//old/new}`) instead of character loops (7x faster on macOS, dramatic improvement on Windows) | Immediately on Windows; noticeable on macOS with large files |
| Protocol files not committed to git — fetched at hook time | Hook reads from submodule which isn't initialized; fails silently or takes network round-trip | Pre-build files committed to git; hook reads only from `${CLAUDE_PLUGIN_ROOT}` | Every fresh install |
| Plugin cache not invalidated | Stale protocol files served after updates | Document cache-clearing procedure; embed version marker in pre-built files | After any update to protocol files |

---

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Hook scripts with unsafe variable expansion | Command injection if hook receives untrusted input | Quote all variables in bash; use `jq` to parse JSON input rather than string manipulation |
| Committing secrets in pre-built protocol files | Secrets distributed to all plugin consumers | Verify pre-built files contain only stripped CUE schema content; no API keys, tokens, or personal data |
| Auto-update without pinning version | Marketplace updates can push new code to all users' machines without explicit consent | Pin plugin source to a specific `sha` in marketplace.json for production use |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Command name changes from `/socrates` to `/plugin-name:socrates` | Every user has to relearn the invocation; documentation is wrong | Choose naming strategy before publishing, document the exact command prominently in README |
| Error message still says "run git submodule update" | Consumers cannot fix this (they don't have the submodule) | Update SKILL.md preflight error message to say "please reinstall the plugin" or "protocol files are missing — this is a packaging issue" |
| Session hook works on `/clear` but not fresh sessions | Context injection feels unreliable; users lose trust | Either document the `/clear` workaround or remove the hook until the upstream bug is fixed |
| Plugin shows as installed but skill not accessible | User confusion, wasted troubleshooting time | Test the install-list-invoke cycle end-to-end before publishing |

---

## "Looks Done But Isn't" Checklist

- [ ] **Path migration:** Every `Read` path in SKILL.md uses a path relative to the skill directory — not `.claude/skills/socrates/...`. Verify by grepping SKILL.md for `.claude/skills/`.
- [ ] **Pre-built files committed:** `git ls-files socrates/protocols/` returns all 15 `.opt.cue` files (13 protocols + dialectics + routing). No file is only in the submodule or gitignored.
- [ ] **Clean install test:** Delete `~/.claude/plugins/cache/socrates-*` entirely, reinstall via marketplace, and run `/socrates "test problem"` successfully without any file-not-found errors.
- [ ] **Plugin name vs marketplace name:** `plugin.json` `name` field differs from the marketplace `name` field. Verified by checking both files side-by-side.
- [ ] **Skill invocation tested:** Confirmed the exact slash command that works after plugin install. Written in the README. Not assumed — tested.
- [ ] **Hook script line endings:** `file hooks/session-start.sh` shows "LF" not "CRLF". `.gitattributes` covers all `.sh` files.
- [ ] **Hook as enhancement only:** Skill works correctly end-to-end when the session hook produces no output (simulate by setting hook exit code 1 temporarily).
- [ ] **Linux install test (or simulation):** Plugin install tested on Linux or with a fresh Ubuntu docker image. No EXDEV errors. Plugin appears in `/plugin list`.
- [ ] **Version in one place:** `version` field exists in either `plugin.json` OR the marketplace entry, not both.
- [ ] **`${CLAUDE_PLUGIN_ROOT}` in all hooks:** Every hook `command` field uses `${CLAUDE_PLUGIN_ROOT}` not a relative or absolute path. Verified by reading hooks.json.

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| SKILL.md paths still reference `.claude/skills/` | LOW | Global find-and-replace in SKILL.md; test with `--plugin-dir` immediately; re-publish |
| Submodule files missing from cache | MEDIUM | Run `strip_cue.py`, commit all output files, bump version, re-publish; existing users reinstall |
| SessionStart hook context not injecting | LOW | Accept the limitation; document `/clear` workaround; remove hook dependency from skill logic |
| Plugin name collision (EXDEV on Linux) | LOW | Rename plugin in `plugin.json`; update marketplace.json accordingly; re-publish |
| Relative path source breaking URL-added marketplace | LOW | Switch to GitHub source type in marketplace.json; re-publish |
| Cache staleness after update | LOW | Document cache-clearing procedure: `rm -rf ~/.claude/plugins/cache/socrates-*` then reinstall |
| Wrong slash command name in docs | LOW | Update README with correct namespaced command; re-publish |
| Hook script CRLF on Windows | LOW | Add `.gitattributes`, re-commit scripts with LF endings, re-publish |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| SKILL.md paths still reference `.claude/skills/` | Phase 1: Plugin scaffold + path migration | `grep -r '.claude/skills/' socrates/SKILL.md` returns empty |
| Submodule files not committed | Phase 1: Build step + file commit | `git ls-files socrates/protocols/ | wc -l` equals 15 |
| Plugin name collision with marketplace name | Phase 1: Plugin manifest creation | `plugin.json` name differs from marketplace.json name |
| Skill namespace breaking invocation | Phase 1: Plugin scaffold | Test `/plugin-name:skill-name` with `--plugin-dir` before any other work |
| Relative path source failing | Phase 1: Marketplace manifest | Test marketplace add via both `./path` and GitHub source; use GitHub source in production |
| SessionStart hook not firing for new sessions | Phase 3: Session hook | Design hook as enhancement; test skill with hook disabled |
| Hook CRLF line endings breaking Windows | Phase 3: Session hook | `.gitattributes` committed before first hook script |
| Async hook race condition | Phase 3: Session hook | Hook runs synchronously by default; do not add `async: true` |
| Plugin cache staleness | Phase 2: Pre-built protocol files | Document cache-clearing; embed version marker in pre-built files |
| Version defined in two places | Phase 1: Plugin manifest creation | Set version only in `plugin.json`; omit from marketplace.json |

---

## Sources

- [Claude Code Plugin Marketplaces — Official Docs](https://code.claude.com/docs/en/plugin-marketplaces) — HIGH confidence, official Anthropic documentation verified 2026-03-01
- [Claude Code Plugins — Official Docs](https://code.claude.com/docs/en/plugins) — HIGH confidence, official Anthropic documentation verified 2026-03-01
- [Claude Code Plugins Reference — Official Docs](https://code.claude.com/docs/en/plugins-reference) — HIGH confidence, includes caching behavior, `${CLAUDE_PLUGIN_ROOT}`, hook event types
- [SessionStart hooks not working for new conversations — GitHub Issue #10373](https://github.com/anthropics/claude-code/issues/10373) — HIGH confidence, confirmed bug with root cause identified in source code
- [Plugin.json name collision with marketplace name — GitHub Issue #24389](https://github.com/anthropics/claude-code/issues/24389) — HIGH confidence, confirmed EXDEV failure mode with workaround
- [Plugin path resolution uses marketplace.json file path — GitHub Issue #11278](https://github.com/anthropics/claude-code/issues/11278) — HIGH confidence, documented bug with root cause
- [Skill plugin scripts fail with relative path resolution — GitHub Issue #11011](https://github.com/anthropics/claude-code/issues/11011) — HIGH confidence, first-execution failure documented
- [Project skill visible in slash command but plugin skill isn't — GitHub Issue #17271](https://github.com/anthropics/claude-code/issues/17271) — HIGH confidence, open bug with analysis of `name` field conflict, Feb 2026
- [Plugin marketplace installs skills to wrong directory — GitHub Issue #10364](https://github.com/anthropics/claude-code/issues/10364) — HIGH confidence, closed as duplicate of #10113, confirmed path mismatch
- [Plugin update does not invalidate plugin cache — GitHub Issue #14061](https://github.com/anthropics/claude-code/issues/14061) — HIGH confidence, confirmed stale cache behavior
- [obra/superpowers DeepWiki: Claude Code Slash Commands and Hooks](https://deepwiki.com/obra/superpowers/5.1-claude-code:-slash-commands-and-hooks) — MEDIUM confidence, documents real-world async race condition and Windows line endings fix encountered in production
- [Claude Code Session Hooks — claudefa.st](https://claudefa.st/blog/tools/hooks/session-lifecycle-hooks) — MEDIUM confidence, documents SessionStart matcher types and context delivery mechanism

---
*Pitfalls research for: Socrates v1.1 — Plugin distribution for existing Claude Code skill*
*Researched: 2026-03-01*

# Phase 8: Session Hook - Research

**Researched:** 2026-03-01
**Domain:** Claude Code plugin SessionStart hooks, cross-platform shell script execution, YAML frontmatter extraction
**Confidence:** HIGH (official docs verified) / MEDIUM (bug status, workarounds)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **Injected content scope:** Lightweight primer only — inject the YAML frontmatter extracted from SKILL.md (~200 tokens). Full SKILL.md content (~4K tokens) is NOT injected. Frontmatter is dynamically extracted at runtime by parsing SKILL.md, not hardcoded. Fixed path: `${CLAUDE_PLUGIN_ROOT}/socrates/skills/socrates/SKILL.md`
- **Trigger events:** Matcher pattern: `startup|resume|clear`. No `compact` — context is already present in the conversation during compaction. `resume` included to ensure context survives session serialization.
- **Hook failure behavior:** Silent failure — return empty/no `additionalContext`, session starts normally. No stderr warnings, no blocking, no error messages from the hook. No frontmatter validation in the script — if the file exists and has a frontmatter block, return it. No explicit timeout — rely on Claude Code's built-in hook timeout.
- **Reference implementation:** Follow the obra/superpowers pattern for run-hook.cmd and hooks.json.
- **Extensionless script:** `session-start` (no .sh extension) — required because Claude Code on Windows auto-prepends "bash" to .sh filenames.

### Claude's Discretion

- Exact frontmatter parsing approach in the session-start script (sed, awk, or other)
- run-hook.cmd polyglot wrapper implementation details (adopt superpowers pattern)
- .gitattributes line ending enforcement scope and placement
- Hook script structure and error handling internals

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| HOOK-01 | User opens a new Claude Code session and the skill context is automatically injected via SessionStart hook | SessionStart event + `hookSpecificOutput.additionalContext` JSON output pattern confirmed in official docs; bug #10373 means new conversations may not fire — design as enhancement not guarantee |
| HOOK-02 | Session-start hook works on macOS, Linux, and Windows via cross-platform polyglot wrapper (run-hook.cmd) | Extensionless script approach confirmed; BASH_SOURCE[0] workaround for CLAUDE_PLUGIN_ROOT; Windows path issues documented with clear solution |
| HOOK-03 | Hook scripts use LF line endings enforced by .gitattributes to prevent Windows checkout breakage | .gitattributes pattern with `*.sh text eol=lf` and `hooks/* text eol=lf` confirmed standard approach |
</phase_requirements>

## Summary

Phase 8 implements a SessionStart hook that injects the SKILL.md YAML frontmatter as `additionalContext` when a user opens, resumes, or clears a Claude Code session. The hook wires three files: `hooks/hooks.json` (event configuration), `hooks/session-start` (extensionless bash script), and `.gitattributes` (LF enforcement).

The primary technical challenge is a cluster of known bugs that affect plugin hooks specifically: (1) `hookSpecificOutput.additionalContext` from plugin-defined hooks is not reliably surfaced to Claude (issue #16538, OPEN), (2) SessionStart does not fire for brand new conversations at all (issue #10373, OPEN), and (3) `CLAUDE_PLUGIN_ROOT` is not set in the hook's environment (issue #24529, OPEN). All three are documented in STATE.md as known blockers and guide the design: the skill must remain self-sufficient without the hook, and the hook path must be derived via `BASH_SOURCE[0]` instead of `CLAUDE_PLUGIN_ROOT`.

The obra/superpowers project has already solved the cross-platform execution problem at scale. Their approach: an extensionless `session-start` script (no `.sh`) avoids Claude Code 2.1.x's auto-`bash`-prepend behavior that breaks polyglot `.cmd` wrappers. The `BASH_SOURCE[0]` pattern derives the plugin root correctly from inside the script. `.gitattributes` enforces LF endings so the script isn't CRLF-corrupted on Windows checkout. This is the reference implementation pattern to follow.

**Primary recommendation:** Build three files exactly as the CONTEXT.md specifies. Treat the hook as a best-effort enhancement — test on macOS/Linux, note the known new-conversation bug limitation, and document that `/clear` is the reliable trigger while new conversations may not get context.

## Standard Stack

### Core
| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| Bash | System (3.2+) | Hook script runtime | Only runtime guaranteed present across macOS/Linux/Windows-Git |
| `awk` | System | YAML frontmatter extraction | POSIX-portable, no dependencies, faster than Python one-liner |
| Windows Batch (cmd.exe) | System | Polyglot wrapper entry point | Required for Windows .cmd invocation to locate bash |
| `.gitattributes` | Git built-in | LF enforcement | Only reliable cross-platform line ending solution |

### Supporting
| Tool | Purpose | When to Use |
|------|---------|-------------|
| `printf` | JSON construction (vs echo) | Safer than echo for control characters; use for hookSpecificOutput JSON |
| `jq` | JSON parsing from stdin | Not needed here — SessionStart input is not used by this hook |
| BASH_SOURCE[0] | Path self-location | Primary workaround for CLAUDE_PLUGIN_ROOT being unset |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| awk frontmatter extraction | sed / python / grep | awk is POSIX, available on all platforms including minimal Windows Git Bash; sed on macOS (BSD) requires different flags than GNU sed |
| extensionless script | session-start.sh | .sh extension causes Claude Code 2.1.x to auto-prepend `bash`, breaking polyglot wrapper; extensionless avoids this entirely |
| `hookSpecificOutput.additionalContext` | plain stdout text | Official pattern; plain stdout also works and is more reliable across plugin bugs — either is valid, but official JSON pattern is preferred |

## Architecture Patterns

### Required File Structure
```
socrates/                       (plugin root — where .claude-plugin/ lives)
├── .claude-plugin/
│   └── plugin.json
├── hooks/
│   ├── hooks.json              (NEW — event wiring)
│   ├── session-start           (NEW — extensionless bash script)
│   └── run-hook.cmd            (NEW — Windows polyglot wrapper, if needed)
└── skills/
    └── socrates/
        └── SKILL.md            (EXISTING — frontmatter source)
.gitattributes                  (NEW — at repo root OR socrates/ root)
```

Note: `hooks/` must be at the plugin root (same level as `.claude-plugin/`), not inside `.claude-plugin/`. The plugin root is `socrates/`.

### Pattern 1: hooks.json Plugin Format

Plugin `hooks/hooks.json` requires a top-level `"hooks"` wrapper (unlike settings files which use direct event keys). An optional top-level `"description"` field is supported.

```json
// Source: https://code.claude.com/docs/en/hooks (Reference scripts by path section)
{
  "description": "Inject Socrates skill context at session start",
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume|clear",
        "hooks": [
          {
            "type": "command",
            "command": "\"${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd\" session-start"
          }
        ]
      }
    ]
  }
}
```

**Critical finding on CLAUDE_PLUGIN_ROOT in hooks.json command field:** The official docs show `${CLAUDE_PLUGIN_ROOT}` being used in hook command strings (e.g., `"command": "${CLAUDE_PLUGIN_ROOT}/scripts/format.sh"`). This is expanded by Claude Code when building the command string — it is NOT the same as the environment variable being set in the hook's execution environment. The environment variable bug (#24529) means the script cannot rely on `$CLAUDE_PLUGIN_ROOT` as a shell variable inside the script itself, but the command path expansion in `hooks.json` works correctly.

### Pattern 2: BASH_SOURCE[0] Path Derivation

```bash
# Source: obra/superpowers session-start, confirmed by STATE.md decision
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SKILL_PATH="${PLUGIN_ROOT}/skills/socrates/SKILL.md"
```

`${BASH_SOURCE[0]:-$0}` handles the case where `BASH_SOURCE` is unbound (some execution contexts in Claude Code).

### Pattern 3: YAML Frontmatter Extraction

```bash
# Extract content between first --- pair (awk counter approach — POSIX, macOS-safe)
frontmatter=$(awk '/^---$/{c++;next} c==1{print}' "$SKILL_PATH")
```

Tested against the actual SKILL.md. Output:
```
name: socrates
description: Apply structured dialectic reasoning...
argument-hint: "<describe your problem>"
disable-model-invocation: true
allowed-tools: Read
```

Alternative extraction approaches (sed) are NOT portable to macOS BSD sed without flags differences — use awk.

### Pattern 4: JSON Escaping via Bash Parameter Substitution

```bash
# Escape special JSON characters (no external tools needed)
escaped="${frontmatter//\\/\\\\}"   # backslashes first
escaped="${escaped//\"/\\\"}"        # double quotes
escaped="${escaped//$'\n'/\\n}"      # newlines to \n literal
escaped="${escaped//$'\r'/}"         # strip carriage returns
escaped="${escaped//$'\t'/\\t}"      # tabs to \t literal
```

Tested against actual frontmatter content — produces valid JSON string. The `argument-hint: "<describe your problem>"` contains double quotes that correctly escape to `\"`.

### Pattern 5: SessionStart JSON Output

```bash
# Source: https://code.claude.com/docs/en/hooks (SessionStart decision control)
printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}' "$escaped"
exit 0
```

The official `hookSpecificOutput.additionalContext` schema confirmed:
```json
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "string added to Claude's context"
  }
}
```

### Pattern 6: Silent Failure

Per locked decisions, hook fails silently. Implementation:

```bash
# If SKILL.md not found or empty frontmatter — exit 0 with no output
if [ ! -f "$SKILL_PATH" ]; then
  exit 0
fi
frontmatter=$(awk '/^---$/{c++;next} c==1{print}' "$SKILL_PATH")
if [ -z "$frontmatter" ]; then
  exit 0
fi
```

Exit 0 with no stdout = hook runs but contributes no context. Session continues normally.

### Pattern 7: run-hook.cmd Polyglot Wrapper

The superpowers pattern for Windows compatibility. A `.cmd` file that is simultaneously valid Windows batch AND (mostly ignored) bash:

```batch
@echo off
:: This file is both a Windows batch file and a bash polyglot
:: Claude Code on Windows calls hooks as: run-hook.cmd <scriptname>
:: Find bash and delegate to the extensionless session-start script
set SCRIPT_DIR=%~dp0

:: Try common Git for Windows bash locations
for %%B in (
  "%ProgramFiles%\Git\bin\bash.exe"
  "%ProgramFiles(x86)%\Git\bin\bash.exe"
  "%LocalAppData%\Programs\Git\bin\bash.exe"
  "C:\Program Files\Git\bin\bash.exe"
) do (
  if exist %%B (
    %%B "%SCRIPT_DIR%%~1"
    exit /b %errorlevel%
  )
)

:: Fallback: try PATH
bash "%SCRIPT_DIR%%~1" 2>nul
exit /b %errorlevel%
```

**Current status of run-hook.cmd:** The superpowers project deprecated `run-hook.cmd` after Claude Code 2.1.x changed behavior. However, the CONTEXT.md says "adopt superpowers pattern" which as of their current version means using the extensionless script directly and referencing it directly in hooks.json (NOT via run-hook.cmd). The research below clarifies this.

### Pattern 8: .gitattributes LF Enforcement

```
# .gitattributes — enforce LF on hook scripts
# Source: Standard Git practice + superpowers pattern
* text=auto
*.sh text eol=lf
hooks/* text eol=lf
```

`* text=auto` normalizes all text files. The specific overrides force LF even on Windows checkout for scripts that must not have CRLF.

### Anti-Patterns to Avoid

- **Using `echo` for JSON output:** `printf` is safer — `echo` behavior with escape sequences varies by shell/platform.
- **Relying on `$CLAUDE_PLUGIN_ROOT` as a shell variable inside the script:** It is NOT set in the hook execution environment (bug #24529). Use `BASH_SOURCE[0]` instead.
- **Using `.sh` extension on the hook script:** Claude Code 2.1.x auto-prepends `bash` to `.sh` files which breaks the polyglot pattern. Use extensionless `session-start`.
- **Using `set -euo pipefail` with silent failure design:** `set -e` will cause exit 1 on any failure, which shows as a non-blocking error in verbose mode. Either use error trapping or omit `set -e`.
- **Checking `CLAUDE_PLUGIN_ROOT` in the command path in hooks.json:** This IS expanded correctly by Claude Code when building the command string. This is NOT the same as the env var bug.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| YAML parsing | Full YAML parser | `awk` counter pattern | YAML parsing from scratch has edge cases; frontmatter extraction with awk counter is 3 lines and handles the exact format |
| JSON escaping | Character-by-character loop | Bash parameter substitution `${var//old/new}` | The superpowers project found 7x speedup on macOS, dramatic improvement on Windows Git Bash using substitution vs loops |
| Cross-platform path resolution | Complex platform detection | `BASH_SOURCE[0]` + `cd "$(dirname ...)" && pwd` | Reliable canonical path resolution |

**Key insight:** This entire hook is a small bash script. Complexity comes from the bugs/workarounds, not from the feature itself. Keep it simple.

## Common Pitfalls

### Pitfall 1: CLAUDE_PLUGIN_ROOT Unset in Hook Shell
**What goes wrong:** Script uses `$CLAUDE_PLUGIN_ROOT/skills/socrates/SKILL.md` — path resolves to `/skills/socrates/SKILL.md` (missing prefix). File not found. Silent failure triggered. Hook contributes nothing.
**Why it happens:** Bug #24529 — Claude Code's hook executor does not set `CLAUDE_PLUGIN_ROOT` as an environment variable in the hook's shell, despite expanding it in the command string in hooks.json.
**How to avoid:** Always derive plugin root from `BASH_SOURCE[0]`, never from `$CLAUDE_PLUGIN_ROOT`.
**Warning signs:** Hook executes (can be verified with logging) but Claude has no additional context.

### Pitfall 2: .sh Extension Breaking Windows Execution
**What goes wrong:** `hooks/session-start.sh` referenced in hooks.json. On Windows, Claude Code 2.1.x auto-prepends `bash`, turning the command into `bash "session-start.sh"`. If also routed via run-hook.cmd, becomes `bash "run-hook.cmd" session-start.sh` — bash cannot execute `.cmd` files.
**Why it happens:** Claude Code 2.1.x changed Windows hook execution to auto-detect `.sh` files.
**How to avoid:** Name the script `session-start` (no extension). Extensionless scripts do not trigger auto-prepend.
**Warning signs:** Windows users see `SessionStart:startup hook error` in verbose mode.

### Pitfall 3: Plugin additionalContext Not Reaching Claude (Bug #16538)
**What goes wrong:** Hook executes correctly, outputs valid JSON with `hookSpecificOutput.additionalContext`, but Claude does not see the context — only receives "SessionStart:Callback hook success: Success".
**Why it happens:** Open bug #16538 — plugin-defined SessionStart hooks' hookSpecificOutput is not properly surfaced. The same hook works when defined in `~/.claude/settings.json`.
**How to avoid:** Cannot be fully avoided — this is an open bug. Two mitigations: (1) plain stdout text also works (non-JSON text to stdout is added as context per official docs), (2) accept that hook works as enhancement only.
**Warning signs:** Hook executes but running `/socrates` still requires Claude to read SKILL.md explicitly.

### Pitfall 4: SessionStart Not Firing for New Conversations (Bug #10373)
**What goes wrong:** User opens a fresh Claude Code session (no previous conversation). SessionStart hook fires on hooks for `compact`, `clear`, and `resume` but NOT for a first-ever new conversation.
**Why it happens:** Open bug #10373 — `qz("startup")` is not called by `wm6()` for brand new interactive conversations. The workaround is to run `/clear` at session start.
**How to avoid:** Design SKILL.md to be self-sufficient. The hook is an enhancement for `/clear` and resume scenarios. Document the limitation.
**Warning signs:** Fresh session does not show hook context injection.

### Pitfall 5: CRLF Line Endings Breaking Bash Scripts on Windows
**What goes wrong:** Script checkout on Windows with CRLF produces `\r` at end of each line inside the script. Bash errors like `/usr/bin/bash: line 1: : command not found` when running the shebang. Script fails silently.
**Why it happens:** Default Windows git config `core.autocrlf=true` converts LF to CRLF on checkout unless overridden by `.gitattributes`.
**How to avoid:** Add `.gitattributes` at repo root with `hooks/* text eol=lf` and `*.sh text eol=lf`.
**Warning signs:** Script works on macOS/Linux but fails on Windows with cryptic bash errors.

### Pitfall 6: macOS BSD sed vs GNU sed in Frontmatter Extraction
**What goes wrong:** Using `sed -n '/^---$/,/^---$/{/^---$/!p}'` — works on Linux (GNU sed) but fails on macOS (BSD sed) with `invalid command code \`.
**Why it happens:** BSD sed and GNU sed have different syntax for range expressions with negation.
**How to avoid:** Use `awk '/^---$/{c++;next} c==1{print}'` — POSIX awk is consistent across all platforms.
**Warning signs:** Frontmatter extraction works in CI (Linux) but fails locally on macOS.

## Code Examples

Verified patterns from testing and official sources:

### Complete session-start Script (reference implementation)

```bash
#!/usr/bin/env bash
# hooks/session-start — extensionless intentionally (Claude Code 2.1.x .sh auto-prepend avoidance)
# Injects SKILL.md YAML frontmatter as additionalContext for SessionStart hook

# Derive plugin root from script location (CLAUDE_PLUGIN_ROOT is unset in hook env, bug #24529)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SKILL_PATH="${PLUGIN_ROOT}/skills/socrates/SKILL.md"

# Silent failure: file missing
if [ ! -f "$SKILL_PATH" ]; then
  exit 0
fi

# Extract YAML frontmatter (content between first --- pair)
# awk counter: increment on ---, skip those lines, print lines when counter==1
frontmatter=$(awk '/^---$/{c++;next} c==1{print}' "$SKILL_PATH")

# Silent failure: no frontmatter found
if [ -z "$frontmatter" ]; then
  exit 0
fi

# JSON-escape the frontmatter (bash parameter substitution — no external tools)
escaped="${frontmatter//\\/\\\\}"    # backslashes first
escaped="${escaped//\"/\\\"}"         # double quotes
escaped="${escaped//$'\n'/\\n}"       # newlines
escaped="${escaped//$'\r'/}"          # strip carriage returns
escaped="${escaped//$'\t'/\\t}"       # tabs

# Output hookSpecificOutput JSON
# Source: https://code.claude.com/docs/en/hooks — SessionStart decision control
printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}' "$escaped"
exit 0
```

### hooks.json (plugin format with wrapper)

```json
{
  "description": "Inject Socrates skill context at session start",
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume|clear",
        "hooks": [
          {
            "type": "command",
            "command": "\"${CLAUDE_PLUGIN_ROOT}/hooks/session-start\""
          }
        ]
      }
    ]
  }
}
```

Note: Quotes around the command handle paths with spaces. `${CLAUDE_PLUGIN_ROOT}` in the command string is expanded by Claude Code's hook dispatcher (this works); it is NOT available as a shell variable inside the script.

### .gitattributes (at repo root)

```
# Normalize line endings
* text=auto

# Force LF for all shell scripts and hook files
*.sh text eol=lf
hooks/* text eol=lf
```

### Frontmatter extraction test (verified against actual SKILL.md)

```bash
# Input: socrates/skills/socrates/SKILL.md (336 lines, starts with ---)
# Command:
awk '/^---$/{c++;next} c==1{print}' SKILL.md
# Output (5 lines, ~200 tokens):
# name: socrates
# description: Apply structured dialectic reasoning...
# argument-hint: "<describe your problem>"
# disable-model-invocation: true
# allowed-tools: Read
```

### SessionStart input schema (what the hook receives on stdin)

```json
{
  "session_id": "abc123",
  "transcript_path": "/Users/.../.claude/projects/.../.jsonl",
  "cwd": "/Users/...",
  "permission_mode": "default",
  "hook_event_name": "SessionStart",
  "source": "startup",
  "model": "claude-sonnet-4-6"
}
```

This hook does NOT need to parse stdin — it outputs static context from SKILL.md regardless of session source.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `run-hook.cmd` polyglot wrapper routing to `.sh` script | Extensionless `session-start` called directly in hooks.json | Claude Code 2.1.x (2025) | Simpler; eliminates the wrapper; `.sh` auto-prepend behavior removed the need |
| `$CLAUDE_PLUGIN_ROOT` env var in hook shell | `BASH_SOURCE[0]` path derivation | Bug #24529 (open as of 2026-03) | Workaround required until Anthropic fixes the hook executor |
| Character-by-character JSON escaping loop | Bash parameter substitution `${var//old/new}` | superpowers v4.x | 7x speedup on macOS, dramatic improvement on Windows Git Bash |

**Deprecated/outdated:**
- `run-hook.cmd` as the primary invocation path: superpowers closed issue #383 by removing the wrapper and calling `session-start.sh` directly. For this project, the extensionless `session-start` is called directly from hooks.json.
- CONTEXT.md says "adopt superpowers pattern for run-hook.cmd" — this should be interpreted as: follow the superpowers pattern (extensionless script, BASH_SOURCE[0], .gitattributes) which now means NOT using run-hook.cmd as the primary dispatch. However, run-hook.cmd may still be needed if `${CLAUDE_PLUGIN_ROOT}` expansion in hooks.json doesn't work on Windows when the path has spaces.

## Open Questions

1. **Does ${CLAUDE_PLUGIN_ROOT} expand in hooks.json command string on all platforms?**
   - What we know: Official docs show this syntax working. The bug (#24529) is about the env var in the shell, not the command string expansion.
   - What's unclear: Whether Windows specifically has issues with `${CLAUDE_PLUGIN_ROOT}` expansion in hooks.json, separate from the env var bug.
   - Recommendation: Test with `--plugin-dir` on macOS first. If command expansion works (hook fires), the approach is correct. Windows testing can follow.

2. **Is run-hook.cmd still needed?**
   - What we know: superpowers deprecated it. Claude Code 2.1.x made `.sh` auto-prepend the issue that broke the wrapper. Extensionless scripts are now the solution.
   - What's unclear: CONTEXT.md says "adopt superpowers pattern for run-hook.cmd" — does this mean implement a wrapper, or follow the pattern (which now omits the wrapper)?
   - Recommendation: Do NOT create run-hook.cmd unless Windows testing reveals that direct extensionless script invocation fails. The CONTEXT.md decision to "follow obra/superpowers pattern" should be interpreted as following the current superpowers approach, which dropped the wrapper.

3. **Plain stdout vs hookSpecificOutput.additionalContext — which is more reliable given bug #16538?**
   - What we know: Plain non-JSON stdout is added as context (per official docs). `hookSpecificOutput.additionalContext` from plugins is broken (bug #16538). The workaround in the bug is to add the hook to `~/.claude/settings.json` instead — not viable for a plugin.
   - What's unclear: Whether plain stdout from a plugin's SessionStart hook has the same injection bug, or only the JSON path is affected.
   - Recommendation: Try `hookSpecificOutput.additionalContext` first (canonical). If verification shows it's broken, add plain stdout fallback. The planner should include a verification step using `--plugin-dir` to empirically confirm injection.

## Sources

### Primary (HIGH confidence)
- [Claude Code Hooks Reference](https://code.claude.com/docs/en/hooks) — SessionStart event schema, hookSpecificOutput format, matcher patterns, exit codes, CLAUDE_PLUGIN_ROOT in command strings
- [Claude Code Plugins Reference](https://code.claude.com/docs/en/plugins-reference) — hooks/hooks.json plugin format, CLAUDE_PLUGIN_ROOT variable, plugin directory structure

### Secondary (MEDIUM confidence)
- [obra/superpowers session-start](https://github.com/obra/superpowers/blob/main/hooks/session-start) — Reference implementation: BASH_SOURCE[0] pattern, JSON escaping via parameter substitution, silent failure design
- [DeepWiki: obra/superpowers hooks](https://deepwiki.com/obra/superpowers/5.1-claude-code:-slash-commands-and-hooks) — run-hook.cmd history, v4.3.0 sync decision, .gitattributes enforcement
- [obra/superpowers issue #313](https://github.com/obra/superpowers/issues/313) — Windows run-hook.cmd deprecation, extensionless solution
- [obra/superpowers issue #383](https://github.com/obra/superpowers/issues/383) — Claude Code 2.1.x breaking change, final recommendation to drop wrapper

### Tertiary (LOW confidence — open bugs, unverified fixes)
- [anthropics/claude-code issue #16538](https://github.com/anthropics/claude-code/issues/16538) — Plugin SessionStart hookSpecificOutput.additionalContext not surfaced (OPEN)
- [anthropics/claude-code issue #10373](https://github.com/anthropics/claude-code/issues/10373) — SessionStart not firing for new conversations (OPEN)
- [anthropics/claude-code issue #24529](https://github.com/anthropics/claude-code/issues/24529) — CLAUDE_PLUGIN_ROOT not set in hook environment (OPEN, closed #27145 as duplicate)
- [anthropics/claude-code issue #22700](https://github.com/anthropics/claude-code/issues/22700) — Windows hook execution uses 'bash' instead of full path

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — official docs confirm all tools used; bash/awk universally available
- Architecture patterns: HIGH for hooks.json format; MEDIUM for BASH_SOURCE[0] workaround (needed due to open bug); MEDIUM for run-hook.cmd decision (superpowers evolved past it)
- Pitfalls: MEDIUM — bugs #10373, #16538, #24529 are open and described precisely in the issues; behavior may change with future Claude Code releases
- Frontmatter extraction: HIGH — awk approach tested locally against actual SKILL.md, produces correct output and valid JSON

**Research date:** 2026-03-01
**Valid until:** 2026-04-01 (bugs are actively tracked; resolution could change workarounds needed)

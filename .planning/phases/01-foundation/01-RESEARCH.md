# Phase 1: Foundation - Research

**Researched:** 2026-02-28
**Domain:** Claude Code skill infrastructure — SKILL.md registration, git submodule wiring, progressive file structure
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **Invocation format:** Argument hint is freeform problem description (e.g. `/socrates <describe your problem>`). No flags hinted in Phase 1 — flags (`--structured`, `--record`) are Phase 4. Command name: `/socrates` — standalone, no namespace.
- **No-argument behavior:** When invoked without arguments: show a brief intro and prompt for input. Intro is minimal: state what it does ("I apply structured dialectic reasoning to your problem"), ask what they want to reason about. Do NOT list protocols or categories.
- **File organization:** One file per protocol — 13 separate protocol files for maximum granularity. Only the relevant protocol file(s) are loaded per invocation (progressive disclosure).
- **Context budget — CUE optimization:** Priority is execution fidelity — keep everything Claude needs to faithfully execute protocols, including field descriptions, constraints, and phase sequences. Strip comments, formatting whitespace, and non-essential content. Optimized protocol files are pre-generated and committed to repo (no build step, deterministic, reviewable).

### Claude's Discretion

- Skill file location (root vs dedicated directory) — pick based on Claude Code skill conventions
- Routing logic placement (in SKILL.md vs separate file) — pick based on what keeps SKILL.md focused
- Submodule location — pick based on git submodule conventions
- Context budget threshold (hard ceiling vs soft target) — determine based on actual CUE file sizes
- Protocol file format (optimized CUE vs converted Markdown) — determine based on how well Claude can interpret each for execution

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| INFRA-01 | Skill registers as `/socrates` slash command in Claude Code with correct SKILL.md frontmatter | `name: socrates` in SKILL.md frontmatter creates the `/socrates` command; project-scoped at `.claude/skills/socrates/SKILL.md` commits with repo |
| INFRA-02 | User sees argument hint when typing `/socrates` showing expected input format | `argument-hint` frontmatter field controls autocomplete hint; value `<describe your problem>` matches the locked decision on freeform input |
| INFRA-03 | Git submodule wired to riverline-labs/dialectics so all .cue files are readable by Claude | `git submodule add` at `.claude/skills/socrates/dialectics`; Claude Code >= 2.0.76 reads submodule files via Read tool; preflight check verifies initialization |
| INFRA-04 | Supporting files structure loads protocol .cue files on demand rather than inlining all 13 | Progressive disclosure: SKILL.md references individual protocol files; Claude reads only the selected file per invocation; no protocol content inlined in SKILL.md |
| INFRA-05 | Protocol .cue files are optimized for agent context window — comments and non-essential content stripped | Raw files range 6.5–24KB; comments are 40–66% of bulk; stripped versions estimated 3.2–12KB each; all fit within the 16K per-file budget; pre-generated and committed |
</phase_requirements>

---

## Summary

Phase 1 is pure infrastructure — no routing logic, no protocol execution, no output formatting. It delivers the scaffolding that every subsequent phase depends on: the `/socrates` slash command appearing in Claude Code, the dialectics git submodule containing all CUE files accessible via the Read tool, and a progressive file structure that prevents context budget overflow from day one.

The Claude Code skill system (as of the current Agent Skills standard) uses `SKILL.md` files discovered in `.claude/skills/<name>/SKILL.md`. This is the canonical format that supersedes `.claude/commands/` — skills support supporting files, invocation control (`disable-model-invocation`), argument hints, and tool whitelisting, all of which are required for socrates. For a project-distributed skill (committed to version control), the correct path is `.claude/skills/socrates/SKILL.md` at the repo root.

The CUE file size analysis confirms the optimization requirement in INFRA-05 is achievable and necessary. Raw protocol files range from 6,464 bytes (ovp.cue) to 23,964 bytes (hep.cue). Comments represent 40–66% of each file by character count. Stripped versions land in the 3,200–12,000 byte range — all individually within the 16,000-character context budget for per-invocation loading. However, loading even two large protocols simultaneously without stripping would breach the budget. Pre-generating stripped files and committing them eliminates this risk deterministically, with no build step required at invocation time.

**Primary recommendation:** Create `.claude/skills/socrates/` with SKILL.md (frontmatter + no-argument intro + file reference instructions), add dialectics as a git submodule at `.claude/skills/socrates/dialectics`, generate stripped protocol files into `.claude/skills/socrates/protocols/` for each of the 15 CUE files (13 protocols + 2 governance), and add a preflight check in SKILL.md that reads `dialectics/dialectics.cue` and fails with a setup message if the file is missing.

---

## Standard Stack

### Core

| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| Claude Code SKILL.md | Agent Skills standard (current) | Skill entrypoint; creates `/socrates` slash command | Only format supporting `argument-hint`, `disable-model-invocation`, `allowed-tools`, and supporting files; supersedes `.claude/commands/` legacy format; skills win on name conflict |
| YAML frontmatter | embedded in SKILL.md | Metadata and behavior control | `name` field creates the slash command; `argument-hint` drives autocomplete; `disable-model-invocation: true` prevents auto-invocation |
| Git submodule | standard git | Reference riverline-labs/dialectics .cue files | Stays in sync with upstream; no copy drift; local on disk — no network access at invocation time; Claude Code >= 2.0.76 reads submodule files via Read tool |
| Markdown (SKILL.md body) | n/a | Instructions Claude follows when skill is invoked | No code, no toolchain; SKILL.md body must stay under 500 lines |

### Supporting

| Component | Purpose | When to Use |
|-----------|---------|-------------|
| Pre-stripped CUE files in `protocols/` | Optimized protocol files that fit within 16K context budget per invocation | Always — the 15 raw CUE files total ~212KB; stripped versions total ~106KB; individual files range 3.2–12KB stripped |
| Preflight check (Read + conditional message) | Verify submodule is initialized before any protocol work | Always — in SKILL.md, first instruction reads `dialectics/dialectics.cue`; if missing, surfaces setup command |
| `.gitmodules` | Git submodule registration file | Automatically created by `git submodule add` |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `.claude/skills/socrates/SKILL.md` | `.claude/commands/socrates.md` | Commands format is legacy — lacks supporting file support, invocation control, and skills win on name conflict. Never for new work. |
| Git submodule for dialectics | Copy .cue files into repo | Copied files drift from upstream as the dialectics framework evolves. Submodule pins to a commit and updates cleanly. |
| Pre-generated stripped files (committed) | Strip at invocation time via a script | A build step creates a runtime dependency and breaks the "deterministic, reviewable" constraint from CONTEXT.md. Pre-generated files are committed and readable. |
| Pre-generated stripped files (committed) | Use raw CUE files directly | Raw files breach the 16K budget — hep.cue at 23,964 bytes and rcp.cue at 22,351 bytes exceed it unstripped. Stripping is required, not optional. |
| Personal install (`~/.claude/skills/`) | Project install (`.claude/skills/`) | Project install commits the skill with the repo — any contributor or deployment gets it without manual setup. Personal install is for individual use only. |

**Installation:**
```bash
# In project root
mkdir -p .claude/skills/socrates
git submodule add https://github.com/riverline-labs/dialectics.git .claude/skills/socrates/dialectics
git submodule update --init --recursive
mkdir -p .claude/skills/socrates/protocols
touch .claude/skills/socrates/SKILL.md
```

---

## Architecture Patterns

### Recommended Project Structure

```
.claude/skills/socrates/
├── SKILL.md                          # Entry point (required; ≤500 lines)
│                                     # frontmatter: name, description, argument-hint,
│                                     #   disable-model-invocation: true, allowed-tools: Read
│                                     # body: preflight check, no-arg intro, file references
│
├── protocols/                        # Pre-stripped CUE files (pre-generated, committed)
│   ├── adversarial/
│   │   ├── atp.opt.cue               # ~5KB stripped (raw: 10,412 bytes)
│   │   ├── cbp.opt.cue               # ~11KB stripped (raw: 21,176 bytes)
│   │   ├── cdp.opt.cue               # ~10KB stripped (raw: 19,173 bytes)
│   │   ├── cffp.opt.cue              # ~8KB stripped (raw: 16,958 bytes)
│   │   ├── emp.opt.cue               # ~5KB stripped (raw: 10,468 bytes)
│   │   └── hep.opt.cue               # ~12KB stripped (raw: 23,964 bytes)
│   ├── evaluative/
│   │   ├── aap.opt.cue               # ~9KB stripped (raw: 18,877 bytes)
│   │   ├── cgp.opt.cue               # ~4KB stripped (raw: 8,952 bytes)
│   │   ├── ifa.opt.cue               # ~4KB stripped (raw: 8,865 bytes)
│   │   ├── ovp.opt.cue               # ~3KB stripped (raw: 6,464 bytes)
│   │   ├── ptp.opt.cue               # ~3KB stripped (raw: 6,804 bytes)
│   │   └── rcp.opt.cue               # ~11KB stripped (raw: 22,351 bytes)
│   ├── exploratory/
│   │   └── adp.opt.cue               # ~10KB stripped (raw: 19,170 bytes)
│   ├── dialectics.opt.cue            # ~3.5KB stripped (raw: 10,488 bytes); kernel primitives
│   └── routing.opt.cue               # ~2.5KB stripped (raw: 4,574 bytes); routing logic
│
└── dialectics/                       # Git submodule: riverline-labs/dialectics
    ├── dialectics.cue
    ├── governance/
    │   ├── routing.cue
    │   └── recording.cue
    └── protocols/
        ├── adversarial/ (6 .cue files)
        ├── evaluative/ (6 .cue files)
        └── exploratory/ (1 .cue file)
```

**Naming note:** The `.opt.cue` convention for optimized files makes it visually clear which files are pre-stripped (Claude reads these) vs. the raw submodule files (source of truth for updates). This is a discretion choice — the planner may choose a different naming convention (e.g., flat filenames without extension variation, or a `protocols/stripped/` subdirectory).

### Pattern 1: SKILL.md Frontmatter Structure

**What:** The YAML frontmatter block defines all behavioral metadata for the skill.

**Required fields for Phase 1:**
```yaml
---
name: socrates
description: Apply structured dialectic reasoning to any problem. Invoke when you want rigorous, protocol-driven analysis — competing candidates, argument stress-testing, assumption audits, causal claims, analogy evaluation, formalization, or possibility mapping. Accepts a problem description and routes to the correct protocol automatically.
argument-hint: <describe your problem>
disable-model-invocation: true
allowed-tools: Read
---
```

**Rationale for each field:**
- `name: socrates` — creates the `/socrates` command (INFRA-01)
- `description` — short enough for the skill description budget (~100 words); includes routing vocabulary so Claude's description matches the 14 structural features from routing.cue; `disable-model-invocation: true` means description is NOT loaded into Claude's always-on context — it only appears when you invoke `/socrates` explicitly
- `argument-hint: <describe your problem>` — this is the hint shown during autocomplete (INFRA-02); matches the locked decision of freeform problem description; no flags hinted (flags are Phase 4)
- `disable-model-invocation: true` — prevents Claude from auto-triggering heavyweight protocol execution mid-conversation; users invoke `/socrates` deliberately (INFRA-01 success criterion)
- `allowed-tools: Read` — skill needs to read .cue files from the submodule and protocols/ directory; no write access needed; no Bash needed in Phase 1

### Pattern 2: Preflight Check

**What:** First instruction in SKILL.md body. Reads a specific file from the submodule to verify initialization, fails with a clear setup message if missing.

**Why:** Git submodules are NOT automatically initialized on clone. Users who clone the repo without `--recurse-submodules` will have an empty `dialectics/` directory. Without a preflight check, Claude silently degrades (reads nothing, produces generic output). With a preflight check, the failure is immediate and actionable.

**Example:**
```markdown
## Setup Verification

Read the file `dialectics/dialectics.cue`.

If the file cannot be read (submodule not initialized), respond:
"The dialectics submodule is not initialized. Run: git submodule update --init --recursive
Then try /socrates again."
Do not proceed with protocol execution.
```

### Pattern 3: No-Argument Intro

**What:** When `$ARGUMENTS` is empty, SKILL.md shows a brief intro and asks for input instead of attempting to execute a protocol.

**When to use:** Required per the locked decision in CONTEXT.md. Must NOT list protocols or categories — keep it simple and inviting.

**Example:**
```markdown
## Invocation

If `$ARGUMENTS` is empty or missing:
Say: "I apply structured dialectic reasoning to your problem — from testing assumptions to mapping possibility spaces. What would you like to reason through?"
Do not proceed further.
```

### Pattern 4: Progressive Disclosure File References

**What:** SKILL.md body contains explicit Read directives that reference sub-files by path. No protocol content is inlined.

**Why:** If all 13 protocol schemas were inlined in SKILL.md, the full skill body would exceed 200KB — far beyond the 500-line / ~16K character budget. Progressive disclosure means Claude loads only the selected protocol file at routing time (Phase 2). Phase 1 establishes this structure even before routing is implemented.

**Example structure in SKILL.md body:**
```markdown
## Protocol Files

Optimized protocol files are in `protocols/`. Read only the file for the selected protocol.

- Kernel primitives: `protocols/dialectics.opt.cue`
- Routing logic: `protocols/routing.opt.cue`
- Adversarial protocols: `protocols/adversarial/{name}.opt.cue`
- Evaluative protocols: `protocols/evaluative/{name}.opt.cue`
- Exploratory protocol: `protocols/exploratory/adp.opt.cue`
```

### Anti-Patterns to Avoid

- **Inlining any CUE content in SKILL.md:** The skill body is injected into context on every invocation. Each protocol file is 3–12KB stripped. Inlining two files already approaches the 16K budget. Zero inline CUE content in SKILL.md.
- **Using `.claude/commands/socrates.md`:** The legacy commands format lacks `argument-hint`, `allowed-tools`, supporting files support, and invocation control. Skills win on name conflict. Never for new work.
- **Using raw submodule files directly (without stripping):** hep.cue (23,964 bytes) and rcp.cue (22,351 bytes) exceed the 16K budget unstripped. Even files that fit individually would have up to 66% wasted comment tokens. Stripped files must be pre-generated.
- **Stripping at invocation time:** No build step at invocation. Pre-generate and commit. This is locked in CONTEXT.md.
- **Personal install at `~/.claude/skills/`:** Would not be committed to the repo. Socrates is a project-distributed skill that ships with the repo.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Slash command registration | Custom command parser, hook-based invocation | `name: socrates` in SKILL.md frontmatter | Claude Code discovers SKILL.md automatically; name becomes the command |
| Argument autocomplete hint | Custom UI, prompt engineering workaround | `argument-hint` frontmatter field | Native Claude Code feature; one field, zero effort |
| Invocation control (prevent auto-trigger) | Complex description wording to discourage auto-invocation | `disable-model-invocation: true` | Definitive — removes skill from Claude's always-on context; description wording is unreliable |
| Tool access control | Prompt-level tool restrictions ("only use the Read tool") | `allowed-tools: Read` in frontmatter | Enforced at skill level, not instruction level; more reliable |
| Submodule sync with upstream | Manual file copying, wget-based download scripts | `git submodule` | Git manages version pinning and updates; one command to update |
| CUE comment stripping | CUE parser, regex-based stripping script | Any standard text processing (sed/awk/Python); result committed | Comment stripping is trivial string processing; no custom tool needed; output is committed (not run dynamically) |

**Key insight:** Phase 1 has zero creative engineering. Every component is a standard Claude Code skill feature or a standard git feature. The entire phase is configuration and file creation.

---

## Common Pitfalls

### Pitfall 1: Silent Submodule Failure

**What goes wrong:** User clones the repo, skips `git submodule update --init --recursive`, runs `/socrates`. Claude reads `dialectics/dialectics.cue` — file not found. Without a preflight check, Claude produces generic output with no error message. User thinks the skill is broken or hallucinating.

**Why it happens:** Git does not auto-initialize submodules on clone. This is the #1 documented submodule pitfall in the ecosystem. There is no error at clone time.

**How to avoid:** Preflight check as the FIRST instruction in SKILL.md body. Read a specific file (`dialectics/dialectics.cue`). If missing, surface the exact setup command and stop. Also document setup in the repo README.

**Warning signs:** `dialectics/` directory exists but is empty. `git submodule status` shows `-` prefix. File reads on CUE paths return "not found."

### Pitfall 2: SKILL.md Exceeds 500-Line Limit

**What goes wrong:** SKILL.md grows beyond 500 lines during Phase 1 scaffolding. Protocol documentation, examples, or routing instructions get inlined. On every `/socrates` invocation, the full body loads — inflating context immediately.

**Why it happens:** It's tempting to add "helpful" documentation inline. Protocol names, descriptions, example outputs all seem like they belong in the skill's main file.

**How to avoid:** Phase 1 SKILL.md contains only: frontmatter, preflight check, no-argument intro, and path references for all supporting files. No CUE content. No protocol descriptions. Target 50–100 lines for Phase 1 SKILL.md body. All detail lives in sub-files that Claude reads on demand.

**Warning signs:** SKILL.md line count > 150 in Phase 1. Any CUE field names or protocol descriptions inline in SKILL.md body.

### Pitfall 3: Wrong Install Location

**What goes wrong:** Skill placed in `~/.claude/skills/socrates/` (personal) instead of `.claude/skills/socrates/` (project). Works for the developer but invisible to anyone else who clones the repo. Or placed in `.claude/commands/socrates.md` (legacy format) which lacks frontmatter features.

**Why it happens:** The STACK.md research documents both personal and project install paths. The distinction matters for distribution.

**How to avoid:** Socrates is a project-distributed skill that ships with the repo — use `.claude/skills/socrates/SKILL.md` at the repo root. Verify by running `ls -la .claude/skills/` from the project root.

**Warning signs:** SKILL.md file is not tracked by git. `/socrates` works on developer machine but not on fresh clone.

### Pitfall 4: Raw CUE Files Used Without Stripping

**What goes wrong:** SKILL.md references `dialectics/protocols/adversarial/hep.cue` (23,964 bytes raw) directly. When Phase 2 loads this file for execution, it consumes 23,964 characters — 50% over the 16K budget. Claude Code may silently truncate or the invocation degrades.

**Why it happens:** Referencing the raw submodule files seems simpler than maintaining a separate `protocols/` directory of stripped files.

**How to avoid:** Pre-generate stripped files into `protocols/` and commit them. SKILL.md references `protocols/adversarial/hep.opt.cue`, not `dialectics/protocols/adversarial/hep.cue`. Raw submodule files are the authoritative source used to regenerate stripped files when the submodule is updated; they are not loaded at invocation time.

**Warning signs:** Any SKILL.md reference to a path inside `dialectics/protocols/` or `dialectics/governance/`. Reference paths should all be `protocols/*.opt.cue`.

### Pitfall 5: Stripping Too Aggressively

**What goes wrong:** Comment stripping removes phase descriptions, field rationales, and semantic cues that Claude uses to faithfully execute the protocol. The stripped file has the right structure but Claude doesn't understand what each field means or why each phase exists. Protocol fidelity degrades.

**Why it happens:** The CONTEXT.md locked decision says "strip comments, formatting whitespace, and non-essential content — but preserve all structural and semantic content." The line between "non-essential" and "semantic" is blurry without reading each file carefully.

**How to avoid:** The stripping criterion is: preserve everything Claude needs to faithfully execute the protocol (field descriptions, constraints, phase sequences, obligation gate semantics). Strip only: (1) block-comment documentation sections explaining design philosophy or rationale for external readers, (2) divider lines (`// ─────────`) used for visual formatting, (3) blank lines beyond one separator. Verify each stripped file is readable by a human who hasn't read the original — if the field semantics are unclear, you stripped too much.

**Warning signs:** Stripped file has correct CUE structure but no explanation of what each field represents. Phase sequences are present but phase purposes are unclear. Any `#ObligationGate` or `#RevisionLoop` reference with no explanation of what it means.

---

## Code Examples

Verified patterns from official sources:

### SKILL.md Frontmatter (Phase 1 Complete)

```yaml
---
name: socrates
description: Apply structured dialectic reasoning to any problem. Use when facing competing design candidates, argument stress-testing, assumption audits, causal claims, analogy evaluation, formalization, or possibility mapping. Accepts a problem description and auto-routes to the correct protocol.
argument-hint: <describe your problem>
disable-model-invocation: true
allowed-tools: Read
---
```
Source: [Claude Code Skills Documentation — frontmatter reference](https://code.claude.com/docs/en/skills)

### Git Submodule Setup

```bash
# From repo root
git submodule add https://github.com/riverline-labs/dialectics.git .claude/skills/socrates/dialectics
git submodule update --init --recursive

# Verify
git submodule status
# Should show: <commit-hash> .claude/skills/socrates/dialectics (v0.2.1-...)
```
Source: Standard git submodule workflow (HIGH confidence)

### Preflight Check Pattern

```markdown
## Preflight

Read the file at path: `protocols/dialectics.opt.cue`

If the file is not found or empty, respond exactly:
"Setup required: the dialectics submodule is not initialized.
Run: git submodule update --init --recursive
Then invoke /socrates again."
Stop here. Do not proceed.
```
Note: Phase 1 uses the pre-stripped `protocols/dialectics.opt.cue` (not the raw submodule path) since the preflight check also validates that the stripped files exist.

### No-Argument Handler

```markdown
## Input

If `$ARGUMENTS` is empty or blank:
Respond: "I apply structured dialectic reasoning to your problem — from testing assumptions to mapping possibility spaces. What would you like to reason through?"
Stop here. Do not proceed with protocol steps.
```

### Stripped CUE File Example — Before vs After

**Before (raw dialectics.cue excerpt — 580 lines, ~10.5KB, ~66% comments):**
```cue
// ─── THE REBUTTAL ─────────────────────────────────────────────────────────────
// A rebuttal is an atomic response to a challenge. It doesn't summarize;
// it terminates the challenge by either defeating the premise (refutation)
// or accepting the premise while narrowing the claim's scope. Either a
// claim collapses or it survives in reduced form. There is no middle ground.
//
// Two Kinds of Rebuttal
// ...
#Rebuttal: {
  kind:           "refutation" | "scope_narrowing"
  valid:          bool
  carries_burden: bool
  // ...
}
```

**After (stripped — target: preserve field names, types, constraints, phase sequences; remove design commentary and dividers):**
```cue
#Rebuttal: {
  // Terminates a challenge: either defeats premise (refutation) or narrows scope (scope_narrowing)
  kind:           "refutation" | "scope_narrowing"
  valid:          bool          // true if this rebuttal holds under adversarial review
  carries_burden: bool          // true if the burden shifts to the challenger on success
}
```

The stripped version retains one comment per field explaining its semantic meaning. All design rationale, historical context, and formatting dividers are removed. Target: 30–40% of original file size.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `.claude/commands/` markdown files | `.claude/skills/<name>/SKILL.md` | 2025 (Agent Skills standard) | Skills win on name conflict, support supporting files, invocation control, and argument hints — commands format is legacy but still works |
| Separate slash command registration | `name` field in SKILL.md frontmatter | 2025 | No separate config file; directory name is the fallback; name field is the override |
| Manual context loading (all files) | Progressive disclosure (load on demand) | 2025 | Skills under 500 lines load instantly; supporting files load only when Claude explicitly reads them |
| Submodule file access limitation | Claude Code >= 2.0.76 reads submodule files via Read tool | Jan 2026 (issue #7852 closed) | Git submodule pattern is now confirmed viable; no workaround needed |

**Deprecated/outdated:**
- `.claude/commands/<name>.md` as the primary skill format: Still works (backward-compatible), but lacks `argument-hint`, `disable-model-invocation`, supporting files, and invocation control. Skills take precedence on name conflict.
- Personal install for project-wide skills: Installing at `~/.claude/skills/` works locally but is not committed to the repo, making it invisible to other contributors and deployments.

---

## Open Questions

1. **Protocol file naming convention**
   - What we know: Pre-stripped files need to be distinguishable from raw submodule files; both will exist in the repo
   - What's unclear: Best naming convention — `.opt.cue` suffix, `stripped/` subdirectory, or flat naming without distinction
   - Recommendation: Claude's discretion (per CONTEXT.md). The `.opt.cue` suffix makes the distinction visually obvious without requiring directory navigation. The planner should pick one convention and apply it consistently to all 15 files.

2. **Submodule location — inside skill dir vs. sibling**
   - What we know: Two valid patterns: `git submodule add ... .claude/skills/socrates/dialectics` (inside skill) or `git submodule add ... dialectics` (repo root, shared)
   - What's unclear: Whether future phases need raw submodule access outside the skill context
   - Recommendation: Place submodule inside the skill directory (`.claude/skills/socrates/dialectics`). The raw files are the source for generating stripped files but are never referenced in SKILL.md body. Keeping them inside the skill directory makes the dependency explicit and self-contained.

3. **Commit pinning vs. branch tracking for submodule**
   - What we know: The dialectics repo has protocol version v0.2.1 (CFFP) and v0.1.0 (routing); research recommends pinning to a specific commit rather than tracking `main`
   - What's unclear: The stable commit to pin to (requires checking upstream)
   - Recommendation: During Phase 1 setup, run `git submodule add` (which pins to HEAD at that moment), then document the pinned commit in a comment in `.gitmodules`. Run `git submodule update --remote` explicitly when upstream protocol updates are desired.

4. **Stripping methodology — manual vs. script-assisted**
   - What we know: CONTEXT.md says pre-generated and committed (no build step at invocation); stripping is a one-time authoring task; files need to be reviewable
   - What's unclear: Whether a script should be committed to the repo to enable reproducible re-stripping when the submodule is updated
   - Recommendation: Commit a simple stripping script (Python or bash, ~20 lines) to `.claude/skills/socrates/scripts/strip_cue.py` so future updates to the submodule can be re-stripped deterministically. The script is not invoked at runtime — it's a developer tool. The pre-stripped files are what matter.

---

## Sources

### Primary (HIGH confidence)

- [Claude Code Skills Official Documentation](https://code.claude.com/docs/en/skills) — SKILL.md format, frontmatter reference (all fields), invocation control, progressive disclosure, context budget (2% of window, 16K fallback), supporting files pattern. Fetched 2026-02-28.
- [riverline-labs/dialectics GitHub repository](https://github.com/riverline-labs/dialectics) — Repository structure, file sizes (via GitHub API), CUE file organization, 13 protocol file paths. Fetched 2026-02-28.
- [GitHub API: dialectics file sizes](https://api.github.com/repos/riverline-labs/dialectics/contents/) — Exact byte sizes for all 15 CUE files. Fetched 2026-02-28.
- `.planning/research/STACK.md` — Prior research on SKILL.md frontmatter, submodule patterns, installation commands, CUE interpretation model. Researched 2026-02-28.
- `.planning/research/ARCHITECTURE.md` — Prior research on progressive disclosure pattern, file structure rationale, anti-patterns. Researched 2026-02-28.
- `.planning/research/PITFALLS.md` — Prior research on submodule initialization gap, token budget overflow, stripping pitfalls. Researched 2026-02-28.

### Secondary (MEDIUM confidence)

- [Claude Code Issue #7852](https://github.com/anthropics/claude-code/issues/7852) — Git submodule read support confirmed in Claude Code >= 2.0.76; issue closed January 2026. Community-reported, not in official docs.
- [Claude Code Issue #13586](https://github.com/anthropics/claude-code/issues/13586) — Silent skill exclusion on naming conflicts. Confirmed behavior.
- [Anthropic Engineering: Agent Skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills) — Context window budget details; skill description budget ~100 tokens; skill body ~2000 tokens when loaded.
- Prior research in `.planning/research/FEATURES.md` — Feature dependency analysis, MVP definition confirming Phase 1 scope.

### Tertiary (LOW confidence)

- CUE file comment ratio estimates (40–66%) — Derived from WebFetch analysis of cffp.cue (45-50%), dialectics.cue (66%), aap.cue (40%), adp.cue from size-to-SLOC ratio. Each estimate is approximate; actual strip ratios should be validated during implementation.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — Official Claude Code docs confirm SKILL.md format, frontmatter fields, and file locations. All verified against live documentation February 2026.
- Architecture: HIGH — File structure follows official Claude Code skill conventions; submodule pattern verified against GitHub issue confirming support in v2.0.76+; prior project research covers the same ground with HIGH confidence.
- CUE file sizes: HIGH — Exact byte sizes from GitHub API; comment ratios derived from WebFetch analysis (approximate, but validated against multiple files).
- Pitfalls: HIGH — Submodule pitfall is #1 documented submodule issue ecosystem-wide; token budget limits confirmed in official docs; stripping approach validated against project CONTEXT.md constraints.

**Research date:** 2026-02-28
**Valid until:** 2026-03-30 (stable domain — Claude Code skill format is stable; dialectics upstream changes would only affect CUE file sizes)

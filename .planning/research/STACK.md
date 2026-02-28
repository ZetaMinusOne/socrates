# Stack Research

**Domain:** Claude Code custom skill — CUE-schema-driven dialectic reasoning
**Researched:** 2026-02-28
**Confidence:** HIGH (core skill format verified against official Claude Code docs; CUE syntax verified against live repo files; git submodule behavior verified against tracked issue)

---

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Claude Code Skill (SKILL.md) | current (2025 Agent Skills standard) | Skill entrypoint and slash command definition | The canonical format per official docs. Supersedes `.claude/commands/` — skills win on name conflict, support supporting files, invocation control, and subagent execution. Only format with `argument-hint`, `allowed-tools`, `context: fork` etc. |
| YAML frontmatter | n/a | Skill metadata and behavior control | Embedded in SKILL.md between `---` markers. Defines name (becomes `/socrates`), description (drives auto-routing), `disable-model-invocation`, `argument-hint`, `allowed-tools`. No external config file needed. |
| Markdown | n/a | Skill body — protocol execution instructions | Claude reads and follows the markdown. This is where the routing logic, output format rules, and protocol execution instructions live. No code, no toolchain. |
| Git submodule | n/a | Reference `riverline-labs/dialectics` .cue files | Keeps CUE files in sync with upstream without copying. Claude Code can read submodule files (confirmed in v2.0.76+). Avoids copy drift and manual update overhead. |
| CUE (.cue files) | v0.2.1 (protocol version, not toolchain) | Structured reasoning specs Claude interprets | Claude reads .cue files as structured specifications — no CUE binary or toolchain required. The schema syntax (typed fields, disjunctions, phase structures) provides the protocol contract Claude follows. |

### Supporting Files

| File | Purpose | When to Use |
|------|---------|-------------|
| `protocols/README.md` (in skill dir) | Protocol index linking to each .cue file | Always — helps Claude navigate 13 protocols without loading all at once |
| `routing-guide.md` (in skill dir) | Human-readable summary of routing.cue logic | Always — reduces context pressure vs. requiring Claude to parse full routing.cue on every invocation |
| `output-examples/` (directory) | Example narrative outputs for 2-3 protocols | Optional — useful to establish output tone and format during initial development |
| `SKILL.md` | Skill entrypoint (required) | Always |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| `git submodule add` | Add dialectics repo as submodule | `git submodule add https://github.com/riverline-labs/dialectics.git dialectics` — place at repo root or inside skill dir |
| `git submodule update --init --recursive` | Initialize submodule on clone | Add to project README setup instructions |
| Claude Code `/socrates` test invocation | Smoke-test skill execution | Test with simple problems first, then complex multi-feature problems to validate routing |

---

## Skill File Structure

This is the canonical layout for a Claude Code skill with supporting files and a git submodule:

```
~/.claude/skills/socrates/          (personal install — available in all projects)
  OR
.claude/skills/socrates/            (project install — committed to version control)
├── SKILL.md                        # Required entrypoint
├── routing-guide.md                # Routing logic in readable form
├── protocols/
│   └── README.md                   # Protocol index
└── dialectics/                     # Git submodule: riverline-labs/dialectics
    ├── dialectics.cue              # Kernel primitives
    ├── governance/
    │   ├── routing.cue             # Protocol routing logic
    │   └── recording.cue          # Run → record conversion
    └── protocols/
        ├── adversarial/
        │   ├── atp.cue
        │   ├── cbp.cue
        │   ├── cdp.cue
        │   ├── cffp.cue
        │   ├── emp.cue
        │   └── hep.cue
        ├── evaluative/
        │   ├── aap.cue
        │   ├── cffp.cue (sic)
        │   ├── cgp.cue
        │   ├── ifa.cue
        │   ├── ovp.cue
        │   ├── ptp.cue
        │   └── rcp.cue
        └── exploratory/
            └── adp.cue
```

---

## SKILL.md Frontmatter — Recommended Configuration

```yaml
---
name: socrates
description: >
  Apply structured dialectic reasoning protocols to any problem.
  Use when facing: competing design candidates, argument stress-testing,
  assumption audits, causal claims, analogy evaluation, formalization,
  or possibility mapping. Accepts a problem description; routes to the
  correct protocol automatically.
argument-hint: "[problem description] [--structured]"
disable-model-invocation: true
allowed-tools: Read, Glob
---
```

**Rationale for each field:**

- `name: socrates` — creates the `/socrates` command
- `description` — trigger-rich; includes the use-cases that match routing.cue's 14 structural features. Claude uses this for auto-invocation matching.
- `argument-hint` — tells users what to pass; `--structured` flag hint for optional raw output mode
- `disable-model-invocation: true` — reasoning protocol invocation is a deliberate act, not something Claude should trigger automatically mid-conversation
- `allowed-tools: Read, Glob` — skill needs to read .cue files from the submodule; no write access needed

---

## CUE File Interpretation Model

CUE files in dialectics use a consistent syntax pattern. Claude must understand:

| CUE Construct | Meaning for Claude | Example |
|---------------|-------------------|---------|
| `#TypeName: { ... }` | Defines a schema structure | `#Candidate: { id: string, ... }` |
| `field: string` | Required string field | `name: string` |
| `field?: string` | Optional field | `limitation_description?: string` |
| `field: "a" \| "b" \| "c"` | Enumerated allowed values | `kind: "refutation" \| "scope_narrowing"` |
| `field: [...#Type]` | List of typed items | `claims: [...#ProofSketch]` |
| `field: [_, ...]` | Non-empty list constraint | `invariants: [_, ...]` — at least one required |
| `if condition { field: value }` | Conditional field presence | `if succeeded { merged_candidate: #Candidate }` |

Claude does not need to run `cue eval` or validate against schemas. It reads the .cue files as structured natural-language specs defining what fields are required and in what sequence.

---

## Installation

```bash
# Create skill directory (personal install — available across all projects)
mkdir -p ~/.claude/skills/socrates

# Add dialectics as git submodule inside skill directory
cd ~/.claude/skills/socrates
git init  # if not already a git repo
git submodule add https://github.com/riverline-labs/dialectics.git dialectics
git submodule update --init --recursive

# Create SKILL.md
touch SKILL.md
touch routing-guide.md
mkdir -p protocols
touch protocols/README.md
```

**Alternative: Project-scoped install (committed to repo)**

```bash
# Inside the socrates project repo
mkdir -p .claude/skills/socrates
git submodule add https://github.com/riverline-labs/dialectics.git .claude/skills/socrates/dialectics
```

---

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| `.claude/skills/socrates/SKILL.md` | `.claude/commands/socrates.md` | Never for new work — commands are legacy; skills win on name conflict and support supporting files |
| Git submodule for dialectics | Copy .cue files into repo | Only if submodule management proves too cumbersome for the user base, or if upstream repo stability is a concern |
| Git submodule for dialectics | Reference .cue files via raw GitHub URLs in instructions | Never — URLs require network access during skill execution; submodule is local and reliable |
| `disable-model-invocation: true` | Default (allow auto-invocation) | Only if you want Claude to trigger dialectic reasoning automatically mid-conversation — not recommended for protocols with structured multi-phase execution |
| Personal install (`~/.claude/skills/`) | Project install (`.claude/skills/`) | Use project install if you want to commit the skill to version control and share with a team via the repo |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| `.claude/commands/socrates.md` (legacy format) | Commands format lacks supporting files, invocation control, and is superseded by skills — skill wins on name conflict | `.claude/skills/socrates/SKILL.md` |
| CUE toolchain (`cue eval`, `cue vet`) as runtime dependency | The PROJECT.md explicitly rules out CUE runtime — no `cue eval` needed. Adding a binary dependency breaks the "no runtime deps" constraint and complicates distribution. | Claude reads .cue files as structured specs; no validation binary needed |
| Embedding .cue file content directly in SKILL.md | Context window waste — loads all 13 protocols upfront even when only 1 is needed. Official docs cap skill descriptions at 2% of context window (fallback: 16K chars). | Reference supporting files; Claude reads only the needed .cue file when routing selects a protocol |
| `context: fork` subagent execution | Skill involves reading external CUE files — forked subagent loses conversation history context needed to understand the original problem. Adds latency without benefit for this use case. | Inline execution; let Claude apply the protocol in the main conversation context |
| `user-invocable: false` | Socrates is meant to be invoked by users via `/socrates` — hiding it from the menu defeats the purpose | Keep default `user-invocable: true` |
| Copying all 13 protocol specs into SKILL.md body | Exceeds recommended 500-line limit; pollutes context on every invocation; all protocols loaded even for simple single-protocol runs | Progressive disclosure: SKILL.md loads routing guide; individual .cue files loaded only when the matched protocol is needed |

---

## Stack Patterns by Variant

**If distributing as personal skill (recommended for solo use):**
- Install to `~/.claude/skills/socrates/`
- Git submodule inside that directory
- No project repo changes needed

**If distributing as project skill (team use or open-source):**
- Install to `.claude/skills/socrates/` committed to the project repo
- Git submodule at `.claude/skills/socrates/dialectics`
- Add `.gitmodules` and submodule initialization to README setup steps
- Users run `git submodule update --init --recursive` after clone

**If the `--structured` flag is desired for raw output:**
- Handle via `$ARGUMENTS` parsing in the skill body (check if last arg equals `--structured`)
- No frontmatter changes needed — argument parsing is instruction-level logic

---

## Version Compatibility

| Component | Version | Notes |
|-----------|---------|-------|
| Claude Code | >= 2.0.76 | Submodule read support confirmed at this version |
| dialectics CUE protocols | v0.2.1 (CFFP), v0.1.0 (routing) | Check upstream for updates; submodule pins to a commit |
| Agent Skills standard | current (agentskills.io) | SKILL.md format is stable and cross-tool compatible |
| Claude context window | ~200K tokens | Skill descriptions budget = 2% of context window, fallback 16K chars |

---

## Sources

- [Claude Code Skills Official Docs](https://code.claude.com/docs/en/skills) — SKILL.md format, frontmatter reference, invocation control, supporting files, context budget (HIGH confidence)
- [riverline-labs/dialectics GitHub](https://github.com/riverline-labs/dialectics) — Protocol structure, .cue file organization (HIGH confidence, live repo)
- [dialectics/protocols/adversarial/cffp.cue](https://raw.githubusercontent.com/riverline-labs/dialectics/main/protocols/adversarial/cffp.cue) — CUE syntax patterns: `#Type`, disjunctions, conditional fields (HIGH confidence, raw file)
- [dialectics/governance/routing.cue](https://raw.githubusercontent.com/riverline-labs/dialectics/main/governance/routing.cue) — RoutingInput/RoutingResult schema, 14 structural features, protocol mapping (HIGH confidence, raw file)
- [Claude Code Issue #7852](https://github.com/anthropics/claude-code/issues/7852) — Git submodule read/write support confirmed in v2.0.76+; issue closed Jan 2026 (MEDIUM confidence — community-reported, not official doc)
- [Anthropic Engineering: Agent Skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills) — Context window budget details: description ~100 tokens, full skill ~2000 tokens (MEDIUM confidence)
- [CUE Language Specification](https://cuelang.org/docs/reference/spec/) — CUE syntax foundations (HIGH confidence, official)

---

*Stack research for: Socrates — Claude Code dialectic reasoning skill*
*Researched: 2026-02-28*

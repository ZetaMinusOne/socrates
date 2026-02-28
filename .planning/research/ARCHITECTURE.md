# Architecture Research

**Domain:** Claude Code skill — LLM-driven reasoning protocol executor
**Researched:** 2026-02-28
**Confidence:** HIGH (official Claude Code docs verified; dialectics repo inspected directly)

## Standard Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                      User Interaction Layer                          │
│  User types /socrates [problem description]                          │
├─────────────────────────────────────────────────────────────────────┤
│                      Skill Entry Point                               │
│  .claude/skills/socrates/SKILL.md                                   │
│  (frontmatter: name, description, disable-model-invocation: true)   │
├───────────────────┬─────────────────────────────────────────────────┤
│  Routing Layer    │         Protocol Execution Layer                 │
│                   │                                                  │
│  governance/      │  protocols/adversarial/   protocols/evaluative/ │
│  routing.cue      │  cffp.cue  cdp.cue        aap.cue  ifa.cue     │
│                   │  cbp.cue   hep.cue        rcp.cue  cgp.cue     │
│  (Claude reads    │  atp.cue   emp.cue        ptp.cue  ovp.cue     │
│   this to select  │                                                  │
│   protocol)       │  protocols/exploratory/                          │
│                   │  adp.cue                                         │
│                   │                                                  │
│                   │  (Claude reads the selected .cue file and        │
│                   │   executes it as a reasoning protocol)           │
├───────────────────┴─────────────────────────────────────────────────┤
│                      Recording Layer                                 │
│  governance/recording.cue                                            │
│  (Claude applies this schema to produce a structured run record)    │
├─────────────────────────────────────────────────────────────────────┤
│                      Output Layer                                    │
│  Narrative mode (default): prose explanation of protocol + result   │
│  Structured mode (--structured flag): typed output per CUE schema   │
└─────────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| SKILL.md | Entry point; frontmatter config; top-level instruction to Claude | YAML + markdown; references all sub-files by relative path |
| routing.cue | Protocol selection logic; maps 14 problem features to 13 protocols | Read by Claude; no CUE runtime needed |
| dialectics.cue (kernel) | Shared primitives: Rebuttal, Challenge, Derivation, ObligationGate, RevisionLoop, Finding | Read by Claude as type reference when executing any protocol |
| Protocol .cue files (13) | Phase-by-phase execution schema for each protocol; defines what Claude must produce | Each read individually when that protocol is selected |
| recording.cue | Standardizes completed runs into queryable records with dispute kind, resolution, dependencies, tags | Applied by Claude after protocol execution |
| PROTOCOL_GUIDE.md (to create) | Human-readable quick reference mapping problem types to protocols | Supporting file loaded when Claude needs disambiguation help |
| examples/ directory | Sample runs showing expected protocol execution patterns | Loaded on-demand when Claude needs to calibrate output format |

## Recommended Project Structure

```
.claude/skills/socrates/
├── SKILL.md                  # Entry point: frontmatter + top-level instructions
├── ROUTING.md                # Prose routing guide (optional companion to routing.cue)
├── protocols/
│   └── (git submodule: riverline-labs/dialectics)
│       ├── dialectics.cue            # Kernel primitives
│       ├── governance/
│       │   ├── routing.cue           # Protocol selection logic
│       │   └── recording.cue         # Run record schema
│       ├── protocols/
│       │   ├── adversarial/
│       │   │   ├── cffp.cue
│       │   │   ├── cdp.cue
│       │   │   ├── cbp.cue
│       │   │   ├── hep.cue
│       │   │   ├── atp.cue
│       │   │   └── emp.cue
│       │   ├── evaluative/
│       │   │   ├── aap.cue
│       │   │   ├── ifa.cue
│       │   │   ├── rcp.cue
│       │   │   ├── cgp.cue
│       │   │   ├── ptp.cue
│       │   │   └── ovp.cue
│       │   └── exploratory/
│       │       └── adp.cue
│       └── examples/
│           └── runs/               # Protocol execution examples
```

### Structure Rationale

- **.claude/skills/socrates/**: Claude Code discovers project-scoped skills in `.claude/skills/<name>/`. Using project scope (not personal `~/.claude/skills/`) means the skill ships with the repo and any contributor or deployment picks it up automatically.
- **SKILL.md at root**: Required by the Claude Code skill contract. Must stay under 500 lines. Contains only: frontmatter, orientation instructions, and references to sub-files. Detail lives in sub-files.
- **protocols/ as submodule**: The dialectics repo is owned by riverline-labs. Pulling it in as a git submodule keeps the skill in sync with upstream schema changes without copy drift. Claude navigates submodule files via the Read tool — this works today with explicit path references even though LS/Grep/Glob have submodule visibility gaps (tracked issue #7852 on anthropics/claude-code).
- **No scripts/ directory needed**: This skill's execution is pure LLM reasoning — no Python/Bash scripts required. All behavior is prompt-driven.

## Architectural Patterns

### Pattern 1: Progressive Disclosure via Referenced Sub-Files

**What:** SKILL.md contains only high-level instructions and explicit `Read [file]` directives. Detailed schemas live in sub-files that Claude loads on-demand.

**When to use:** Always. The Claude Code skill meta-tool injects full SKILL.md content on invocation. If SKILL.md contained all 13 protocol schemas, context bloat would be severe (13 protocols × ~200 lines each = 2600+ lines injected every time). Progressive disclosure means Claude only loads the selected protocol's .cue file.

**Trade-offs:** Context is lean; each protocol invocation costs ~300-500 tokens for routing + ~300 tokens for selected protocol, rather than 2600+ for all protocols upfront.

**Example:**
```markdown
## Execution Steps

1. Read `protocols/governance/routing.cue` to select the protocol for the user's problem.
2. Read `protocols/dialectics.cue` for kernel primitives.
3. Read the selected protocol's .cue file (e.g., `protocols/protocols/adversarial/cffp.cue`).
4. Execute the protocol's phases following the schema exactly.
5. Read `protocols/governance/recording.cue` to structure the run record.
6. Produce output in the requested mode (narrative or structured).
```

### Pattern 2: CUE-as-Spec Interpretation

**What:** Claude reads CUE schema files as structured specifications and follows them as behavioral instructions, without any CUE toolchain at runtime. No `cue eval`, no CUE binary, no toolchain dependency.

**When to use:** Whenever the protocol logic is encoded in CUE. Claude treats `#CFFPInstance`, `#Challenge`, `#ObligationGate` etc. as type contracts it must satisfy when reasoning — not as code to execute.

**Trade-offs:** Zero runtime dependencies (correct for a Claude Code skill). The risk is schema drift if upstream CUE changes its idioms in ways Claude misinterprets; mitigate with example runs that demonstrate expected behavior.

**Example:**
```markdown
The CFFP protocol defines `#ObligationGate` with a `satisfied: bool` field.
When executing Phase 5, Claude must evaluate each obligation and explicitly
mark `satisfied: true` or `satisfied: false` with a `blocker` if false —
not skip the check or infer satisfaction implicitly.
```

### Pattern 3: Routing Before Loading

**What:** Execute the routing step (read routing.cue, classify the problem, select a protocol) before loading any protocol file. This is a two-pass architecture: classify first, then load.

**When to use:** Always. Routing is cheap (~300 tokens for routing.cue). Protocol files are moderately expensive. Never pre-load all 13 protocols.

**Trade-offs:** Two reads (routing.cue, then selected protocol file) add minor latency but save significant context. Routing failures produce an explicit unroutable status that surfaces to the user as a clear message rather than a confused protocol execution.

**Example:**
```markdown
After reading routing.cue, Claude identifies the primary structural feature
(e.g., "term inconsistency") and maps it to the primary protocol (e.g., CBP).
Only then does Claude read protocols/adversarial/cbp.cue to execute it.
```

### Pattern 4: Dual Output Modes via Flag

**What:** SKILL.md detects whether `$ARGUMENTS` contains `--structured` and switches output format accordingly: narrative prose by default, typed structured output (matching the protocol's CUE output schema) when the flag is present.

**When to use:** Skill design requiring two audiences — humans reading reasoning prose, tools consuming structured output.

**Trade-offs:** Adds a branching instruction to SKILL.md; keep this explicit and early in the instructions so Claude doesn't miss it.

**Example:**
```yaml
---
name: socrates
description: Applies structured dialectic reasoning protocols to any problem. Auto-routes to the appropriate protocol from the dialectics framework (CFFP, CDP, CBP, HEP, ATP, EMP, AAP, IFA, RCP, CGP, PTP, OVP, ADP). Use when you need rigorous, protocol-driven analysis.
disable-model-invocation: true
allowed-tools: Read
---

## Output Mode

If `$ARGUMENTS` ends with `--structured`, produce raw structured output
matching the selected protocol's CUE output schema. Otherwise produce
narrative output explaining the reasoning process and conclusion.
```

## Data Flow

### Request Flow

```
User: /socrates "Should we use PostgreSQL or DynamoDB for this service?" [--structured]
    |
    v
SKILL.md loads into conversation context
    |
    v
Claude reads routing.cue
  → identifies feature: "competing candidates" (candidate selection problem)
  → selects primary protocol: CDP (Candidate Decomposition Protocol)
    |
    v
Claude reads dialectics.cue (kernel primitives)
  → loads #Rebuttal, #Challenge, #Derivation, #ObligationGate types
    |
    v
Claude reads protocols/evaluative/cdp.cue
  → loads CDP's phase structure and schema
    |
    v
Claude executes CDP phases:
  Phase 1 → Phase 2 → Phase 3 → [Phase 3b if zero survivors] → Phase 4 → ...
    |
    v
Claude reads recording.cue
  → structures the run into a #Record with dispute kind, resolution, tags
    |
    v
Output:
  narrative mode → prose explanation of reasoning + conclusion
  structured mode → typed record matching CUE output schema
```

### State Management

```
No persistent state. Each /socrates invocation is stateless.

Within one invocation:
  Routing result → passed in-context to protocol loading step
  Protocol execution → produces in-context run record
  Run record → serialized to output (narrative or structured)

Cross-invocation recording (future):
  recording.cue defines #Record schema for queryable logs
  Implementation would require a separate storage layer (not in v1)
```

### Key Data Flows

1. **Problem to protocol:** User's problem text → routing.cue feature classification → protocol name → protocol .cue file load
2. **Protocol execution:** dialectics.cue primitives + selected protocol phases → Claude's reasoning → populated schema fields → run record
3. **Run record to output:** Completed run → recording.cue schema → narrative or structured output

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| 1 user, ~10 invocations/day | Current architecture is sufficient. No state, no storage, no backend needed. |
| 10 users, ~100 invocations/day | Same. Stateless skills scale horizontally by nature — each Claude Code session is independent. |
| Cross-session run history | Would require a storage layer (not in scope v1). recording.cue defines the record schema; a future companion tool could persist records to a file or database. |

### Scaling Priorities

1. **First bottleneck: Context budget.** If SKILL.md grows beyond 500 lines, split content into referenced sub-files. The SKILL.md stays lean; protocol schemas stay in dialectics submodule.
2. **Second bottleneck: Submodule staleness.** As the dialectics framework evolves, the submodule pin needs updating. Use `git submodule update --remote` to pull changes, then test protocol execution against examples/.

## Anti-Patterns

### Anti-Pattern 1: Embedding All Protocol Schemas in SKILL.md

**What people do:** Copy all 13 .cue protocol files into SKILL.md for "convenience."
**Why it's wrong:** The Claude Code skill meta-tool injects the full SKILL.md body into context on every invocation. 13 protocols × ~200 lines ≈ 2600+ lines injected every single time, most of it unused. This saturates context and degrades reasoning on the actual problem.
**Do this instead:** Keep SKILL.md under 200 lines. Reference sub-files explicitly. Claude loads only the selected protocol per invocation.

### Anti-Pattern 2: Copying Dialectics .cue Files Instead of Submodule

**What people do:** Copy `protocols/*.cue` into the skill directory to avoid submodule complexity.
**Why it's wrong:** Copied files drift from upstream. The dialectics framework's protocol schemas will evolve. Running on stale schemas means executing protocols that may have breaking changes in their phase structure or type contracts.
**Do this instead:** Use `git submodule add https://github.com/riverline-labs/dialectics.git .claude/skills/socrates/protocols`. One `git submodule update --remote` stays current.

### Anti-Pattern 3: Implicit Routing (Let Claude Guess)

**What people do:** Skip routing.cue and let Claude pick a protocol based on vibes.
**Why it's wrong:** routing.cue encodes 14 structural features, explicit feature-to-protocol mappings, confidence levels, disambiguation rules for conflicting features, and sequential execution conditions. Skipping this means Claude free-associates instead of applying the formal classification logic. Protocol fidelity breaks down on ambiguous inputs.
**Do this instead:** Make reading routing.cue the mandatory first step. Treat the routing output (primary protocol, confidence, sequencing needs) as a structured intermediate result, not a soft suggestion.

### Anti-Pattern 4: Skipping the Kernel (dialectics.cue)

**What people do:** Jump directly to a protocol .cue file without reading dialectics.cue first.
**Why it's wrong:** Protocol files reference kernel types: `#Rebuttal`, `#Challenge`, `#Derivation`, `#ObligationGate`, `#RevisionLoop`, `#Finding`. Without loading the kernel, Claude has no definition for these types and must infer their structure from context, which produces inconsistent execution across protocols.
**Do this instead:** Always read dialectics.cue before reading any protocol file. It is cheap (~100 lines) and provides the shared type vocabulary that makes all protocol schemas unambiguous.

### Anti-Pattern 5: allow-model-invocation: true for /socrates

**What people do:** Leave out `disable-model-invocation: true`, so Claude auto-invokes the socrates skill whenever it judges the conversation is "philosophical" or "analytical."
**Why it's wrong:** Dialectic protocol execution is heavyweight — it takes multiple reasoning passes and produces structured output. Claude should not invoke a full CFFP or CDP cycle because the user casually asked "which approach do you think is better?" Auto-invocation should be the user's explicit choice.
**Do this instead:** Set `disable-model-invocation: true`. `/socrates` is a power tool users invoke deliberately, not a background advisory skill Claude loads opportunistically.

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| riverline-labs/dialectics | Git submodule pinned to main | Read via Read tool; no CUE runtime needed |
| Claude Code skill system | SKILL.md in `.claude/skills/socrates/` | Project-scoped skill; ships with repo |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| SKILL.md -> routing.cue | Claude reads file via Read tool; in-context reasoning | SKILL.md must include explicit instruction to read routing.cue first |
| SKILL.md -> dialectics.cue | Claude reads file via Read tool | Load after routing, before protocol file |
| SKILL.md -> protocol .cue file | Claude reads file via Read tool; path determined by routing result | Path construction: `protocols/protocols/{category}/{name}.cue` |
| Protocol execution -> recording.cue | Claude reads file via Read tool after protocol phases complete | Optional in v1; required for --structured mode with full record schema |
| User arguments -> output mode | `$ARGUMENTS` string substitution in SKILL.md | Parse `--structured` flag early; branch instruction is in SKILL.md |

## Build Order Implications

The architecture implies a clear dependency order for implementation:

1. **Submodule setup first** — the dialectics repo must be added as a submodule before any skill logic can reference protocol files
2. **SKILL.md skeleton second** — frontmatter, output mode detection, and the Read tool call sequence can be written independently of protocol content
3. **Routing integration third** — verify Claude correctly reads routing.cue and selects protocols before writing any protocol execution logic
4. **Protocol execution fourth** — start with one representative protocol (CDP or CFFP) to validate the read-kernel → read-protocol → execute-phases pattern works end-to-end
5. **Remaining protocols fifth** — once the single-protocol path is validated, the other 12 protocols follow the same pattern; no new infrastructure required
6. **Recording integration last** — recording.cue is needed for structured output mode; implement after narrative output is confirmed working

## Sources

- Claude Code official skills documentation: https://code.claude.com/docs/en/skills (HIGH confidence — official)
- Claude Agent Skills deep dive (internal architecture): https://leehanchung.github.io/blogs/2025/10/26/claude-skills-deep-dive/ (MEDIUM confidence — third-party verified against official docs)
- Claude Code skills structure and invocation: https://mikhail.io/2025/10/claude-code-skills/ (MEDIUM confidence — third-party)
- riverline-labs/dialectics repository: https://github.com/riverline-labs/dialectics (HIGH confidence — primary source)
- Claude Code git submodule limitation tracking: https://github.com/anthropics/claude-code/issues/7852 (MEDIUM confidence — GitHub issue)
- Anthropic official skills examples: https://github.com/anthropics/skills (HIGH confidence — official)

---
*Architecture research for: Socrates — Claude Code dialectic reasoning skill*
*Researched: 2026-02-28*

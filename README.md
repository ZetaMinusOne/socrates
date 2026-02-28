# Socrates

A [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skill that brings structured dialectic reasoning into Claude via `/socrates`. Describe a problem, get rigorous protocol-driven analysis — no need to know which reasoning method to apply.

Built on [riverline-labs/dialectics](https://github.com/riverline-labs/dialectics), a formal engine for structured disagreement resolution expressed in [CUE](https://cuelang.org/).

## Install

Clone with the submodule:

```bash
git clone --recurse-submodules https://github.com/your-org/socrates.git
```

Or if already cloned:

```bash
git submodule update --init --recursive
```

The skill lives at `.claude/skills/socrates/` — Claude Code picks it up automatically when you open a project containing this repo.

## Usage

```
/socrates <describe your problem>
```

Socrates analyzes structural features of your problem, selects the appropriate protocol, and executes it — producing a narrative explanation of the reasoning process and conclusion.

### Examples

```
/socrates Why did our API latency increase 40% after the last deployment?
```
Routes to OVP (validate the observation) then HEP (eliminate causal hypotheses).

```
/socrates We have three competing database schemas and need to pick one
```
Routes to CFFP (formalize constraints, pressure-test each candidate, adopt the survivor).

```
/socrates Is our assumption that users always have network connectivity sound?
```
Routes to AAP (extract assumptions, stress-test each one, produce a fragility map).

```
/socrates I don't know what design options exist for our notification system
```
Routes to ADP (multi-persona exploration of the design space before formalization).

### Output Modes

**Narrative (default)** — prose explanation with section headers per protocol phase:

```
/socrates <problem>
```

**Structured** — typed JSON matching the protocol's CUE output schema:

```
/socrates --structured <problem>
```

**Record** — JSON formatted as a `#Record` per `governance/recording.cue` (queryable audit trail):

```
/socrates --record <problem>
```

**Both** — combined structured + record output:

```
/socrates --structured --record <problem>
```

## Protocols

Socrates includes 13 reasoning protocols across three families. Routing is automatic — describe your problem and the skill selects the right one.

### Adversarial — generate, pressure, survive, adopt

These protocols pit candidates against structured adversarial challenges. Survivors earn adoption; eliminated candidates are discarded with explicit reasons.

| Protocol | Name | Core Question |
|----------|------|---------------|
| **CFFP** | Constraint-First Formalization | What is the correct formal definition of this construct? |
| **CDP** | Construct Decomposition | Is this one thing or secretly two? |
| **CBP** | Concept Boundary | What does this term actually mean? |
| **HEP** | Hypothesis Elimination | Why did this happen? |
| **ATP** | Analogy Transfer | Is this structural similarity real and importable? |
| **EMP** | Emergence Mapping | What unexpected behavior appears at the seams? |

### Evaluative — subject, criteria, verdict

These protocols assess a subject against defined criteria and deliver a verdict.

| Protocol | Name | Core Question |
|----------|------|---------------|
| **AAP** | Assumption Audit | What is this argument standing on, and where is it fragile? |
| **IFA** | Implementation Fidelity Audit | Does the implementation match the spec? |
| **RCP** | Reconciliation | Do these independent outputs agree with each other? |
| **CGP** | Canonical Governance | Is this canonical form still fit for purpose? |
| **PTP** | Prioritization Triage | Given finite resources, which path first? |
| **OVP** | Observation Validation | Is this observation real or an artifact? |

### Exploratory — personas, rounds, map

| Protocol | Name | Core Question |
|----------|------|---------------|
| **ADP** | Adversarial Design | What is the space of possibilities? |

ADP deploys six personas (formalist, implementor, adversary, operator, consumer, referee) through structured rounds to map a design space before formalization begins.

## How It Works

### Architecture

```
┌─────────────────────────────────────────────────────┐
│  SKILL LAYER  (SKILL.md)                            │
│  routing · flag handling · execution · rendering     │
├─────────────────────────────────────────────────────┤
│  GOVERNANCE LAYER                                    │
│  routing.cue · recording.cue                         │
├─────────────────────────────────────────────────────┤
│  PROTOCOL LAYER                                      │
│  13 domain-specific protocol schemas (.opt.cue)      │
├─────────────────────────────────────────────────────┤
│  DIALECTIC KERNEL  (dialectics.cue)                  │
│  rebuttal · challenge · derivation · obligation      │
│  revision · finding · archetype contracts            │
└─────────────────────────────────────────────────────┘
```

### Routing

When you invoke `/socrates`, the skill:

1. **Extracts structural features** from your problem description (e.g., `competing_candidates`, `causal_ambiguity`, `term_inconsistency`)
2. **Maps features to protocols** using the routing table in `governance/routing.cue`
3. **Applies disambiguation** when multiple features co-occur (e.g., OVP vs HEP boundary: "Is the observation itself questionable, or is the cause unclear?")
4. **Sequences protocols** when a composite problem requires multiple passes (e.g., validate the observation first with OVP, then investigate the cause with HEP)

### Execution

Protocol execution follows the schema phases defined in each `.cue` file. Key mechanisms:

- **Obligation gates** block progress until proof obligations are satisfied — the anti-hallucination mechanism
- **Revision loops** trigger when all candidates are eliminated, diagnosing why and determining where to restart (zero survivors is not failure — it means the problem is harder than assumed)
- **Scope narrowings** accumulate when candidates retreat from pressure, becoming acknowledged limitations in the final output
- **Eager gate enforcement** checks preconditions at every phase transition, not just the formal obligation gate

### Progressive Disclosure

Protocol files are loaded on demand. The skill reads only the kernel and routing logic upfront, then loads the specific protocol file after routing selects it. This keeps context usage minimal.

## File Structure

```
.claude/skills/socrates/
├── SKILL.md                           # Skill definition (frontmatter + instructions)
├── protocols/                         # Optimized protocol files (.opt.cue)
│   ├── dialectics.opt.cue             # Kernel primitives
│   ├── routing.opt.cue                # Routing logic
│   ├── adversarial/
│   │   ├── cffp.opt.cue
│   │   ├── cdp.opt.cue
│   │   ├── cbp.opt.cue
│   │   ├── hep.opt.cue
│   │   ├── atp.opt.cue
│   │   └── emp.opt.cue
│   ├── evaluative/
│   │   ├── aap.opt.cue
│   │   ├── ifa.opt.cue
│   │   ├── rcp.opt.cue
│   │   ├── cgp.opt.cue
│   │   ├── ptp.opt.cue
│   │   └── ovp.opt.cue
│   └── exploratory/
│       └── adp.opt.cue
├── scripts/
│   └── strip_cue.py                   # Generates .opt.cue from full sources
└── dialectics/                        # Git submodule → riverline-labs/dialectics
    ├── dialectics.cue                 # Full kernel with documentation
    ├── governance/
    │   ├── routing.cue
    │   └── recording.cue
    ├── protocols/
    │   ├── adversarial/
    │   ├── evaluative/
    │   └── exploratory/
    └── examples/runs/                 # Example protocol executions
```

The `.opt.cue` files are comment-stripped versions of the full protocol schemas, optimized for Claude's context window. The full documented sources live in the `dialectics/` submodule.

## Constraints

- **Claude Code only** — this is a skill (slash command), not an MCP server or standalone tool
- **No CUE runtime** — Claude interprets the `.cue` schemas directly; no `cue` binary required
- **No custom protocols** — users consume the 13 existing protocols; authoring new ones is out of scope for v1
- **Submodule-linked** — protocol schemas stay in sync with upstream `riverline-labs/dialectics`

## License

See the [dialectics](https://github.com/riverline-labs/dialectics) repository for protocol schema licensing.

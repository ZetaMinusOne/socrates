---
name: socrates
description: Apply structured dialectic reasoning to any problem. Use when facing competing design candidates, argument stress-testing, assumption audits, causal claims, analogy evaluation, formalization, or possibility mapping. Accepts a problem description and auto-routes to the correct protocol.
argument-hint: "<describe your problem>"
disable-model-invocation: true
allowed-tools: Read
---

## Preflight

Read the file at path: `protocols/dialectics.opt.cue`

If the file is not found or empty, respond exactly:
"Setup required: the dialectics submodule is not initialized or protocol files have not been generated.
Run: git submodule update --init --recursive
Then check that protocols/dialectics.opt.cue exists.
If missing, regenerate the optimized protocol files from the dialectics submodule."
Stop here. Do not proceed.

## Input

If `$ARGUMENTS` is empty or blank:
Respond: "I apply structured dialectic reasoning to your problem — from testing assumptions to mapping possibility spaces. What would you like to reason through?"
Stop here. Do not proceed with protocol steps.

## Protocol Files

Optimized (pre-stripped) protocol files are in `protocols/`. Read ONLY the file for the selected protocol. Never load all protocols at once.

**Kernel and governance:**
- Kernel primitives: `protocols/dialectics.opt.cue`
- Routing logic: `protocols/routing.opt.cue`

**Adversarial protocols (6):**
- `protocols/adversarial/atp.opt.cue` — Analogy Transfer Protocol
- `protocols/adversarial/cbp.opt.cue` — Concept Boundary Protocol
- `protocols/adversarial/cdp.opt.cue` — Construct Decomposition Protocol
- `protocols/adversarial/cffp.opt.cue` — Constraint-First Formalization Protocol
- `protocols/adversarial/emp.opt.cue` — Emergence Mapping Protocol
- `protocols/adversarial/hep.opt.cue` — Hypothesis Elimination Protocol

**Evaluative protocols (6):**
- `protocols/evaluative/aap.opt.cue` — Assumption Audit Protocol
- `protocols/evaluative/cgp.opt.cue` — Canonical Governance Protocol
- `protocols/evaluative/ifa.opt.cue` — Implementation Fidelity Audit
- `protocols/evaluative/ovp.opt.cue` — Observation Validation Protocol
- `protocols/evaluative/ptp.opt.cue` — Prioritization Triage Protocol
- `protocols/evaluative/rcp.opt.cue` — Reconciliation Protocol

**Exploratory protocols (1):**
- `protocols/exploratory/adp.opt.cue` — Adversarial Design Protocol

## Routing

Read the file at path: `protocols/routing.opt.cue`

**Protocol full names:**
- AAP: Assumption Audit Protocol
- ADP: Adversarial Design Protocol
- ATP: Analogy Transfer Protocol
- CBP: Concept Boundary Protocol
- CDP: Construct Decomposition Protocol
- CFFP: Constraint-First Formalization Protocol
- CGP: Canonical Governance Protocol
- EMP: Emergence Mapping Protocol
- HEP: Hypothesis Elimination Protocol
- IFA: Implementation Fidelity Audit
- OVP: Observation Validation Protocol
- PTP: Prioritization Triage Protocol
- RCP: Reconciliation Protocol

**Step 1: Extract structural features**
Analyze the user's problem in `$ARGUMENTS`. Identify which `#StructuralFeature` values are present. The inline comments on each enum value encode the feature-to-protocol mapping (e.g., `"term_inconsistency" | // term used differently across contexts → CBP`). Use these inline comments as the authoritative routing table.

**Step 2: Apply boundary discrimination**
When multiple features are detected, apply these questions INTERNALLY (never shown to user) to narrow to one primary protocol:

- **OVP vs HEP** (`observation_validity` vs `causal_ambiguity`): "Is the observation itself questionable, or is the phenomenon clearly real but the cause unclear?" — questioned observation → OVP; real phenomenon with unclear cause → HEP.
- **CBP vs CDP** (`term_inconsistency` vs `construct_incoherence`): "Is the same word used differently across contexts/people, or is one concept internally splitting into two different things?" — cross-context disagreement → CBP; internal split → CDP.
- **CFFP vs PTP** (`competing_candidates` vs `resource_constrained_choice`): "Are the options in genuine tension (adopting one means the other fails), or are all options valid and the constraint is capacity/resources?" — genuine tension → CFFP; capacity constraint → PTP.
- **CFFP vs CGP** (`competing_candidates` vs `revision_pressure`): "Is there an existing canonical form being proposed for change, or are these competing new proposals with no established baseline?" — existing baseline → CGP; no baseline → CFFP.
- **AAP vs RCP** (`argument_fragility` vs `cross_run_conflict`): "Is there one argument being stress-tested, or two independent reasoning sessions that reached different conclusions?" — one argument → AAP; two sessions conflicting → RCP.

**Step 3: Check for composite sequencing**
If `observation_validity` AND `causal_ambiguity` co-occur, set `sequenced: true` and build the OVP → HEP sequence. For any other co-occurring features where the selected protocol has `prerequisites` in its `#FeatureProtocolMapping`, check if the prerequisite protocol is also implied and sequence if so. Default: single protocol unless prerequisites are explicitly indicated.

**Step 4: Determine outcome**
- `"routed"` — one clear protocol selected (including after disambiguation)
- `"ambiguous"` — multiple features detected, boundary discrimination does not resolve them
- `"unroutable"` — no structural features detected in the problem description

**Routing outcome: routed (single protocol)**
Display the routing block, then proceed immediately to execution. No user confirmation gate.

```
---
Protocol: {ACRONYM} ({Full Name})
Detected: {plain language description} ({schema_identifier})
Rationale: {One sentence explaining why this protocol fits the problem}
---
```

Show confidence level ONLY when medium or low. Show warnings from the schema's `warnings` field ONLY when they would meaningfully change the user's interpretation. Do NOT show: disambiguation rules applied, features considered but not matched, or alternative protocols not chosen.

**Routing outcome: routed (composite sequence)**
Display the full sequence upfront, then proceed. No user confirmation gate.

```
---
Multi-protocol sequence:

1. {ACRONYM} ({Full Name}) — {purpose}
   Feeds into: {what this step's output provides to the next step}

2. {ACRONYM} ({Full Name}) — {purpose}
   Feeds into: conclusion

Detected: {plain language} ({schema_ids})
---

Starting with {first protocol}...
```

Early termination: if step N produces an outcome that invalidates step N+1, explain the invalidation and stop. Do not continue unnecessary protocols.

**Routing outcome: ambiguous**
Ask for clarification using plain language description of the fork. Never use protocol names.

```
Your problem could go in two directions:
- {Plain language description of direction A}
- {Plain language description of direction B}

Which describes your situation more accurately?
```

After the user clarifies, re-run routing with the additional context. If still ambiguous after one clarification attempt, use judgment on whether to ask again or pick the closer fit.

**Routing outcome: unroutable**
Explain without jargon, show what kinds of problems the skill handles, suggest rephrasing.

```
I couldn't identify a clear problem structure from your description.

Socrates handles problems like:
- "Why did X happen?" (causal investigation)
- "Which of these designs should I use?" (competing candidates)
- "Is this argument sound?" (assumption stress-testing)
- "I don't know what options exist" (design space exploration)

Could you describe what you're trying to figure out or decide?
```

Never force a bad fit — an unroutable problem gets the unroutable handler, not a randomly chosen protocol.

## Execution

Protocol execution will be implemented in a future update. After routing completes with outcome "routed", inform the user:
"Protocol {ACRONYM} ({Full Name}) has been selected. Execution is not yet available — it will be added in a future update."

---
name: socrates
description: Apply structured dialectic reasoning to any problem. Use when facing competing design candidates, argument stress-testing, assumption audits, causal claims, analogy evaluation, formalization, or possibility mapping. Accepts a problem description and auto-routes to the correct protocol.
argument-hint: "<describe your problem>"
disable-model-invocation: true
allowed-tools: Read
---

## Preflight

Read the file at path: `$CLAUDE_PLUGIN_ROOT/protocols/dialectics.opt.cue`

If the file is not found or empty, respond exactly:
"Setup required: protocol files are missing or unreadable. This usually means the plugin was not installed correctly.
Try reinstalling the plugin, or check that the protocols/ directory exists within the plugin root."
Stop here. Do not proceed.

## Input

If `$ARGUMENTS` is empty or blank:
Respond: "I apply structured dialectic reasoning to your problem — from testing assumptions to mapping possibility spaces. What would you like to reason through?"
Stop here. Do not proceed with protocol steps.

## Flag Handling

Before routing, scan `$ARGUMENTS` for recognized flags: `--structured` and `--record`. Both may appear together.

**Flag detection:** Identify which flags are present. Store the result — it determines output rendering after execution.

**Flag stripping:** Remove any detected flags from `$ARGUMENTS` before passing the remainder to routing. Routing must receive only the problem description text.

**Empty-after-strip guard:** If `$ARGUMENTS` contains only flags and no problem text remains after stripping:
Respond: "Please describe a problem for me to analyze."
Stop here. Do not proceed with routing or execution.

**Conditional recording.cue read:** When `--record` is detected (with or without `--structured`), read `$CLAUDE_PLUGIN_ROOT/governance/recording.opt.cue` to load the `#Record` type definition. Do NOT read recording.cue when `--record` is absent — follow the progressive disclosure pattern.

## Protocol Files

Optimized (pre-stripped) protocol files are in `$CLAUDE_PLUGIN_ROOT/protocols/`. Read ONLY the file for the selected protocol. Never load all protocols at once.

**Kernel and governance:**
- Kernel primitives: `$CLAUDE_PLUGIN_ROOT/protocols/dialectics.opt.cue`
- Routing logic: `$CLAUDE_PLUGIN_ROOT/protocols/routing.opt.cue`

**Adversarial protocols (6):**
- `$CLAUDE_PLUGIN_ROOT/protocols/adversarial/atp.opt.cue` — Analogy Transfer Protocol
- `$CLAUDE_PLUGIN_ROOT/protocols/adversarial/cbp.opt.cue` — Concept Boundary Protocol
- `$CLAUDE_PLUGIN_ROOT/protocols/adversarial/cdp.opt.cue` — Construct Decomposition Protocol
- `$CLAUDE_PLUGIN_ROOT/protocols/adversarial/cffp.opt.cue` — Constraint-First Formalization Protocol
- `$CLAUDE_PLUGIN_ROOT/protocols/adversarial/emp.opt.cue` — Emergence Mapping Protocol
- `$CLAUDE_PLUGIN_ROOT/protocols/adversarial/hep.opt.cue` — Hypothesis Elimination Protocol

**Evaluative protocols (6):**
- `$CLAUDE_PLUGIN_ROOT/protocols/evaluative/aap.opt.cue` — Assumption Audit Protocol
- `$CLAUDE_PLUGIN_ROOT/protocols/evaluative/cgp.opt.cue` — Canonical Governance Protocol
- `$CLAUDE_PLUGIN_ROOT/protocols/evaluative/ifa.opt.cue` — Implementation Fidelity Audit
- `$CLAUDE_PLUGIN_ROOT/protocols/evaluative/ovp.opt.cue` — Observation Validation Protocol
- `$CLAUDE_PLUGIN_ROOT/protocols/evaluative/ptp.opt.cue` — Prioritization Triage Protocol
- `$CLAUDE_PLUGIN_ROOT/protocols/evaluative/rcp.opt.cue` — Reconciliation Protocol

**Exploratory protocols (1):**
- `$CLAUDE_PLUGIN_ROOT/protocols/exploratory/adp.opt.cue` — Adversarial Design Protocol

## Routing

Read the file at path: `$CLAUDE_PLUGIN_ROOT/protocols/routing.opt.cue`

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

**Context bridge:** Begin every execution with one sentence connecting the routing decision to the protocol. Format: "Because your problem involves [problem characteristic], we'll apply [ACRONYM] — [what the protocol does in one clause]." Proceed immediately into protocol phases. No confirmation gate.

**Narrative structure:** Render each protocol phase as a section header (`### Phase N: [Phase name in plain language]`) followed by narrative prose. Use protocol-specific terminology (counterexample, obligation gate, scope narrowing) with inline explanation on first use; subsequent uses are bare. Output length scales with protocol complexity — adversarial protocols produce longer output than evaluative ones. Never list schema fields directly; output is narrative prose for humans.

**Eager gate enforcement:** Check phase preconditions at every transition, not only at the schema's formal Phase 5 gate. If a phase requires at least one item (the `[_, ...]` CUE constraint) and none can be established from the user's problem, stop before the next phase begins, show completed work, state the gate diagnosis, and give actionable suggestions for how the user could reframe.

### Adversarial protocols (CFFP, CDP, CBP, HEP, ATP, EMP)

Read the selected protocol's `.opt.cue` file (path already known from routing: `$CLAUDE_PLUGIN_ROOT/protocols/adversarial/{acronym}.opt.cue`). Execute the phases in order as defined by the schema. Do not hard-code phase sequences — let the loaded schema's type definitions drive what each phase requires.

**Phase 1 — Starting conditions:** Establish the phase-appropriate starting material from the protocol's Phase1 type:
- CFFP: invariants (each testable, structural, with an invariant class)
- CDP: incoherence evidence (invariant conflicts, behavioral partitions, or contextual composition failures)
- CBP: source term with documented usages across contexts
- HEP: phenomenon with hypotheses (each with predictions and prior plausibility)
- ATP: source construct and target domain with claimed correspondence
- EMP: composed forms with emergence claims

Eager gate: if the schema requires at least one item and none can be established from the user's problem, stop here with a gate diagnosis and suggestions.

**Phase 2 — Candidates:** Generate candidates (split candidates for CDP, correspondence candidates for ATP, hypotheses already in Phase 1 for HEP). Eager gate: if at least one candidate cannot be formulated from the problem, stop with a gate diagnosis before Phase 3.

**Phase 3 — Adversarial pressure:** For each candidate, generate challenges of the types the protocol's Phase3 schema defines — these vary per protocol (CFFP: `#Counterexample` and `#CompositionFailure`; CDP: boundary counterexamples, recomposition challenges, naturalness challenges; HEP: evidence rebuttals and accumulated pressure; ATP: disanalogy counterexamples, domain mismatches, scope challenges; etc.). For each challenge, evaluate whether a rebuttal holds (rebuttal kinds: `refutation`, `scope_narrowing`; note that `#CompositionFailure` in CFFP and CDP is not rebuttable). Compute derived: eliminated list (with elimination reason and source challenge id) and survivors list (with scope narrowings from valid scope-narrowing rebuttals).

**If derived.survivors is empty — Phase 3b (revision loop):**
1. Summarize the failed first pass briefly: "All N candidates were eliminated because [what pressure they couldn't survive]."
2. Identify the diagnosis label from the protocol's Phase3b diagnosis enum. State it explicitly: "Revision triggered: **[diagnosis]** — [what this means]."
3. Check for skip-retry diagnoses: if diagnosis is `construct_incoherent` (CFFP), `construct_not_decomposable` (CDP), or `transfer_not_viable` (ATP), skip retry entirely. Apply the protocol's skip-retry resolution — `reframe_and_close` for CFFP, `close_as_unified` for CDP, `close_as_rejected` for ATP — explain why retrying won't help, and give the user reframe suggestions. Stop.
4. Otherwise: apply the resolution enum value. Re-run Phases 2–3 in full with revised parameters, showing the complete second pass output.
5. If the second pass also produces empty survivors: report and stop. No infinite loops.
6. HEP tracks `revision_count: uint`; CDP has `max_revisions: uint` — respect these schema-declared limits.

**If derived.survivors has exactly 1:** Skip Phase 4. Proceed directly to Phase 5 with the single survivor.

**If derived.survivors > 1 — Phase 4 (selection):** Select one survivor with explicit rationale per the protocol's Phase4 type. HEP's Phase4 branches: single survivor triggers a `#ConfidenceAssessment`; multiple survivors trigger discriminating experiment design — if a feasible discriminating experiment exists, execute it and re-run Phase 3 with the new evidence before proceeding.

**Phase 5 — Obligation gate:** Evaluate all obligations defined in the protocol's Phase5 schema. The gate field varies by protocol:
- CFFP: `all_provable` (using `#StaticObligation` with `provable: bool`)
- CDP: `all_ready` (using `#PartReadiness` with `ready: bool`)
- CBP, HEP, ATP, EMP: `all_satisfied` (using protocol-specific obligation types)

If the gate fails: show all completed phases in full — the journey matters — then display a clear gate diagnosis stating which obligation failed and why, with actionable suggestions for how the user could reframe or modify input. Hard stop. No workarounds, no forcing past unmet gates.

**Phase 6 — Adoption (only when Phase 5 gate passes):** Produce the canonical form (CFFP), authorized parts (CDP), adopted explanation (HEP), validated transfer (ATP), or emergence map (EMP) — per the protocol's Phase6 type.

Special note for CDP: Phase6 produces `cffp_instructions` — conclude by telling the user that CDP has authorized CFFP runs for each part, and they can invoke `/socrates` with the part description to begin formalization of each part individually.

### Evaluative protocols (AAP, IFA, RCP, CGP, PTP, OVP)

Read the selected protocol's `.opt.cue` file (path: `$CLAUDE_PLUGIN_ROOT/protocols/evaluative/{acronym}.opt.cue`). Execute the phases in order as defined by the schema. Evaluative protocols follow a simpler arc than adversarial: establish the subject → define evaluation criteria → assess the subject against those criteria → deliver a verdict. There are no revision loops. A failed or indeterminate verdict is the terminal result — report it and stop.

Render each phase as a section header followed by narrative prose, using the same structure as adversarial protocols. Eager gate enforcement applies: if a phase requires at least one item and none can be established from the user's problem, stop before the next phase, show completed work, state the gate diagnosis, and give actionable suggestions.

**Protocol-specific handling:**

- **RCP special case:** After Phase 1 vocabulary alignment, check the `blocked` field. If `blocked: true`, CBP runs are required before conflict detection can proceed. Report the blocking terms — the homonyms that share a surface form but carry incompatible meanings across the two reasoning sessions — and stop. Instruct the user to invoke `/socrates` with each blocking term to resolve its concept boundaries via CBP, then re-run the reconciliation.

- **CGP special case:** Phase 2 activates `preservation_checks` for revision and combined cases, and `erosion_assessments` for deprecation and combined cases. Determine the governance case kind from the user's problem description (revision of an existing canonical form, deprecation of one, or both). Populate and render only the checks relevant to the case kind presented.

- **AAP note:** AAP has 6 phases — subject, extraction, plausibility, stress-test, fragility map, and recommendations. Give the stress-test and fragility map phases their own section headers; the fragility map (#FragilityMap) lists assumptions by tier: Tier 1 (`structural`), Tier 2 (`significant`), Tier 3 (`moderate`), Tier 4 (`minor`). The recommendations phase references the tier rankings.

- **PTP note:** PTP produces a ranked list with sensitivity analysis. If the top-ranked choice changes when criteria weights are perturbed, note the sensitivity in the conclusion — the ranking is weight-dependent, and the user should know which weights drive the outcome.

### Exploratory protocol (ADP)

Read the protocol file at `$CLAUDE_PLUGIN_ROOT/protocols/exploratory/adp.opt.cue`. ADP's model is distinct from both adversarial and evaluative families: rather than eliminating candidates or auditing a subject, it constructs a design space through structured multi-persona debate.

**Execution steps:**

1. **Subject and constraints:** Establish the subject type from the user's problem (new_construct, new_domain, breaking_change, or decision — per ADP's #ADPSubject). Declare which design constraints apply to this run (from ADP's #DesignConstraint types).

2. **Rounds:** Execute each round in sequence. Round types: probe, pressure, synthesis, handoff. Each round involves 5–6 personas (formalist, implementor, adversary, operator, consumer, referee). For each persona's contribution, narrate in **third person**: "The formalist raises a decidability concern, arguing that..." — do NOT write as first-person dialogue ("As the formalist, I believe...") and do NOT write as bare transcript ("Formalist: ..."). The narrator describes each persona's argument and its relationship to other arguments.

3. **Referee constraint checks:** After each round, the referee applies constraint checks to all proposals. If a proposal fails a constraint check (`#ConstraintCheckSet.passed: false`), it is blocked from proceeding. State which constraint it violated.

4. **Round progression:** Typical sequence is probe → pressure → synthesis. If synthesis does not converge, additional pressure/synthesis rounds may occur, or the referee declares scope_reduction.

5. **Terminal outcomes:** The referee declares one of three outcomes: `design_mapped` (produces #DesignMap), `exhaustion` (rounds exhausted without convergence), or `scope_reduction` (problem narrowed to a feasible subset). If `design_mapped`, render the DesignMap contents as the conclusion. Note any constructs marked as CFFP-ready — these are candidates for formalization the user can pursue via `/socrates`.

### Multi-protocol handoff

When a composite sequence executes, show an explicit handoff section between protocols before beginning the next protocol. Format:

> "[First protocol] established that [key output]. This feeds into [second protocol] as follows: [explicit input mapping]."

**OVP → HEP (confirmed prerequisite composite):** Extract OVP's Phase 4 `validated_observation` — its phenomenon, confidence level, and caveats. Use this as HEP's `#Phenomenon.observation` input. Incorporate OVP's caveats as `known_exclusions` in HEP's initial hypothesis set. Do NOT re-derive the phenomenon from the user's original problem description — use OVP's refined output as HEP's starting point.

**Early termination:** If the first protocol's outcome invalidates the need for the second, explain why the sequence ends, show the first protocol's complete output, and suggest alternatives. Example: if OVP returns `artifact` (the observation is not a real phenomenon), HEP would operate on a false premise — stop, explain the invalidation, and suggest what the user might investigate instead.

**No redundant routing block:** When the second protocol begins, do not re-display a routing block. The composite routing overview shown before the first protocol is sufficient.

**Other composite sequences:** Follow the same handoff pattern. Check the first protocol's terminal output type and map relevant fields to the second protocol's Phase 1 input type. The handoff section makes the state transfer explicit so the user can see what is being carried forward.

## Output Rendering

After protocol execution completes (or stops at a gate), render output based on the flags detected in Flag Handling:

- **No flags detected:** Use narrative prose (existing behavior). No further action needed.
- **`--structured` detected:** Render structured JSON output (see below).
- **`--record` detected:** Render `#Record` JSON output (see below).
- **Both detected:** Render combined: `{"structured": {protocol output envelope}, "record": {#Record}}`.

### Structured output (`--structured`)

Output ONLY a JSON object. No preamble, no trailing explanation. Use a single markdown code fence (` ```json ... ``` `) as the formatting wrapper only — no text outside it.

**Single protocol envelope:**
```json
{"protocol": "{ACRONYM}", "routed_via": "{structural_feature}", "output": {full protocol instance}}
```

The `output` field contains ALL executed phases as JSON objects — every phase that ran appears, including Phase 3b if triggered and Phase 4 if survivors > 1. Field names and nesting follow the protocol's instance type from its `.opt.cue` file: `#{ACRONYM}Instance` for all protocols except ADP, which uses `#ADPRecord`. Challenge/rebuttal narrative text is included as string `description` fields (complete audit trail). Revision loops include both passes: `[{"pass": 1, "outcome": "all_eliminated", ...}, {"pass": 2, "outcome": "survivors", ...}]`. Evaluative protocols use the same full-phase pattern for consistency.

**Gate failure in structured mode** (replaces normal output entirely — no envelope wrapper):
```json
{"outcome": "gate_failed", "gate": "{gate description}", "completed_phases": [...], "suggestions": [...]}
```

**Composite sequence format:**
```json
{"sequence": [{"protocol": "...", "routed_via": "...", "output": {...}}, ...]}
```
Early termination appends: `"early_termination": {"reason": "...", "stopped_at": "...", "suggested_next": "..."}`.

**Ambiguous routing with `--structured`:** Ask the clarifying question in plain text (not JSON) — structured output requires a selected protocol. After clarification and successful re-routing, apply the flag to the result.

**Unroutable with `--structured`:** Return `{"outcome": "unroutable", "message": "..."}`.

### Record output (`--record`)

Project the completed run into a `#Record` JSON object from the already-loaded `$CLAUDE_PLUGIN_ROOT/governance/recording.opt.cue`. Same output-only JSON rule applies.

**Field population:**
- `record_id`: `"rec-{protocol_lower}-{YYYYMMDD}-{4-char-hex}"` (e.g., `"rec-cffp-20260228-a7f3"`)
- `source_run.run_id`: `"{protocol_lower}-{YYYYMMDD}-{4-char-hex}"` (same suffix, no `rec-` prefix)
- `source_run.protocol`: Protocol acronym
- `source_run.run_version`: From `#Protocol.version` in the loaded `.opt.cue` file. If the protocol has no `#Protocol` type (currently: ADP only), use `"n/a"` and note this in the `notes` field.
- `source_run.subject`: User's problem text (after flag stripping)
- `source_run.started` / `completed`: ISO 8601 using today's date, `T00:00:00Z` time portion
- `dispute.prior_runs`: Default `[]`
- `resolution.status`: `"decided"` if canonical/adopted/validated, `"open"` if indeterminate, `"rejected"` if all eliminated
- `resolution.eliminated_count` and `survivors`: From derived phase data
- `acknowledged_limitations`: From scope_narrowing rebuttals
- `dependencies.consumed` / `produced`: Default `[]`
- `tags`: Auto-generated — protocol category, protocol acronym lowercase, resolution status (e.g., `["adversarial", "cffp", "decided"]`)
- `next_actions`: Populated ONLY when the protocol explicitly names a follow-up (CDP → CFFP, RCP blocked → CBP). No speculative suggestions.
- `notes`: Default `""`

**`dispute.kind` mapping** (structural feature → #DisputeKind):

| Structural Feature | DisputeKind |
|---|---|
| `competing_candidates` | `candidate_selection` |
| `term_inconsistency` | `term_ambiguity` |
| `argument_fragility` | `assumption_audit` |
| `unknown_design_space` | `design_mapping` |
| `construct_incoherence` | `construct_repair` |
| `implementation_gap` | `implementation_check` |
| `revision_pressure` / `deprecation_pressure` | `governance_case` |
| `cross_run_conflict` | `cross_run_conflict` |
| `structural_transfer` | `analogy_transfer` |
| `composition_emergence` | `composition_emergence` |
| `observation_validity` | `observation_validity` |
| `resource_constrained_choice` | `prioritization` |
| `causal_ambiguity` | `candidate_selection` (note in dispute.description that this is causal hypothesis elimination) |

**Ambiguous/unroutable routing with `--record`:** Same behavior as `--structured` — clarifying question in plain text; unroutable returns `{"outcome": "unroutable", "message": "..."}`.

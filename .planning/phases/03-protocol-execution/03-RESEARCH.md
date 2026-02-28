# Phase 3: Protocol Execution - Research

**Researched:** 2026-02-28
**Domain:** Claude-native protocol execution — CUE schema interpretation, narrative output generation, obligation gate enforcement, revision loop handling, and multi-protocol continuity
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Narrative structure:**
- Hybrid approach: protocol phases are visible via headers/dividers, but reasoning within each phase is narrative prose — not schema dumps
- Protocol-specific terminology (counterexample, obligation gate, scope narrowing) is used but explained inline on first use; subsequent uses are bare
- Output length scales with protocol complexity — CFFP output will be longer than a simpler evaluative protocol; the schema's depth drives how much reasoning is shown
- Brief context bridge sentence connects routing decision to execution: "Because your problem involves competing candidates, we'll formalize invariants first..." Then into phases

**Obligation gate behavior:**
- Hard stop when an obligation gate can't be satisfied — no forcing past unmet gates, no best-effort workarounds
- Eager enforcement at every phase transition, not just schema-defined explicit gate points — if Phase 2 requires "at least one candidate", enforce it before Phase 3
- When execution is blocked: show all completed phases up to the gate in full, then a clear diagnosis of what obligation failed and why
- Include actionable suggestions for how the user could reframe or modify their input to get past the blocker on a re-run

**Revision loop behavior:**
- Auto-retry once when no candidates survive: Claude diagnoses the failure, revises parameters, and re-runs adversarial phases
- Exception: if diagnosis is "construct_incoherent", skip retry entirely — report immediately with "reframe_and_close" outcome (retrying an incoherent construct won't help)
- If the second pass also fails, report and stop — no infinite loops
- Failed first pass is summarized briefly ("All 3 candidates were eliminated because..."), then the revision diagnosis and retry shown in full
- Diagnosis labels from the schema are explicit in the output: "Revision triggered: invariants_too_strong — relaxing invariant I3..."

**Multi-protocol continuity:**
- Explicit handoff section between sequenced protocols: "OVP established that the observation is valid. Feeding this into HEP to investigate the cause..."
- When first protocol invalidates the need for the second: explain why the sequence ends, show full output of the completed protocol, and suggest alternatives for what the user might do next
- Initial composite routing overview only — no redundant routing block when the second protocol begins
- Explicit input mapping between protocols: "From OVP: the observation is valid with these characteristics. HEP will use this as its starting hypothesis set."

### Claude's Discretion

- Exact phase header formatting and visual styling
- How to handle ADP's multi-persona rounds in narrative (persona voice vs narrator summary)
- Compression strategy when protocols are simpler (evaluative protocols may need fewer sections)
- Error handling for malformed or ambiguous user input that routing accepted but execution can't meaningfully process

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| EXEC-01 | Skill can execute all 6 adversarial protocols (CFFP, CDP, CBP, HEP, ATP, EMP) by reading their .cue schemas | Each adversarial protocol has a reviewed .opt.cue file; all follow the same Phase1→Phase2→Phase3→derived→Phase3b?→Phase4?→Phase5→Phase6 pattern with protocol-specific challenge/rebuttal/elimination types; execution instructions in SKILL.md tell Claude to read the selected protocol's .opt.cue and work through its phases |
| EXEC-02 | Skill can execute all 6 evaluative protocols (AAP, IFA, RCP, CGP, PTP, OVP) by reading their .cue schemas | Each evaluative protocol has a reviewed .opt.cue file; all follow the same subject→criteria→assessment→verdict pattern (some with 4 phases, some with 5); simpler phase structures than adversarial protocols; OVP is the shallowest (4 phases), RCP the most complex (5 phases with vocabulary alignment) |
| EXEC-03 | Skill can execute the exploratory protocol (ADP) by reading its .cue schema | ADP .opt.cue reviewed; uses multi-persona rounds (formalist, implementor, adversary, operator, consumer, referee); produces a DesignMap and referee_declaration; distinct execution model from adversarial and evaluative families |
| EXEC-04 | Obligation gates (#ObligationGate) are enforced during adversarial protocol execution — derivation blocked until all obligations satisfied | All 6 adversarial protocols have Phase5 with `obligations: [...] all_satisfied: bool` (CFFP: #StaticObligation, HEP: #ExplanationObligation, CBP: #ResolutionObligation, CDP: #PartReadiness, ATP: #TransferObligation, EMP: #ImpactObligation); Phase6 is conditional on Phase5 passing; the kernel dialectics.opt.cue defines #ObligationGate with `all_satisfied: bool` |
| EXEC-05 | When no candidates survive adversarial pressure, the revision loop (#RevisionLoop) triggers feedback rather than forcing a false conclusion | All 6 adversarial protocols define #Phase3b with `triggered: bool`, `diagnosis` enum (protocol-specific), and `resolution` enum; CFFP diagnoses: invariants_too_strong/candidates_too_weak/construct_incoherent; HEP: exhaustiveness_failed/space_needs_expansion/new_hypotheses_needed; CBP: usages_insufficient/candidates_too_weak/term_irredeemable; CDP: evidence_insufficient/candidates_too_weak/construct_not_decomposable; ATP: correspondence_too_strong/candidates_too_weak/transfer_not_viable; EMP: candidates_too_weak/behavior_not_emergent/observation_insufficient |
| OUTP-01 | User receives narrative prose by default explaining routing rationale, protocol execution steps, and conclusion | SKILL.md Execution section will instruct Claude to produce narrative prose that walks through each protocol phase; all completed phases shown in full before any gate blocks; Phase headers provide structure while reasoning within each phase is prose |
</phase_requirements>

---

## Summary

Phase 3 execution is entirely implemented as natural language instructions in SKILL.md, with each protocol's `.opt.cue` file as the machine-readable schema Claude interprets at execution time. There is no code to write, no new files beyond SKILL.md modification, and no external dependencies. The "stack" is: SKILL.md execution instructions + per-protocol .opt.cue schema + Claude's reasoning capability.

The protocol families have distinct structures that drive different execution models. The 6 adversarial protocols (CFFP, CDP, CBP, HEP, ATP, EMP) all follow the same Phase1→Phase2→Phase3→derived→Phase3b?→Phase4?→Phase5→Phase6 pattern with protocol-specific challenge/rebuttal/elimination types. Phase5 is always the obligation gate. Phase3b is always the revision loop trigger. Phase6 only executes when Phase5 passes. The 6 evaluative protocols (AAP, IFA, RCP, CGP, PTP, OVP) have simpler 4-5 phase structures with no revision loops and no explicit obligation gates. ADP (exploratory) has a completely different model: multi-persona adversarial rounds culminating in a referee declaration and DesignMap.

The primary design challenge is instruction precision for three cross-cutting concerns: (1) obligation gate enforcement that is eager (enforced at every phase transition, not just schema-declared gates), (2) revision loop behavior that handles the `construct_incoherent` exception and second-pass failure, and (3) multi-protocol continuity that transfers state between OVP and HEP explicitly. The current SKILL.md Execution section is a single-line placeholder that must be replaced with complete execution instructions.

**Primary recommendation:** Implement Phase 3 as two plans in SKILL.md: Plan 1 covers adversarial protocol execution (the more complex family with obligation gates and revision loops), Plan 2 covers evaluative and exploratory protocols plus multi-protocol handoff logic. Both plans modify only SKILL.md and reference the already-existing .opt.cue files.

---

## Standard Stack

### Core

| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| SKILL.md execution section | n/a | Natural language instructions that tell Claude how to execute each protocol family | SKILL.md is the only execution surface — all logic lives here as instructions Claude follows |
| Per-protocol `.opt.cue` files | already exist in `protocols/` | Schemas Claude reads at execution time to understand phase structure, types, and constraints | Already generated in Phase 1; Claude reads only the selected protocol's .opt.cue; never loads all 13 at once |
| `protocols/dialectics.opt.cue` | already exists | Kernel primitives: #ObligationGate, #RevisionLoop, #Adversarial, #Evaluative, #Exploratory | Already loaded in preflight; defines the shared structural vocabulary Claude uses across all protocols |

### Supporting

| Component | Purpose | When to Use |
|-----------|---------|-------------|
| Individual protocol `.opt.cue` Phase3b fields | Revision loop diagnosis labels and resolution enums | Claude reads these from the loaded protocol schema to produce explicit diagnosis labels in output |
| Individual protocol `.opt.cue` Phase5 fields | Obligation fields and `all_satisfied` bool | Claude reads these to determine gate behavior; each protocol has a distinct Phase5 obligation type |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Single execution section for all 13 protocols | Separate per-protocol instruction blocks | Per-protocol blocks would be verbose and hard to maintain; adversarial/evaluative/exploratory families have enough shared structure to be handled with family-level instructions plus protocol-specific handling for edge cases |
| Inline schema field descriptions in instructions | Directing Claude to read .opt.cue and interpret fields directly | The .opt.cue files are already optimized for agent context; pointing Claude at them is more reliable than attempting to re-describe what the schemas already say |

**Installation:**
No new packages or files beyond SKILL.md modification. All .opt.cue files already exist from Phase 1.

---

## Architecture Patterns

### Recommended Project Structure

No new directories. The execution section replaces the Phase 2 placeholder in the existing SKILL.md.

```
.claude/skills/socrates/
├── SKILL.md                          ← Modified: replace Phase 2 execution placeholder with full execution logic
│   ├── ## Preflight                  (unchanged)
│   ├── ## Input                      (unchanged)
│   ├── ## Protocol Files             (unchanged)
│   ├── ## Routing                    (unchanged from Phase 2)
│   └── ## Execution                  ← REPLACED: complete execution instructions
│       ├── Context bridge
│       ├── Adversarial protocol family
│       │   ├── Phase structure walk-through
│       │   ├── Obligation gate enforcement (eager)
│       │   ├── Revision loop handling (with construct_incoherent exception)
│       │   └── Phase headers + narrative prose pattern
│       ├── Evaluative protocol family
│       │   ├── Phase structure walk-through
│       │   └── Phase headers + narrative prose pattern
│       ├── ADP (exploratory)
│       │   └── Persona round handling + DesignMap output
│       └── Multi-protocol handoff
│           ├── Explicit state transfer between protocols
│           └── Early termination handling
│
└── protocols/                        (unchanged — all files already exist from Phase 1)
    ├── dialectics.opt.cue
    ├── routing.opt.cue
    ├── adversarial/{atp,cbp,cdp,cffp,emp,hep}.opt.cue
    ├── evaluative/{aap,cgp,ifa,ovp,ptp,rcp}.opt.cue
    └── exploratory/adp.opt.cue
```

### Pattern 1: Adversarial Protocol Execution Model

**What:** All 6 adversarial protocols share the same phase flow. SKILL.md execution instructions walk Claude through this flow, reading phase-specific types from the loaded .opt.cue.

**Phase flow (universal for all 6 adversarial protocols):**

```
Phase 1: Establish starting conditions
  → Eager gate: "at least one X required" — stop before Phase 2 if not met

Phase 2: Generate candidates/hypotheses
  → Eager gate: "at least one candidate required" — stop before Phase 3 if not met

Phase 3: Adversarial pressure (challenges + rebuttals)
  → Compute derived: eliminated list + survivors list

If derived.survivors is empty:
  → Phase 3b (revision loop)
  → Diagnose: [protocol-specific diagnosis enum]
  → Exception: diagnosis == "construct_incoherent" → skip retry, reframe_and_close
  → Otherwise: revise, retry Phases 2-3 ONCE
  → If second pass also fails: report and stop

If derived.survivors has > 1:
  → Phase 4: Select one survivor (selection with rationale)

Phase 5: Obligation gate
  → Evaluate all_satisfied
  → Hard stop if any obligation fails — show completed phases + diagnosis + suggestions
  → Phase 6 only executes when all_satisfied == true

Phase 6: Adoption / canonical form
```

**Protocol-specific challenge types (what Phase 3 challenges look like per protocol):**

| Protocol | Phase 3 Challenge Types | Rebuttal Kinds |
|----------|------------------------|----------------|
| CFFP | #Counterexample, #CompositionFailure | refutation, scope_narrowing (CompositionFailure: not rebuttable) |
| HEP | #EvidenceRebuttal + #AccumulatedPressure + #CrossSupport | refutation, scope_narrowing, evidence_unreliability |
| CDP | #BoundaryCounterexample, #RecompositionChallenge, #NaturalnessChallenge, #CompositionFailure | refutation, scope_narrowing (RecompositionChallenge: refutation only) |
| CBP | #CoverageGapChallenge, #DefinitionCollisionChallenge, #NamingPressureChallenge, #ConnotationPressureChallenge | refutation, scope_narrowing; NamingPressure: triggers name revision (does not eliminate) |
| ATP | #DisanalogyCE, #DomainMismatch, #ScopeChallenge | refutation, scope_narrowing (DomainMismatch: refutation only) |
| EMP | #ReductionChallenge, #ScopeChallenge, #CompositionCE | refutation, scope_narrowing |

**Protocol-specific elimination reasons (diagnosis vocabulary):**

| Protocol | Elimination Reasons |
|----------|-------------------|
| CFFP | counterexample_unrebutted, counterexample_invalid_rebuttal, composition_failure |
| HEP | decisive_inconsistency, strong_inconsistency_unrebutted, accumulated_weak_pressure |
| CDP | boundary_counterexample_unrebutted, recomposition_challenge_unrefuted, composition_failure, naturalness_dominated |
| CBP | coverage_gap_unrebutted, definition_collision_unrebutted, connotation_pressure_unrebutted, naming_revision_failed |
| ATP | disanalogy_ce_unrebutted, domain_mismatch_unrebutted, scope_challenge_unrebutted |
| EMP | reduction_unrebutted, scope_challenge_unrebutted, composition_ce_unrebutted |

**Protocol-specific revision loop diagnosis enums:**

| Protocol | Phase3b Diagnosis Values |
|----------|------------------------|
| CFFP | invariants_too_strong, candidates_too_weak, construct_incoherent |
| HEP | exhaustiveness_failed, space_needs_expansion, new_hypotheses_needed |
| CDP | evidence_insufficient, candidates_too_weak, construct_not_decomposable |
| CBP | usages_insufficient, candidates_too_weak, term_irredeemable |
| ATP | correspondence_too_strong, candidates_too_weak, transfer_not_viable |
| EMP | candidates_too_weak, behavior_not_emergent, observation_insufficient |

**Note on HEP:** HEP has a Phase3b with `trigger_reason: "zero_survivors" | "new_hypothesis_indicated"` — the trigger reason is distinct from the diagnosis. HEP also has unique Phase4 logic: if single_survivor, do confidence assessment; if multiple survivors, attempt to design discriminating experiments.

**Note on CDP:** CDP Phase6 produces `authorized_parts` (at least two) + `recomposition_proof` + `cffp_instructions` — it explicitly seeds downstream CFFP runs. Claude should note this in the conclusion.

### Pattern 2: Evaluative Protocol Execution Model

**What:** All 6 evaluative protocols share a simpler flow: establish subject → define criteria → assess against criteria → deliver verdict. No revision loops. No obligation gates in the adversarial sense. Phase count varies from 4 (OVP, CGP, PTP) to 5 (AAP, IFA, RCP) to 6 (AAP).

**Phase flow summary by protocol:**

| Protocol | Phases | Terminal Output |
|----------|--------|-----------------|
| AAP | 6 (subject → extraction → plausibility → stress-test → fragility map → recommendations → audit record) | #FragilityMap + tier ranking + recommendations |
| IFA | 5 (canonical ref + impl → obligations → evaluation → verdict → remediation) | #FidelityVerdict: faithful/divergent/indeterminate |
| RCP | 5 (vocabulary alignment → conflict detection → resolution → reconciliation map → record) | #ReconciliationMap: compatible/reconciled/conflicted/mixed |
| CGP | 5 (canonical + case → invariant health → successor readiness → dependent impact → verdict) | #Verdict: admissible_revision/inadmissible/deprecated/conditional_retention/deferred |
| PTP | 5 (options + constraints → criteria → scoring → ranking → decision) | #RankedOption list + top_choice |
| OVP | 4 (phenomenon → validity criteria → challenges → verdict) | #OVPVerdict: validated/contested/artifact |

**Key difference from adversarial:** Evaluative protocols do not have Phase3b revision loops. A failed/indeterminate result is the terminal outcome — there is no auto-retry. Claude reports the verdict and stops.

**RCP special handling:** RCP operates on multiple existing protocol runs, not on a fresh problem. Phase1 performs vocabulary alignment and may produce `cbp_blockers: []` (homonyms that require a CBP run before conflict detection proceeds). If `blocked: true`, Claude must report the blocker and stop rather than proceeding to Phase2.

**CGP note:** CGP handles three case kinds (revision, deprecation, combined). The phases activated depend on which case kind was presented. `preservation_checks` only applies for revision/combined cases; `erosion_assessments` only for deprecation/combined cases.

### Pattern 3: ADP (Exploratory) Execution Model

**What:** ADP uses 5-6 named personas conducting multi-round discussions. The referee persona manages convergence. Claude narrates the rounds rather than speaking in first-person as each persona.

**Execution model:**
1. Establish the subject type (new_construct, new_domain, breaking_change, or decision)
2. Declare the design constraints that apply to this run
3. Run probe round: each persona explores the problem space from their mandate
4. Run pressure round: personas challenge each other's positions
5. Run synthesis round: positions converge, referee identifies CFFP-readiness or live issues
6. If not converged: run additional rounds or declare scope_reduction
7. Referee declares outcome: design_mapped, exhaustion, or scope_reduction
8. Produce #DesignMap (if design_mapped)

**Persona mandates (from adp.opt.cue — these drive the substance of each round):**
- formalist: "Decidability, completeness, soundness. Every construct must have formal guarantees or be rejected."
- implementor: "Feasibility, performance, operational reality. Knows what gets built under deadline pressure."
- adversary: "Hostile or naive implementer. Finds every place where spec intent and spec text diverge."
- operator: "Production deployment, versioning, migration, observability, incident response."
- consumer: "End user of whatever is being designed, human or machine. Asks whether the output is actually usable."
- referee: "Neutral process management. Does not advocate. Applies design constraint checks."

**Narrator vs persona voice:** Per Claude's discretion in CONTEXT.md. Recommended approach: Claude narrates what each persona argues rather than speaking as the persona. This maintains narrative coherence and avoids the prose becoming a multi-character dialogue that's hard to follow.

**Constraint checks:** After each round, the referee applies constraint checks to all proposals. `#ConstraintCheckSet.passed` must be `true` for a proposal to proceed. Failed constraints block the proposal.

### Pattern 4: Obligation Gate Enforcement

**What:** Eager gate enforcement means Claude checks obligations at every phase transition, not just at the schema's explicit Phase5 gate.

**Eager gate conditions to enforce before each phase:**

| Check | Enforced Before | Schema Location |
|-------|-----------------|-----------------|
| At least one invariant/hypothesis/usage | Phase 2 | Phase1 schema has `[_, ...]` constraint |
| At least one candidate | Phase 3 | Phase2 schema has `candidates: [_, ...]` |
| All counterexamples have assessments (HEP) | Phase 3b computation | Phase2 `assessments` must cover all evidence |
| derived.survivors non-empty | Phase 4/5 normal path | #Derived.survivors check |
| Phase5.all_satisfied == true | Phase 6 | Explicit schema gate |
| CDP: phase5.all_ready == true | Phase 6 | `#Phase5.all_ready` bool |
| IFA: no `cbp_required` in RCP Phase1 | Phase 2 (RCP) | `blocked: bool` field |

**When a gate fails:**
1. Show all completed phases in full (the journey matters)
2. Display a clear diagnosis: which obligation failed and why
3. Provide actionable suggestions: how to reframe input or what the user could provide to satisfy the gate
4. Stop — no workarounds, no forced continuation

**Example gate failure output structure:**
```
[Phase 1 output — shown in full]
[Phase 2 output — shown in full]

Gate: Phase 3 cannot proceed.

The problem requires at least one candidate [candidate type], but [diagnosis of why none could be formulated — e.g., "the construct as described doesn't have a well-defined evaluation rule to formalize"].

To proceed: [specific actionable suggestion — e.g., "Try rephrasing the construct's evaluation rule more precisely, or consider starting with ADP to map the possibility space first."]
```

### Pattern 5: Revision Loop Handling

**What:** When `derived.survivors` is empty after Phase 3, Claude triggers the revision loop rather than forcing a false conclusion.

**Revision loop execution flow:**
1. Summarize the failed first pass briefly: "All N candidates were eliminated because [diagnosis of what pressure they couldn't survive]"
2. Identify the Phase3b `diagnosis` label from the protocol's enum
3. Check: is `diagnosis == "construct_incoherent"` (CFFP), `"construct_not_decomposable"` (CDP), or `"transfer_not_viable"` (ATP)?
   - Yes: skip retry. Report immediately with the reframe_and_close equivalent. Explain why retrying won't help.
   - No: proceed to revision
4. Diagnosis label is EXPLICIT in output: "Revision triggered: invariants_too_strong — relaxing invariant I3..."
5. Apply the `resolution` (e.g., revise_invariants, revise_candidates)
6. Re-run Phase 2 and Phase 3 with revised parameters (full output shown)
7. If second pass also produces empty survivors: report and stop ("Both passes eliminated all candidates. [Summary of what this means for the problem.]")

**Note on revision loop counter:** HEP's Phase3b tracks `revision_count: uint` explicitly in the schema. CDP's Phase3b has `max_revisions: uint`. Claude should respect these limits and not retry past the schema-declared maximum.

### Pattern 6: Narrative Prose Output Structure

**What:** Each phase renders as a section header followed by narrative prose, not schema fields listed sequentially.

**Phase header format (Claude's discretion per CONTEXT.md):**

Recommended:
```
### Phase 1: [Phase name in plain language]

[Narrative prose explaining what was established in this phase, using protocol vocabulary with inline explanations on first use]
```

**Terminology introduction pattern:**
- First use: "...a counterexample (a minimal concrete case demonstrating where an invariant fails)..."
- Subsequent uses: "...the counterexample C1 targets Candidate A's completeness claim..."

**Output length guidance:**
- Adversarial protocols (CFFP, CDP, CBP): Long output expected — each candidate requires Phase1-2 setup, Phase3 challenge-rebuttal cycles, Phase5 obligations. Typical: 6-8 sections.
- HEP, ATP, EMP: Moderate length — Phase1 hypothesis/source setup + Phase2-3 evidence/challenge cycles + Phase4 confidence/discrimination.
- Evaluative protocols (AAP, PTP): Moderate length — systematic criteria evaluation. OVP, IFA, CGP: shorter (4-5 phases, less cyclical).
- ADP: Length scales with number of rounds; 2-3 rounds is typical.

### Anti-Patterns to Avoid

- **Showing the schema dump:** Outputting CUE field names and values directly (e.g., "candidates: [{id: 'C1', description: ...}]") instead of narrative prose. The output is for humans, not machines.
- **Skipping phases:** Every phase must appear in the output, even if brief. No silent elision.
- **Forcing past a gate:** When Phase5 `all_satisfied: false`, continuing to Phase6 because "the candidate was close". Hard stop is mandatory.
- **Single-pass revision loop:** Treating Phase3b as a one-shot fix. The revision re-runs the adversarial phases fully and can itself produce an empty survivors set (which terminates the run).
- **Schema vocabulary without explanation:** Using "scope_narrowing rebuttal" without explaining it on first occurrence. Protocol vocabulary must be introduced inline.
- **Redundant routing block in multi-protocol runs:** When transitioning from OVP to HEP, no new routing block — only the handoff section that maps OVP output to HEP input.
- **ADP as first-person dialogue:** Writing "As the formalist, I object to..." instead of "The formalist challenges this proposal on decidability grounds, arguing..."

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Protocol phase structure | Hard-code phase sequence in SKILL.md | Direct Claude to read the selected protocol's .opt.cue | The schema defines the phase structure; Claude interprets it directly — no need to re-specify what the schema already says |
| Obligation gate logic | Write conditional branch logic in SKILL.md | Instruct Claude to check each Phase5 `all_satisfied` field | The schema already declares what must be satisfied; Claude applies the boolean gate |
| Revision loop detection | Write custom survivors-check logic | Instruct Claude to check `derived.survivors` emptiness | The #Derived type already defines the survivors list; empty = revision loop triggers |
| Terminology glossary | Embed a glossary of all protocol terms | Let protocol .opt.cue field names and comments teach terms in context | Terms acquire meaning through use in the output, not from a front-matter glossary |
| Phase3b diagnosis logic | Build a diagnosis decision tree | Instruct Claude to derive diagnosis from what pressure the candidates couldn't survive, then find the matching enum label in the protocol's #Phase3b | The schema's diagnosis enum values are semantically named — Claude matches what happened to the closest label |

**Key insight:** Phase 3 has no engineering complexity beyond instruction authoring. The schemas define everything. The hard part is writing SKILL.md instructions that correctly sequence the execution, enforce gates eagerly, handle the revision loop exception cases, and produce coherent narrative across all 13 protocols without becoming a 500-line instruction document.

---

## Common Pitfalls

### Pitfall 1: Protocol-Specific Phase Numbering Inconsistencies

**What goes wrong:** Not all adversarial protocols use the same phase count. CFFP has 6 phases (Phase1-6) with Phase4 being optional (CollapseResult — only when >1 survivor) and Phase6 conditional on Phase5. HEP has 6 phases but Phase4 has two branches (single_survivor vs multi-survivor discrimination). CDP has Phase4 only when multiple survivors, Phase6 only when phase5.all_ready. Evaluative protocols range from 4 phases (OVP) to 6 phases (AAP, IFA, RCP).

**Why it happens:** SKILL.md execution instructions that describe "phases 1-6" generically will cause Claude to attempt phases that are conditional or absent in certain protocols.

**How to avoid:** Execution instructions must be schema-directed: "Follow the phases defined in the loaded .opt.cue, executing optional phases only when their conditions are met." Claude reads the protocol schema and determines which phases apply to the current run. Don't enumerate phases numerically in SKILL.md instructions.

**Warning signs:** Claude attempts Phase6 without Phase5 succeeding, or attempts Phase4 when there is only one survivor.

### Pitfall 2: Obligation Gate Conflation

**What goes wrong:** The kernel `#ObligationGate` type and the protocol-specific Phase5 obligations are structurally similar but not identical. CFFP Phase5 uses `#StaticObligation` (with `provable: bool`), HEP uses `#ExplanationObligation` (with `satisfied: bool`), CBP uses `#ResolutionObligation` (with `satisfied: bool`), CDP uses `#PartReadiness` (with `ready: bool` as the conjunction of several sub-checks), ATP uses `#TransferObligation`, EMP uses `#ImpactObligation`. The gate field names differ (provable vs satisfied vs ready).

**Why it happens:** SKILL.md instructions that say "check the `satisfied` field" will break for CFFP (which uses `provable`) and CDP (which uses `ready`).

**How to avoid:** Instructions must be schema-directed: "Check the obligation result field in Phase5 — this is `provable` in CFFP, `all_ready` in CDP, and `all_satisfied` in other adversarial protocols. The gate passes only when all obligations pass."

**Warning signs:** Claude proceeds to Phase6 after a CFFP obligation with `provable: false`, or treats CDP's `all_ready: false` as a soft warning.

### Pitfall 3: Revision Loop Exception Cases

**What goes wrong:** Three protocols have diagnoses that should skip retry: CFFP's `construct_incoherent`, CDP's `construct_not_decomposable`, and ATP's `transfer_not_viable`. If SKILL.md instructions only say "retry once when no survivors", Claude will retry even when retry is futile.

**Why it happens:** The retry-skip logic is implied by the diagnosis label's semantics (an incoherent construct can't be fixed by relaxing invariants) but not always structurally enforced in the schema.

**How to avoid:** SKILL.md execution instructions must explicitly enumerate the skip-retry diagnoses: "If the Phase3b diagnosis is `construct_incoherent` (CFFP), `construct_not_decomposable` (CDP), or `transfer_not_viable` (ATP), skip retry and report with the reframe_and_close resolution."

**Warning signs:** Claude retries a CFFP run after diagnosing `construct_incoherent`, producing a second pass that will also fail.

### Pitfall 4: SKILL.md Line Count Creep

**What goes wrong:** The Phase 2 routing section is ~100 lines. Adding execution instructions for 13 protocols across 3 families plus obligation gates, revision loops, multi-protocol handoffs, and narrative structure guidance could push SKILL.md over the 500-line body limit.

**Why it happens:** Each protocol family needs execution instructions, and the temptation is to be exhaustively specific about every protocol's nuances.

**How to avoid:** Execution instructions should be schema-directed and family-level. "Follow the adversarial execution model: read the selected protocol's .opt.cue, execute each phase in order, enforce gates, handle Phase3b" is 1 line, not 30. Protocol-specific handling (obligation gate field names, revision skip conditions, ADP's persona model) adds targeted lines. Target: 80-120 lines for the execution section.

**Warning signs:** Execution section exceeds 150 lines. Any section that re-describes what the schema already says.

### Pitfall 5: Multi-Protocol State Transfer Fidelity

**What goes wrong:** In an OVP→HEP sequence, the HEP phenomenon input must come from OVP's `#ValidatedObservation`. If SKILL.md instructions say only "proceed to HEP", Claude may re-derive the HEP phenomenon from the user's original problem description rather than from OVP's validated output.

**Why it happens:** Without explicit state transfer instructions, Claude defaults to the user's original input as the starting point for each protocol.

**How to avoid:** SKILL.md must include an explicit handoff instruction: "After OVP completes, extract the `validated_observation` from OVP's Phase4 output. Use this as the HEP `#Phenomenon.observation` input, preserving the caveats as known_exclusions in HEP's hypothesis set."

**Warning signs:** HEP's Phase1 phenomenon description is identical to the user's original problem statement rather than OVP's refined validated observation.

### Pitfall 6: ADP Persona Round Narrative Confusion

**What goes wrong:** ADP has 5 distinct personas each contributing to each round. Rendered as first-person dialogue ("As the formalist, I believe..."), this becomes a confusing multi-character play. Rendered as a bare transcript (Formalist: ..., Implementor: ...), it's mechanical. Neither matches the locked decision of narrative prose.

**Why it happens:** There's no precedent in SKILL.md for multi-persona content. The narration style is entirely Claude's discretion.

**How to avoid:** SKILL.md execution instructions should specify the narrator pattern: "For each ADP round, narrate what each persona argues in third person. Example: 'The formalist raises a decidability concern, arguing that...' The referee summarizes convergence at the end of each round."

**Warning signs:** ADP output reads as a play script rather than analytical narrative, or reads as a single unified voice that doesn't distinguish persona viewpoints.

---

## Code Examples

Verified patterns from schema analysis and Phase 2 SKILL.md conventions:

### Adversarial Protocol Execution Section in SKILL.md

```markdown
## Execution

Read the file at path for the selected protocol: `protocols/{adversarial|evaluative|exploratory}/{acronym}.opt.cue`

Begin with a context bridge sentence connecting the routing decision to the execution. Example: "Because your problem involves competing candidates under formal constraints, we'll apply CFFP — formalizing invariants first and pressure-testing candidate designs until one survives."

### Adversarial protocols (CFFP, CDP, CBP, HEP, ATP, EMP)

Execute the phases defined in the loaded .opt.cue in order:

**Phase 1:** Establish the starting conditions (invariants, phenomenon, term under investigation, source construct, composed forms, or subject — depending on protocol). Enforce the schema's minimum constraints: if Phase1 requires "at least one X" and none can be established, stop here with a gate diagnosis and suggestions for how to proceed.

**Phase 2:** Generate candidates/hypotheses. Enforce minimum: if at least one candidate cannot be formulated, stop with a gate diagnosis.

**Phase 3:** Apply adversarial pressure. For each candidate, generate challenges of the types defined in the protocol's Phase3 schema. For each challenge, evaluate whether a rebuttal holds. Compute derived: eliminated (with reason and source_id) + survivors (with scope_narrowings from valid scope_narrowing rebuttals).

**If derived.survivors is empty → Phase 3b (revision loop):**
- Briefly summarize: "All N candidates were eliminated because [what pressure they couldn't survive]."
- Identify the diagnosis label from the protocol's Phase3b diagnosis enum.
- If diagnosis is `construct_incoherent`, `construct_not_decomposable`, or `transfer_not_viable`: skip retry. Report with the reframe_and_close resolution. Stop.
- Otherwise: state diagnosis label explicitly ("Revision triggered: [diagnosis] — [what this means]") and apply the resolution. Re-run Phase 2 and Phase 3 in full with revised parameters.
- If the second pass also produces empty survivors: report and stop.

**If derived.survivors > 1 → Phase 4:** Select one survivor with explicit rationale.

**Phase 5 (obligation gate):** Evaluate all obligations defined in the protocol's Phase5 schema. The gate field is `all_satisfied` (most protocols), `all_provable` (CFFP), or `all_ready` (CDP). If the gate fails: show all completed phases in full, then a gate diagnosis stating which obligation failed and why, plus actionable suggestions. Stop — do not proceed to Phase 6.

**Phase 6** (only when Phase 5 gate passes): Produce the canonical form / adopted explanation / validated transfer / authorized parts / emergence map — per the protocol's Phase6 type.

Render each phase as a section header followed by narrative prose. Use protocol vocabulary with inline explanation on first use.
```

### Evaluative Protocol Execution Section in SKILL.md

```markdown
### Evaluative protocols (AAP, IFA, RCP, CGP, PTP, OVP)

Execute the phases defined in the loaded .opt.cue in order. These protocols do not have revision loops. A failed or indeterminate verdict is the terminal result.

**RCP special case:** After Phase 1 vocabulary alignment, check `blocked: bool`. If `blocked: true`, CBP runs are required before conflict detection can proceed. Report the blocking terms and stop.

**CGP special case:** Phase 2 activates preservation_checks for revision/combined cases, erosion_assessments for deprecation/combined cases. Only populate the phases relevant to the governance case kind.

Render each phase as a section header followed by narrative prose.
```

### Multi-Protocol Handoff (OVP → HEP) in SKILL.md

```markdown
### Multi-protocol handoff

After the first protocol completes, show an explicit handoff section before beginning the second:

"[First protocol] established that [key output]. This feeds into [second protocol] as follows: [explicit input mapping]."

For OVP → HEP: extract OVP's `validated_observation` (phenomenon, confidence, caveats). Use these as HEP's `#Phenomenon` input, incorporating OVP's caveats as `known_exclusions` in the initial hypothesis set.

If the first protocol's outcome invalidates the second (OVP returns `artifact`, making HEP unnecessary): explain the invalidation, show the first protocol's complete output, suggest alternatives. Stop.
```

### Obligation Gate Failure Output Pattern

```
### Phase 5: Obligation review

The analysis cannot proceed to a conclusion.

Obligation failed: [description of what must be provable/satisfied and why it isn't — e.g., "The decidability obligation requires an argument that evaluation terminates for all inputs, but the proposed evaluation rule for recursive cases has no demonstrated termination condition."]

To proceed, the formalization would need: [specific actionable suggestion — e.g., "a termination argument for the recursive case, or a scope restriction that explicitly excludes unbounded recursion."]

[Show what a revised formulation might look like, if possible]
```

### Revision Loop Output Pattern

```
### Revision triggered

All 3 candidates were eliminated: [brief summary of what pressure they couldn't survive — e.g., "each candidate's invariant claims were falsified by the counterexample showing non-termination in mutually recursive definitions."]

Revision triggered: **invariants_too_strong** — the invariants as formulated reject all viable formalizations. Relaxing invariant I3 ("decidability must hold for all possible inputs") to scope it to finite-depth inputs may admit a surviving candidate.

### Pass 2 — revised parameters

[Full Phase 2 and Phase 3 output with revised parameters]
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Execution placeholder in SKILL.md | Full execution instructions replacing the placeholder | Phase 3 (now) | Phase 2 left "Protocol execution will be implemented in a future update." — Phase 3 replaces this with real instructions |
| Agent instruction sections in protocol .opt.cue files | Stripped from .opt.cue by Phase 1 optimization | Phase 1 | adp.cue and rcp.cue had agent instruction sections that were stripped as documentation blocks — execution instructions live in SKILL.md, not in .opt.cue files |

**No deprecated approaches for this phase** — the .opt.cue schemas are current; no upstream dialectics submodule changes affect Phase 3 planning.

---

## Open Questions

1. **SKILL.md line count after Phase 3**
   - What we know: Phase 2 routing section adds ~100 lines to SKILL.md (current total: ~160 lines). Phase 3 execution section needs to cover 3 protocol families, obligation gate logic, revision loop handling, multi-protocol handoff, and narrative structure guidance.
   - What's unclear: Whether 80-120 lines is achievable while being specific enough to prevent protocol fidelity drift.
   - Recommendation: Write the execution section first, then review. If over 120 lines, look for family-level instructions that can replace protocol-specific elaboration. The test is whether a Claude agent following the instructions would faithfully execute CFFP's 6-phase flow with obligation gates and revision loops — not whether every edge case is enumerated.

2. **Plan split: single plan vs two plans**
   - What we know: Adversarial protocols (with gates and revision loops) are substantially more complex than evaluative and exploratory protocols. Combining all 13 protocols into one plan risks an overly large, hard-to-verify task.
   - What's unclear: Whether the execution instructions can be tested as a unit (all 13) or must be validated separately per family.
   - Recommendation: Two plans. Plan 1: adversarial family + obligation gate logic + revision loop handling. Plan 2: evaluative family + ADP + multi-protocol handoff. This allows Plan 1 to be verified against complex protocols (CFFP) before Plan 2 adds the simpler cases.

3. **ADP persona round narration style**
   - What we know: CONTEXT.md marks this as Claude's discretion. The two options are: (a) narrator voice describing each persona's position, (b) each persona speaks directly. The adp.opt.cue's `#PersonaPosition.content: string` doesn't prescribe a format.
   - What's unclear: Which format produces better narrative clarity for users unfamiliar with ADP's multi-persona model.
   - Recommendation: Use narrator voice in SKILL.md execution instructions (Pattern 3 in Architecture section). This is more readable for users encountering ADP for the first time, and aligns with the locked decision that "protocol-specific terminology is explained inline on first use."

4. **CDP's downstream CFFP authorization**
   - What we know: CDP Phase6 produces `cffp_instructions: string` — explicit seeds for downstream CFFP runs. This is unique among the 13 protocols.
   - What's unclear: Whether SKILL.md should instruct Claude to offer to run CFFP immediately after CDP, or simply note the downstream authorization in the conclusion.
   - Recommendation: Note the downstream authorization in the CDP conclusion without automatically triggering CFFP. The user may want to review the CDP output before proceeding. Include a suggestion: "CDP has authorized CFFP runs for each part. You can invoke `/socrates` with the part description to begin formalization."

---

## Protocol Family Reference

### Adversarial Protocols (Phase count and obligation gate field)

| Protocol | Phase Count | Phase3b | Phase4 | Obligation Gate Field | Phase6 Condition |
|----------|-------------|---------|--------|----------------------|-----------------|
| CFFP | 6 (+3b +4 optional) | yes (3 diagnoses) | when >1 survivor | `phase5.all_provable` | all_provable == true |
| HEP | 6 (+3b +4) | yes (3 diagnoses, 2 triggers) | always (2 branches) | `phase5.all_satisfied` | all_satisfied == true |
| CDP | 6 (+3b +4 optional) | yes (3 diagnoses) | when >1 survivor | `phase5.all_ready` | all_ready == true |
| CBP | 6 (+3b +4 optional) | yes (3 diagnoses) | when >1 survivor | `phase5.all_satisfied` | all_satisfied == true |
| ATP | 6 (+3b +4 optional) | yes (3 diagnoses) | when >1 survivor | `phase5.all_satisfied` | all_satisfied == true |
| EMP | 6 (+3b +4 optional) | yes (3 diagnoses) | when >1 survivor | `phase5.all_satisfied` | all_satisfied == true |

### Evaluative Protocols (Phase count and terminal verdict type)

| Protocol | Phase Count | Terminal Verdict |
|----------|-------------|-----------------|
| AAP | 6 | #Outcome: mapped/incomplete/incoherent |
| IFA | 5 | #FidelityVerdict: faithful/divergent/indeterminate |
| RCP | 5 | #RCPOutcome: compatible/reconciled/conflicted/incommensurable/mixed |
| CGP | 5 | #Verdict: admissible_revision/inadmissible/deprecated/conditional_retention/deferred |
| PTP | 5 | #Outcome: ranked/tied/insufficient_data |
| OVP | 4 | #OVPVerdict: validated/contested/artifact |

### Exploratory Protocol

| Protocol | Structure | Terminal Output |
|----------|-----------|-----------------|
| ADP | N rounds (probe → pressure → synthesis → handoff) | #DesignMap (design_mapped), or scope_reduction, or exhaustion |

---

## Sources

### Primary (HIGH confidence)

- `/Users/javier/projects/socrates/.claude/skills/socrates/protocols/dialectics.opt.cue` — Kernel primitives: #ObligationGate, #RevisionLoop, #Rebuttal, #Challenge, #Derived, #EliminationRecord, #SurvivorRecord, #Adversarial, #Evaluative, #Exploratory, #Run. Reviewed 2026-02-28.
- `/Users/javier/projects/socrates/.claude/skills/socrates/protocols/adversarial/cffp.opt.cue` — Full phase structure (Phase1-6), #Phase3b with 3 diagnoses, #StaticObligation (provable field), #CollapseResult (Phase4), #CanonicalForm (Phase6). Reviewed 2026-02-28.
- `/Users/javier/projects/socrates/.claude/skills/socrates/protocols/adversarial/hep.opt.cue` — Full phase structure, #Phase3b with trigger_reason field (unique), Phase4 dual-branch (single_survivor vs multi-survivor discrimination), #ExplanationObligation. Reviewed 2026-02-28.
- `/Users/javier/projects/socrates/.claude/skills/socrates/protocols/adversarial/cdp.opt.cue` — Full phase structure, #Phase3b with `construct_not_decomposable` diagnosis, #PartReadiness (Phase5 with `ready` bool), `cffp_instructions` in Phase6. Reviewed 2026-02-28.
- `/Users/javier/projects/socrates/.claude/skills/socrates/protocols/adversarial/cbp.opt.cue` — Full phase structure, CBP-specific challenge types (coverage gap, definition collision, naming pressure, connotation), #Phase3b. Reviewed 2026-02-28.
- `/Users/javier/projects/socrates/.claude/skills/socrates/protocols/adversarial/atp.opt.cue` — Full phase structure, analogy-specific challenges (disanalogy CE, domain mismatch, scope), `transfer_not_viable` diagnosis. Reviewed 2026-02-28.
- `/Users/javier/projects/socrates/.claude/skills/socrates/protocols/adversarial/emp.opt.cue` — Full phase structure, emergence-specific challenges (reduction, scope, composition CE), #ImpactObligation, #EmergenceMap. Reviewed 2026-02-28.
- `/Users/javier/projects/socrates/.claude/skills/socrates/protocols/evaluative/aap.opt.cue` — 6-phase structure, #FragilityMap, tier system, #StressTestResult. Reviewed 2026-02-28.
- `/Users/javier/projects/socrates/.claude/skills/socrates/protocols/evaluative/ifa.opt.cue` — 5-phase structure, #FidelityObligation, #DivergenceKind, #FidelityVerdict. Reviewed 2026-02-28.
- `/Users/javier/projects/socrates/.claude/skills/socrates/protocols/evaluative/rcp.opt.cue` — 5-phase structure, vocabulary alignment (synonyms/homonyms/neologisms), CBP blocker logic, #ReconciliationMap. Reviewed 2026-02-28.
- `/Users/javier/projects/socrates/.claude/skills/socrates/protocols/evaluative/cgp.opt.cue` — 5-phase structure, three governance case kinds (revision/deprecation/combined), #SuccessorReadiness, #Verdict. Reviewed 2026-02-28.
- `/Users/javier/projects/socrates/.claude/skills/socrates/protocols/evaluative/ptp.opt.cue` — 5-phase structure, #Criterion + #RankedOption, sensitivity analysis. Reviewed 2026-02-28.
- `/Users/javier/projects/socrates/.claude/skills/socrates/protocols/evaluative/ovp.opt.cue` — 4-phase structure, #ValidityCriterion (6 types), #OVPVerdict. Reviewed 2026-02-28.
- `/Users/javier/projects/socrates/.claude/skills/socrates/protocols/exploratory/adp.opt.cue` — Multi-persona model, #ADPPersona mandates (6 personas), #ADPRound types (probe/pressure/synthesis/handoff), #DesignMap, #ConstraintCheckSet. Reviewed 2026-02-28.
- `.planning/phases/03-protocol-execution/03-CONTEXT.md` — All locked decisions for narrative structure, obligation gate behavior, revision loop behavior, and multi-protocol continuity. Reviewed 2026-02-28.
- `.planning/STATE.md` — Blocker documented: "6 adversarial protocols have multi-round challenge-rebuttal cycles — review protocol-specific phase structures before building to prevent fidelity drift." This research resolves that blocker. Reviewed 2026-02-28.
- `.planning/phases/02-routing/02-01-PLAN.md` — Plan format, task structure, and SKILL.md modification conventions used in Phase 2. Reviewed 2026-02-28.

### Secondary (MEDIUM confidence)

- None — all findings verified from primary sources in the project codebase.

### Tertiary (LOW confidence)

- None — all findings verified from primary sources.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all .opt.cue files exist and were read directly; SKILL.md is the only implementation surface; no external dependencies
- Architecture: HIGH — adversarial/evaluative/exploratory family patterns derived directly from reading all 13 .opt.cue files; phase structures and gate fields verified
- Obligation gate specifics: HIGH — each protocol's Phase5 obligation type and gate field name verified from schema source
- Revision loop diagnosis values: HIGH — all Phase3b diagnosis enums verified from schema source for all 6 adversarial protocols
- Narrative output guidance: MEDIUM — locked decisions from CONTEXT.md are clear, but exact prose patterns will need validation against real invocations
- SKILL.md line count: MEDIUM — target 80-120 lines for execution section is estimated; may need adjustment after writing

**Research date:** 2026-02-28
**Valid until:** 2026-03-28 (stable domain — .opt.cue schemas are stable; only risk is upstream dialectics submodule changes)

# Phase 3: Protocol Execution - Context

**Gathered:** 2026-02-28
**Status:** Ready for planning

<domain>
## Phase Boundary

All 13 CUE-schema-defined protocols execute with narrative output, obligation gates enforced, and revision loops triggered when needed. The user describes a problem, routing selects a protocol (Phase 2 — already complete), and now the protocol runs and produces rigorous narrative reasoning. Structured/typed output is a separate phase (Phase 4).

</domain>

<decisions>
## Implementation Decisions

### Narrative structure
- Hybrid approach: protocol phases are visible via headers/dividers, but reasoning within each phase is narrative prose — not schema dumps
- Protocol-specific terminology (counterexample, obligation gate, scope narrowing) is used but explained inline on first use; subsequent uses are bare
- Output length scales with protocol complexity — CFFP output will be longer than a simpler evaluative protocol; the schema's depth drives how much reasoning is shown
- Brief context bridge sentence connects routing decision to execution: "Because your problem involves competing candidates, we'll formalize invariants first..." Then into phases

### Obligation gate behavior
- Hard stop when an obligation gate can't be satisfied — no forcing past unmet gates, no best-effort workarounds
- Eager enforcement at every phase transition, not just schema-defined explicit gate points — if Phase 2 requires "at least one candidate", enforce it before Phase 3
- When execution is blocked: show all completed phases up to the gate in full, then a clear diagnosis of what obligation failed and why
- Include actionable suggestions for how the user could reframe or modify their input to get past the blocker on a re-run

### Revision loop behavior
- Auto-retry once when no candidates survive: Claude diagnoses the failure, revises parameters, and re-runs adversarial phases
- Exception: if diagnosis is "construct_incoherent", skip retry entirely — report immediately with "reframe_and_close" outcome (retrying an incoherent construct won't help)
- If the second pass also fails, report and stop — no infinite loops
- Failed first pass is summarized briefly ("All 3 candidates were eliminated because..."), then the revision diagnosis and retry shown in full
- Diagnosis labels from the schema are explicit in the output: "Revision triggered: invariants_too_strong — relaxing invariant I3..."

### Multi-protocol continuity
- Explicit handoff section between sequenced protocols: "OVP established that the observation is valid. Feeding this into HEP to investigate the cause..."
- When first protocol invalidates the need for the second: explain why the sequence ends, show full output of the completed protocol, and suggest alternatives for what the user might do next
- Initial composite routing overview only — no redundant routing block when the second protocol begins
- Explicit input mapping between protocols: "From OVP: the observation is valid with these characteristics. HEP will use this as its starting hypothesis set."

### Claude's Discretion
- Exact phase header formatting and visual styling
- How to handle ADP's multi-persona rounds in narrative (persona voice vs narrator summary)
- Compression strategy when protocols are simpler (evaluative protocols may need fewer sections)
- Error handling for malformed or ambiguous user input that routing accepted but execution can't meaningfully process

</decisions>

<specifics>
## Specific Ideas

- The user wants protocol rigor: hard stops at gates, eager enforcement, explicit diagnosis labels — the tool should feel like it's doing real formal reasoning, not hand-waving
- Failed reasoning is valuable: show completed work before gate blocks, summarize failed passes before retries — the journey matters, not just the conclusion
- Protocol vocabulary should be taught through use: terms appear with inline explanations on first use, building the user's understanding over time

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 03-protocol-execution*
*Context gathered: 2026-02-28*

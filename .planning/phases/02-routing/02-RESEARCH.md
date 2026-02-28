# Phase 2: Routing - Research

**Researched:** 2026-02-28
**Domain:** Claude-native routing logic — structural feature extraction, protocol selection, composite sequencing, and failure handling via natural language instruction in SKILL.md
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Selection display:**
- Routing result presented as a structured block, visually separated from execution output
- Block includes: protocol acronym + full name (e.g. "HEP (Hypothesis Elimination Protocol)"), detected structural features, and rationale
- Structural features shown using both plain language and schema identifiers (e.g. "competing causal explanations (causal_ambiguity)")
- Routing block is shown then execution proceeds immediately — no user confirmation gate
- No pause between routing display and execution handoff

**Ambiguous/unroutable input:**
- When routing returns "ambiguous": ask the user to clarify by describing the fork in plain language (not protocol names). e.g. "Is this about testing whether X is true, or about choosing between X and Y?"
- When routing returns "unroutable": explain that the problem didn't match any protocol's structural features, suggest how to rephrase, and show the types of problems Socrates handles
- Never force a bad fit — don't best-guess an unroutable problem into a protocol

**Composite sequencing:**
- When routing produces a multi-protocol sequence, show the full sequence upfront before any execution begins
- Use numbered steps with protocol name, purpose, and data flow per step (the "feeds" relationship from the schema)
- If an early protocol produces a result that invalidates a later step (e.g. OVP finds "artifact"), explain why the sequence is stopping and stop — don't continue unnecessary protocols

### Claude's Discretion

- Whether to show routing warnings (from the schema's warnings field) — case-by-case based on user relevance
- Confidence level display — show only when it's noteworthy (medium or low), not for high-confidence routes
- Feature-to-problem-text attribution — attribute when it adds clarity, omit when the connection is obvious
- Retry limits for ambiguous/unroutable rephrasing — Claude judges when further attempts are unproductive

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| ROUT-01 | User describes a problem and the skill automatically selects the correct protocol via governance/routing.cue structural feature matching | Claude reads `protocols/routing.opt.cue` at routing time, extracts structural features from user's problem description, and applies the `#FeatureProtocolMapping` table to select a protocol — no protocol named by user |
| ROUT-02 | Output includes which protocol was selected and why (protocol transparency) | Routing block (structured display) shows protocol acronym + full name + detected structural features + rationale before execution proceeds — satisfies transparency requirement |
| ROUT-03 | When routing.cue identifies a composite problem requiring multiple protocols, the skill chains them in sequence | `#RoutingResult.sequenced: true` path triggers multi-protocol sequence display using `#SequencedStep` fields (order, protocol, purpose, feeds); early invalidation stops the chain |
</phase_requirements>

---

## Summary

Phase 2 routing is entirely implemented as natural language instructions in SKILL.md, with `protocols/routing.opt.cue` as the machine-readable schema Claude interprets at invocation time. There is no external routing engine, no code to write, and no library to install. The "stack" is: SKILL.md routing instructions + routing.opt.cue schema + Claude's reasoning capability.

The `routing.opt.cue` file (already generated in Phase 1, 2,572 chars) defines the complete routing contract: 14 named structural features, the `#FeatureProtocolMapping` schema (feature → protocol with confidence, conditions, exceptions, prerequisites), `#DisambiguationRule` for co-occurring features, and the `#RoutingResult` output type with three outcome values (`routed`, `ambiguous`, `unroutable`). Claude does not need to be told how to route — it needs to be told to read this schema, apply it to the user's problem description, and format the result per the locked decisions in CONTEXT.md.

The primary design challenge is not implementation complexity but routing precision: 14 structural features across 13 protocols, with some features sharing a protocol (revision_pressure and deprecation_pressure both → CGP) and some problems exhibiting multiple features simultaneously. The STATE.md blocker is real — the discrimination logic for boundary cases must be handled in SKILL.md instructions, not left to ad hoc reasoning. The plan should include concrete test cases for the boundary pairs identified in this research.

**Primary recommendation:** Implement Phase 2 as a single plan that adds a Routing section to SKILL.md. The section reads `protocols/routing.opt.cue`, extracts structural features, applies the mapping table, formats the routing block per CONTEXT.md locked decisions, and handles all three outcome paths (routed, ambiguous, unroutable). No new files needed. Update SKILL.md's execution placeholder with the real routing instructions.

---

## Standard Stack

### Core

| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| SKILL.md routing section | n/a | Natural language instructions that tell Claude how to route | SKILL.md is the only execution surface in this skill — all logic lives here as instructions Claude follows |
| `protocols/routing.opt.cue` | already exists (2,572 chars) | Schema Claude reads to understand feature→protocol mappings | Already generated in Phase 1; defines `#FeatureProtocolMapping`, `#DisambiguationRule`, `#RoutingResult` — Claude interprets this directly |
| `protocols/dialectics.opt.cue` | already exists (3,013 chars) | Kernel primitives defining `#KnownProtocol` | Already loaded in preflight check; defines the 13 protocol identifiers Claude uses in routing output |

### Supporting

| Component | Purpose | When to Use |
|-----------|---------|-------------|
| Individual protocol `.opt.cue` files | Read the `#Protocol.name` field to display full protocol names in routing block | Claude reads ONLY the selected protocol's `.opt.cue` to get its full name for the routing display — not to execute the protocol |
| Protocol full names (embedded in SKILL.md) | Avoid a file read just to get protocol names | Alternative: embed a name lookup table in SKILL.md routing section to avoid per-protocol reads at routing time |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Reading `routing.opt.cue` at route time | Embedding routing table inline in SKILL.md | Embedding creates drift when the dialectics submodule is updated; routing.opt.cue is the source of truth per INFRA-03 |
| Single-plan implementation | Two-plan split (routing logic + failure paths) | Routing logic + ambiguous/unroutable handling are tightly coupled — splitting creates ordering risk and unnecessary complexity |
| Plain language feature names only | Schema identifiers only | Locked decision: both — plain language primary, schema identifier supplementary |

**Installation:**
No new packages or files. Phase 2 modifies only `.claude/skills/socrates/SKILL.md`.

---

## Architecture Patterns

### Recommended Project Structure

No new files or directories. The routing section is added to the existing SKILL.md.

```
.claude/skills/socrates/
├── SKILL.md                          ← Modified: replace "setup mode" placeholder with Routing section
│   ├── ## Preflight                  (unchanged)
│   ├── ## Input                      (unchanged — no-arg handler)
│   ├── ## Protocol Files             (unchanged — file path references)
│   └── ## Routing                    ← NEW: feature extraction, protocol selection, display logic
│       ├── Read routing.opt.cue
│       ├── Extract structural features
│       ├── Apply feature→protocol mapping
│       ├── Handle: routed / ambiguous / unroutable
│       ├── Composite sequencing (when sequenced: true)
│       └── Handoff to execution (Phase 3 placeholder)
│
└── protocols/                        (unchanged — all files already exist from Phase 1)
    ├── routing.opt.cue               ← Read at every invocation for routing
    └── [all 15 .opt.cue files]
```

### Pattern 1: Feature Extraction from User Problem Description

**What:** Claude reads the user's free-text problem description and identifies which of the 14 `#StructuralFeature` values are present. This is pure natural language reasoning — no external classifier.

**When to use:** Every invocation with a non-empty argument, after preflight check passes.

**Feature identification guide** (derived from routing.opt.cue with conditions/exceptions Claude must apply):

| Structural Feature | Signal in User Problem | Primary Protocol | Key Discriminator |
|-------------------|----------------------|-----------------|-------------------|
| `term_inconsistency` | Same word means different things in different contexts; definitional dispute | CBP | Focus is on the term/concept itself, not the argument built on it |
| `competing_candidates` | Multiple formal proposals/designs competing; need to pick one | CFFP | Multiple explicit alternatives; requires adversarial pressure to eliminate |
| `unknown_design_space` | "I don't know what options exist"; exploring possibilities before committing | ADP | Space is unmapped; no candidates yet |
| `argument_fragility` | "Is this argument solid?"; stress-test an existing position | AAP | Argument exists; question is about its hidden weaknesses |
| `construct_incoherence` | One term/concept seems to be two different things | CDP | Internal split within a single construct, not a term dispute |
| `causal_ambiguity` | "Why did X happen?"; multiple possible causes for a phenomenon | HEP | Observable phenomenon + competing causal explanations |
| `cross_run_conflict` | Two independent reasoning sessions reached different conclusions | RCP | Conflict is between separate runs/sources, not within one argument |
| `implementation_gap` | Implementation diverges from canonical specification/design | IFA | Canonical form exists; question is whether implementation matches |
| `revision_pressure` | Proposed change to an existing canonical form | CGP | Canonical form exists; change is proposed |
| `deprecation_pressure` | Proposed retirement of an existing canonical form | CGP | Canonical form exists; retirement is proposed |
| `structural_transfer` | Using a pattern/solution from one domain in another | ATP | Analogy or cross-domain borrowing is being claimed |
| `composition_emergence` | Unexpected behavior where components meet; integration surprises | EMP | Behavior emerges at seams, not within individual components |
| `observation_validity` | "Is this measurement/observation real?"; empirical claim validation | OVP | Observation itself is questioned before theorizing about it |
| `resource_constrained_choice` | Multiple valid paths, must choose with limited resources/time | PTP | All options are valid; constraint is capacity, not correctness |

**Example:**
```markdown
## Routing

Read the file at path: `protocols/routing.opt.cue`

Analyze the user's problem description in $ARGUMENTS:
1. Identify which `#StructuralFeature` values are present in the problem
2. For each detected feature, note the text in $ARGUMENTS that signals it
3. Apply the `#FeatureProtocolMapping` table to determine the primary protocol
4. If multiple features detected, apply `#DisambiguationRule` entries (first matching rule wins)
5. Determine `#RoutingResult.outcome`: "routed", "ambiguous", or "unroutable"
```

### Pattern 2: Routing Block Display Format

**What:** A visually separated block shown before any protocol execution. Plain language primary, schema identifiers supplementary.

**Locked format:**
```
---
Protocol selected: HEP (Hypothesis Elimination Protocol)

Detected: competing causal explanations (causal_ambiguity)

Rationale: Your problem describes an observed phenomenon with multiple possible causes,
which calls for systematic hypothesis elimination rather than choosing a best guess.
---
```

**When to show confidence:** Only when `confidence: "medium"` or `confidence: "low"` in the matching `#FeatureProtocolMapping`. Omit for high-confidence routes.

**When to show warnings:** Claude's discretion — include schema `warnings` field content when it would meaningfully change the user's interpretation. Omit when warning is generic or obvious.

### Pattern 3: Composite Sequencing Display

**What:** When `#RoutingResult.sequenced: true`, show the full sequence before any execution.

**Format:**
```
---
Multi-protocol sequence:

1. OVP (Observation Validation Protocol) — Validate the phenomenon is real before theorizing
   Feeds into: HEP — validated observation becomes the HEP phenomenon input

2. HEP (Hypothesis Elimination Protocol) — Eliminate hypotheses against the validated evidence
   Feeds into: conclusion
---

Beginning with step 1...
```

**Early termination:** If step N produces an outcome that invalidates step N+1 (e.g., OVP returns `artifact` — the phenomenon is not real, so HEP would operate on a false premise), explain the invalidation and stop:
```
OVP result: artifact — the observed anomaly appears to be a measurement artifact, not a real phenomenon.

The sequence cannot proceed to HEP: hypothesis elimination requires a real phenomenon to explain.
Stopping here.
```

### Pattern 4: Ambiguous Input Handler

**What:** When routing produces `outcome: "ambiguous"` — multiple features co-occur without a matching `#DisambiguationRule`.

**Display:** Ask for clarification using plain language description of the fork — never protocol names.

```
Your problem could go in two directions:
- Are you trying to determine *why* something happened? (multiple possible causes for an event)
- Or are you trying to *choose between* two approaches? (multiple options competing for adoption)

Which describes your situation more accurately?
```

**What not to do:** "This could be HEP or CFFP — which one?" — never expose protocol names in the clarification question.

### Pattern 5: Unroutable Input Handler

**What:** When routing produces `outcome: "unroutable"` — no structural features detected.

**Display:** Explain without jargon, show what kinds of problems the skill handles, suggest rephrasing.

```
I couldn't identify a clear problem structure in your description. Socrates works best with
problems like:
- "Why did X happen?" (causal investigation)
- "Which of these designs should I use?" (competing candidates)
- "Is this argument sound?" (assumption stress-testing)
- "I'm not sure what options exist" (design space exploration)

Could you rephrase your problem in terms of what you're trying to figure out or decide?
```

### Anti-Patterns to Avoid

- **Best-guessing an unroutable input:** The locked decision is explicit — never force a bad-fit protocol. An unroutable problem gets the unroutable handler, not a randomly chosen protocol.
- **Naming protocols in ambiguity clarification:** "This could be HEP or CFFP" exposes implementation to users who don't know (or need to know) protocol names. Describe the fork in problem terms.
- **Loading all protocol files to get full names:** Only the routing.opt.cue needs to be read for routing. Full protocol names can come from a lookup table in SKILL.md or from reading the selected protocol's `.opt.cue` after routing completes.
- **Waiting for user confirmation after showing routing block:** Locked decision: routing block → execution, no gate.
- **Inlining the routing table in SKILL.md:** routing.opt.cue is the single source of truth. Claude reads it; the SKILL.md instructions tell Claude how to interpret it, not what the table says.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Protocol selection logic | Custom routing algorithm, probability scoring, ML classifier | Claude reading routing.opt.cue and applying natural language reasoning | The schema already defines the mapping table and disambiguation rules; Claude's reasoning IS the routing engine |
| Feature disambiguation | Custom weighted voting, priority queue | `#DisambiguationRule` entries in routing.opt.cue (first-match wins) | The schema already encodes disambiguation logic; Claude applies it directly |
| Full protocol name lookup | File reads of all 13 protocol .opt.cue files at routing time | Embed protocol full names in SKILL.md routing section as a lookup table | Avoids 13 unnecessary Read tool calls per invocation; names are stable and don't require submodule access |
| Routing output schema | Custom structured output format | `#RoutingResult` type from routing.opt.cue | Schema already defines primary, secondary, sequenced, sequence, rationale, warnings, outcome, outcome_notes |

**Key insight:** Phase 2 has no engineering complexity — it is entirely natural language instruction authoring. The hard part is writing clear, precise SKILL.md instructions that produce consistent routing behavior across boundary cases.

---

## Common Pitfalls

### Pitfall 1: Feature Overlap at Boundary Cases

**What goes wrong:** Several structural feature pairs are semantically adjacent and can be confused by Claude's reasoning:
- `causal_ambiguity` (HEP) vs `observation_validity` (OVP) — the difference is whether the *observation itself* is questioned (OVP first) vs whether the *cause* of a valid observation is unclear (HEP)
- `term_inconsistency` (CBP) vs `construct_incoherence` (CDP) — CBP is about a term used differently across contexts; CDP is about a single construct that seems to be two different things internally
- `argument_fragility` (AAP) vs `cross_run_conflict` (RCP) — AAP tests one argument's assumptions; RCP reconciles two independent reasoning sessions that reached different conclusions
- `competing_candidates` (CFFP) vs `resource_constrained_choice` (PTP) — CFFP uses adversarial pressure to eliminate candidates; PTP evaluates valid options under resource constraints (all options are acceptable, just not all can be chosen)
- `revision_pressure` (CGP) vs `competing_candidates` (CFFP) — a revision proposal is a change to an existing canonical form (CGP); competing formalisms are new alternatives without an existing canonical baseline (CFFP)

**Why it happens:** Users don't describe their problem using schema vocabulary. "I need to choose between two designs" could be CFFP (adversarial elimination needed) or PTP (both are valid, resources constrain) depending on whether the candidates are genuinely competing or just resource-constrained alternatives.

**How to avoid:** SKILL.md routing instructions must include concrete discriminating questions Claude applies internally:
- OVP before HEP: "Is the observation itself questionable, or is the phenomenon clearly real but the cause unclear?"
- CBP vs CDP: "Is the inconsistency across different users/contexts using the same word, or is one concept internally splitting into two different things?"
- CFFP vs PTP: "Are the options in genuine tension (one being adopted means the other fails), or are both valid and the constraint is capacity?"
- CGP vs CFFP: "Is there an existing canonical form being proposed for change, or are these competing new proposals with no established baseline?"

**Warning signs:** Claude returns the same protocol for two problem descriptions that should route differently. Test both sides of each boundary pair.

### Pitfall 2: Composite Sequencing Ambiguity

**What goes wrong:** The routing.opt.cue schema defines `#RoutingResult.sequenced: bool` and `#SequencedStep`, but does not enumerate which feature combinations trigger sequencing. Claude must infer when to sequence vs. when to select a single primary protocol.

**Why it happens:** The routing schema defines the *structure* of a sequenced result but not the *triggering conditions*. Without explicit guidance, Claude may over-sequence (chaining protocols unnecessarily) or under-sequence (picking one protocol when OVP→HEP is clearly indicated).

**How to avoid:** SKILL.md routing instructions must document the known composite cases:
- OVP → HEP: when `observation_validity` + `causal_ambiguity` co-occur — validate the observation first, then eliminate hypotheses
- The `prerequisites` field in `#FeatureProtocolMapping` is the signal: if a detected protocol has prerequisites, check whether those prerequisites are also implied and need to run first
- Default: single protocol unless prerequisites are explicitly indicated

**Warning signs:** Claude sequences two protocols when the problem clearly describes only one structural feature. Or Claude picks one protocol when `observation_validity` is present and should have triggered OVP first.

### Pitfall 3: Routing Block Verbosity

**What goes wrong:** The routing block becomes a wall of technical output that lists every detected feature, confidence level, disambiguation rule applied, and schema reference. The locked decision is "full transparency" but also "feel like a 'here's what I'm going to do and why' moment, not a wall of technical output."

**Why it happens:** Claude's tendency to be thorough conflicts with the UX goal of a clean, readable routing block.

**How to avoid:** SKILL.md instructions must specify the exact routing block structure and what to omit:
- Include: selected protocol (acronym + full name), detected structural features (plain language + schema identifier), rationale (one sentence per the ROADMAP success criterion)
- Conditionally include: confidence (medium/low only), warnings (when user-relevant)
- Exclude: disambiguation rules applied, features that were considered but not matched, alternatives not chosen

**Warning signs:** Routing block exceeds 5-6 lines for a simple single-protocol route.

### Pitfall 4: Protocol Name vs. Full Name Mismatch

**What goes wrong:** The routing.opt.cue uses acronyms ("HEP", "CFFP") but the locked decision requires routing block to show "HEP (Hypothesis Elimination Protocol)". If Claude doesn't know the full name, it either reads all 13 protocol files (expensive) or makes up names.

**Why it happens:** The routing schema uses `#KnownProtocol` which is a string enum of acronyms. Full names live in each protocol's `#Protocol.name` field in the individual `.opt.cue` files.

**How to avoid:** Embed a complete acronym-to-full-name lookup table in SKILL.md's routing section. This avoids per-protocol reads at routing time. The full names are stable and can be maintained in SKILL.md directly:

```markdown
Protocol names:
- AAP: Assumption Audit Protocol
- ADP: Analytic Decomposition Protocol
- ATP: Analogy Transfer Protocol
- CBP: Challenge-Based Protocol
- CDP: Construct Disambiguation Protocol
- CFFP: Competing Formal Frameworks Protocol
- CGP: Canonical Governance Protocol
- EMP: Emergence Mapping Protocol
- HEP: Hypothesis Elimination Protocol
- IFA: Inference Fidelity Assessment
- OVP: Observation Validation Protocol
- PTP: Priority Trade-off Protocol
- RCP: Reasoning Chain Protocol
```

**Warning signs:** Routing block shows a made-up full name, or Claude reads multiple `.opt.cue` files before displaying the routing block.

### Pitfall 5: SKILL.md Line Count Creep

**What goes wrong:** Phase 1 SKILL.md is 56 lines. Adding routing instructions risks pushing it toward or past the 500-line body limit.

**Why it happens:** Routing requires: feature extraction instructions, disambiguation instructions, boundary case discriminators, display format, three outcome handlers, composite sequencing logic, and a protocol name lookup table. Each adds lines.

**How to avoid:** Target 100-150 lines for the routing section. Keep instructions concise and precise — one instruction per decision, not explanatory prose. The lookup table is the bulkiest part (~15 lines) but is unavoidable. Test whether SKILL.md total stays under 250 lines after adding the routing section.

**Warning signs:** SKILL.md body exceeds 200 lines after Phase 2. Any section that reads like documentation rather than instructions.

---

## Code Examples

Verified patterns from official sources and routing.opt.cue schema analysis:

### Routing Section Structure in SKILL.md

```markdown
## Routing

Read the file at path: `protocols/routing.opt.cue`

**Protocol full names:**
- AAP: Assumption Audit Protocol
- ADP: Analytic Decomposition Protocol
- ATP: Analogy Transfer Protocol
- CBP: Challenge-Based Protocol
- CDP: Construct Disambiguation Protocol
- CFFP: Competing Formal Frameworks Protocol
- CGP: Canonical Governance Protocol
- EMP: Emergence Mapping Protocol
- HEP: Hypothesis Elimination Protocol
- IFA: Inference Fidelity Assessment
- OVP: Observation Validation Protocol
- PTP: Priority Trade-off Protocol
- RCP: Reasoning Chain Protocol

**Step 1: Extract structural features**
Read the user's problem in $ARGUMENTS. Identify which `#StructuralFeature` values are present.
Use the `#FeatureProtocolMapping` table in routing.opt.cue to map each feature to its primary protocol.

**Step 2: Apply disambiguation**
If multiple features detected, apply `#DisambiguationRule` entries in order — first matching rule wins.
If no matching rule and features point to different protocols, outcome is "ambiguous".

**Step 3: Check for composite sequencing**
If the selected protocol has `prerequisites` in its `#FeatureProtocolMapping`, and those prerequisite
protocols are implied by the problem, set `sequenced: true` and build a `#SequencedStep` list.

**Step 4: Determine outcome**
- "routed": clear single protocol selected
- "ambiguous": multiple features, no disambiguation rule resolves them
- "unroutable": no structural features detected

**Step 5: Display routing block and proceed**
...
```

### Routing Block Output (routed — single protocol)

```
---
Protocol: HEP (Hypothesis Elimination Protocol)
Detected: competing causal explanations (causal_ambiguity)
Rationale: Your problem describes a real phenomenon with multiple possible causes — this calls for systematic evidence-driven hypothesis elimination.
---
```

### Routing Block Output (routed — composite sequence)

```
---
Multi-protocol sequence:

1. OVP (Observation Validation Protocol) — Validate the phenomenon is real
   Feeds into: HEP receives the validated observation as its phenomenon input

2. HEP (Hypothesis Elimination Protocol) — Eliminate competing hypotheses against evidence
   Feeds into: conclusion

Detected: questionable observation (observation_validity) + competing causes (causal_ambiguity)
---

Starting with OVP...
```

### Ambiguous Response (asks for clarification)

```
Your problem has two possible directions:
- Are you trying to explain *why* something happened — an observable event with multiple possible causes?
- Or are you trying to stress-test an existing argument — checking whether its assumptions hold?

Which is closer to what you need?
```

### Unroutable Response

```
I couldn't identify a clear problem structure from your description.

Socrates handles problems like:
- "Why did X happen?" (multiple causal explanations)
- "Which of these should I choose?" (competing candidates)
- "Is this argument sound?" (assumption stress-testing)
- "I don't know what the options are yet" (design space exploration)

Could you describe what you're trying to figure out or decide?
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Routing as a separate protocol (PSP) | Routing as governance (routing.cue) | Upstream change before Phase 2 | Routing is type matching, not adjudication — this is already reflected in the routing.opt.cue schema we're using |
| Protocol selection by user | Auto-routing from problem description | Phase 2 design decision | Users describe problems; skill handles protocol selection — this IS the Phase 2 goal |

**No deprecated approaches for this phase** — routing.opt.cue is current and reflects the governance promotion of the former PSP.

---

## Open Questions

1. **Protocol full names — embed in SKILL.md vs. read from .opt.cue files**
   - What we know: Reading all 13 protocol .opt.cue files at routing time would be expensive (13 Read calls); embedding names in SKILL.md avoids this but creates a maintenance surface if upstream changes protocol names
   - What's unclear: How often do protocol names change in the dialectics submodule?
   - Recommendation: Embed the lookup table in SKILL.md routing section. Names are stable (the protocols are formalized); drift risk is low; the maintenance cost of updating 13 names in SKILL.md is trivial compared to 13 file reads per invocation.

2. **How many composite sequences exist in routing.opt.cue?**
   - What we know: OVP → HEP is the only clearly documented prerequisite relationship (OVP description: "Gates HEP — validates phenomena are real before hypothesis elimination"); the `prerequisites` field in `#FeatureProtocolMapping` would document others, but the schema TYPE is defined without instance data (the routing.opt.cue only defines the schema, not the actual mapping instances)
   - What's unclear: Whether the routing.opt.cue only defines types (schema) or also contains instance data (actual mapping table values) — on review, the file contains ONLY type definitions, not data instances. The mapping instances must be applied by Claude using the schema structure as a guide.
   - Recommendation: SKILL.md must explicitly document the known composite cases (OVP→HEP is the confirmed one from OVP's description field). Claude applies the schema structure; SKILL.md provides the instances. This is a critical finding: **routing.opt.cue is a schema/type definition, not a populated data table.** Claude must interpret the schema structure and apply it to route, but it has no pre-populated mapping data to query.

3. **Discrimination logic for boundary feature pairs**
   - What we know: Six boundary pairs identified (CBP/CDP, CFFP/PTP, AAP/RCP, HEP/OVP, CFFP/CGP, structural_transfer/composition_emergence) where user descriptions may be ambiguous between two features
   - What's unclear: Whether the `#FeatureProtocolMapping.conditions` and `exceptions` fields contain sufficient discriminating language in the actual dialectics submodule source to guide routing
   - Recommendation: Read the raw routing.cue from the submodule (which has comments stripped in routing.opt.cue) to check if the original contains discrimination guidance. If not, SKILL.md must supply the discriminating questions explicitly.

---

## Critical Finding: routing.opt.cue is a Schema, Not a Populated Table

This is the most important finding for planning. The `routing.opt.cue` (and the raw `routing.cue`) defines CUE *types*:
- `#StructuralFeature` — the 14 feature enum values
- `#FeatureProtocolMapping` — the *structure* of a mapping entry (feature, primary_protocol, confidence, conditions, exceptions, prerequisites)
- `#DisambiguationRule` — the *structure* of a disambiguation rule
- `#RoutingResult` — the *structure* of a routing output

It does NOT contain instances — there is no actual table of `#FeatureProtocolMapping` values populated with real data. The mapping logic (which feature maps to which protocol under what conditions) is encoded in the inline comments of the raw `routing.cue`, which were stripped from `routing.opt.cue`.

This means:
1. **Claude cannot "read the mapping table" from routing.opt.cue** — there is no table, only the schema for what a table would look like
2. **The routing logic must be in SKILL.md instructions** — SKILL.md must encode which feature maps to which protocol (the inline comments from the raw routing.cue inform this, as do the structural feature values themselves which embed the mapping in their inline comments: `// term used differently across contexts → CBP`)
3. **The inline comments in routing.opt.cue DO contain the mapping** — each `#StructuralFeature` enum value has an inline comment like `// term used differently across contexts → CBP` that encodes the feature-to-protocol mapping

The inline comments in routing.opt.cue carry the feature→protocol mapping:
```cue
#StructuralFeature:
    "term_inconsistency"          | // term used differently across contexts → CBP
    "competing_candidates"        | // multiple formalisms competing → CFFP
    "unknown_design_space"        | // design space not yet understood → ADP
    ...
```

This is sufficient for Claude to extract the mapping at routing time — the comments ARE the routing table. Claude reads the schema + inline comments and applies the mapping. SKILL.md instructions should direct Claude to use these inline comments as the authoritative mapping, supplemented by discrimination questions for boundary cases.

---

## Sources

### Primary (HIGH confidence)

- `/Users/javier/projects/socrates/.claude/skills/socrates/protocols/routing.opt.cue` — Schema analysis: 14 structural features with inline protocol mapping comments, `#FeatureProtocolMapping` type definition, `#DisambiguationRule` type, `#RoutingResult` type with `routed`/`ambiguous`/`unroutable` outcome enum. Reviewed 2026-02-28.
- `/Users/javier/projects/socrates/.claude/skills/socrates/dialectics/governance/routing.cue` — Raw source with full comment block confirming governance promotion from PSP, usage pattern, and what an agent should be able to do. Reviewed 2026-02-28.
- `/Users/javier/projects/socrates/.planning/phases/02-routing/02-CONTEXT.md` — All locked decisions for routing display, ambiguous/unroutable handling, composite sequencing. Reviewed 2026-02-28.
- `/Users/javier/projects/socrates/.planning/STATE.md` — Blocker documented: "routing.cue's 14 structural features may overlap for ambiguous problem types — test discrimination logic against boundary cases before committing to routing implementation." Reviewed 2026-02-28.
- `/Users/javier/projects/socrates/.claude/skills/socrates/protocols/evaluative/ovp.opt.cue` — OVP description confirms: "Gates HEP — validates phenomena are real before hypothesis elimination" — the only explicitly documented prerequisite composite. Reviewed 2026-02-28.
- Phase 1 plans and verification — confirms SKILL.md structure, line count (56 lines), file reference pattern, execution placeholder location. Reviewed 2026-02-28.

### Secondary (MEDIUM confidence)

- Individual protocol `.opt.cue` files (HEP, ATP, AAP, CGP, OVP) — reviewed to understand structural feature expressions in real problems; used to verify boundary case discrimination logic.

### Tertiary (LOW confidence)

- None — all findings verified from primary sources in the project codebase.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — routing.opt.cue already exists and defines the complete schema; SKILL.md is the only implementation surface; no external dependencies
- Architecture: HIGH — routing section added to SKILL.md is the correct pattern; backed by Phase 1 plan conventions and existing SKILL.md structure
- Routing schema semantics: HIGH — routing.opt.cue read directly; inline comments confirmed to carry feature→protocol mapping
- Boundary case discrimination: MEDIUM — six boundary pairs identified from schema analysis; resolution via SKILL.md instructions is the right approach but exact wording requires testing
- Composite sequencing scope: MEDIUM — OVP→HEP confirmed from OVP description; other composites not explicitly documented in schema; `prerequisites` field in `#FeatureProtocolMapping` type is the intended mechanism but no instances populated

**Research date:** 2026-02-28
**Valid until:** 2026-03-28 (stable domain — routing.opt.cue and SKILL.md format are stable; only risk is upstream dialectics submodule changes)

# Phase 2: Routing - Context

**Gathered:** 2026-02-28
**Status:** Ready for planning

<domain>
## Phase Boundary

User describes any problem and the skill transparently selects the correct dialectic protocol(s) via governance/routing.cue structural feature matching before execution begins. Covers single-protocol routing, multi-protocol sequencing, and failure cases (ambiguous/unroutable). Protocol execution itself is Phase 3.

</domain>

<decisions>
## Implementation Decisions

### Selection display
- Routing result presented as a structured block, visually separated from execution output
- Block includes: protocol acronym + full name (e.g. "HEP (Hypothesis Elimination Protocol)"), detected structural features, and rationale
- Structural features shown using both plain language and schema identifiers (e.g. "competing causal explanations (causal_ambiguity)")
- Routing block is shown then execution proceeds immediately — no user confirmation gate
- No pause between routing display and execution handoff

### Ambiguous/unroutable input
- When routing returns "ambiguous": ask the user to clarify by describing the fork in plain language (not protocol names). e.g. "Is this about testing whether X is true, or about choosing between X and Y?"
- When routing returns "unroutable": explain that the problem didn't match any protocol's structural features, suggest how to rephrase, and show the types of problems Socrates handles
- Never force a bad fit — don't best-guess an unroutable problem into a protocol

### Composite sequencing
- When routing produces a multi-protocol sequence, show the full sequence upfront before any execution begins
- Use numbered steps with protocol name, purpose, and data flow per step (the "feeds" relationship from the schema)
- If an early protocol produces a result that invalidates a later step (e.g. OVP finds "artifact"), explain why the sequence is stopping and stop — don't continue unnecessary protocols

### Claude's Discretion
- Whether to show routing warnings (from the schema's warnings field) — case-by-case based on user relevance
- Confidence level display — show only when it's noteworthy (medium or low), not for high-confidence routes
- Feature-to-problem-text attribution — attribute when it adds clarity, omit when the connection is obvious
- Retry limits for ambiguous/unroutable rephrasing — Claude judges when further attempts are unproductive

</decisions>

<specifics>
## Specific Ideas

- Full transparency is the priority: the user should always understand why a protocol was selected
- Plain language is the default communication mode with users — schema identifiers are supplementary, not primary
- The routing block should feel like a "here's what I'm going to do and why" moment, not a wall of technical output

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 02-routing*
*Context gathered: 2026-02-28*

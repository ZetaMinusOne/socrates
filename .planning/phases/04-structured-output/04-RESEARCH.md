# Phase 4: Structured Output - Research

**Researched:** 2026-02-28
**Domain:** Claude-native structured JSON output — flag parsing from $ARGUMENTS, protocol output schema projection, recording.cue #Record projection, and alternative output rendering paths in SKILL.md
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Output rendering format:**
- Format is JSON, pretty-printed with indentation
- `--structured` output is pure JSON only — no prose wrapping, no routing block, no context bridge
- Top-level envelope with metadata: `{"protocol": "CFFP", "routed_via": "competing_candidates", "output": {...}}` — self-describing, includes protocol used and routing info alongside the protocol output

**Flag behavior and edge cases:**
- Gate failures in `--structured` mode return a structured error object: `{"outcome": "gate_failed", "gate": "...", "completed_phases": [...], "suggestions": [...]}`
- Composite sequences (e.g., OVP → HEP) produce a single combined JSON object: `{"sequence": [{"protocol": "OVP", "output": {...}}, {"protocol": "HEP", "output": {...}}]}`
- When both `--structured` and `--record` are passed together, return both in one response: `{"structured": {protocol output}, "record": {#Record}}`
- Flags are parsed from `$ARGUMENTS` text (e.g., user types `--structured why did X fail?`)

**Reasoning trace in structured output:**
- Full phase trace included — all phases appear as JSON objects, not just the terminal output type
- Challenge/rebuttal narrative text included as string description fields (verbose but complete audit trail)
- Revision loops include both passes: `[{"pass": 1, "outcome": "all_eliminated", ...}, {"pass": 2, "outcome": "survivors", ...}]`
- Evaluative protocols use the same full-phase pattern as adversarial for consistency — every phase is a JSON object in a phases array

**Record completeness:**
- `prior_runs` field defaults to empty array `[]` for standalone runs — exists for future cross-run reconciliation
- Tags are auto-generated only from protocol run data: protocol type, dispute kind, resolution status (e.g., `["adversarial", "cffp", "decided"]`)
- `next_actions` populated only when the protocol explicitly names a follow-up (CDP → CFFP instructions, RCP blocked → CBP needed) — no speculative suggestions

### Claude's Discretion

- ID generation strategy for `run_id` and `record_id` (deterministic hash vs UUID)
- Exact envelope field names and nesting structure
- How to handle `--structured` with ambiguous or unroutable routing outcomes
- Timestamp format and timezone handling in records

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| OUTP-02 | User can pass `--structured` flag to get typed results matching the protocol's CUE output schema instead of narrative | Flag parsing from $ARGUMENTS; protocol schema projection into JSON; output rendering branch in SKILL.md |
| OUTP-03 | User can pass `--record` flag to get output formatted as a #Record compatible with governance/recording.cue (queryable audit trail) | recording.cue #Record type field-by-field mapping; auto-generation rules for tags, next_actions, prior_runs |
</phase_requirements>

## Summary

Phase 4 adds two alternative output rendering paths to the existing `/socrates` execution pipeline. The core change is purely in SKILL.md: after protocol execution completes (or fails), Claude checks whether `--structured` or `--record` appeared in `$ARGUMENTS` and routes output accordingly. No new files are needed, no protocol schemas change, and the execution pipeline itself is unchanged — only the final rendering step branches.

The implementation domain is entirely within Claude's text generation capability. There is no runtime CUE evaluation, no JSON schema validation library, and no external tooling — just instructions telling Claude how to project a completed (or failed) protocol run into JSON structures derived from the CUE schemas already loaded. This is consistent with the project's core decision: Claude interprets CUE schemas directly with no toolchain dependency.

The two schemas that drive this phase are: (1) the protocol-specific instance type (e.g., `#CFFPInstance`, `#HEPInstance`, `#AAPInstance`) which defines the full typed output for `--structured`, and (2) `governance/recording.cue`'s `#Record` type which defines the uniform projection for `--record`. Both schemas are already readable by Claude via the Read tool. The primary challenge is not technical but instructional: writing SKILL.md instructions precise enough that Claude produces valid, well-typed JSON that mirrors the schema without prose contamination.

**Primary recommendation:** Implement Phase 4 as a single plan that adds a "Flag Handling" section to SKILL.md, inserting it between Input parsing and Routing. The section instructs Claude to parse flags from $ARGUMENTS, strip them from the problem text, execute normally, then apply the appropriate output renderer — bypassing narrative mode entirely when flags are present.

## Standard Stack

### Core

| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| SKILL.md | (existing) | Agent instruction file — only artifact modified | All skill behavior defined here; no external libraries |
| protocols/{protocol}.opt.cue | (existing) | Source of `#ProtocolInstance` type definitions for `--structured` projection | Already loaded during execution; contains the typed output schemas |
| governance/recording.cue | (existing, raw) | Source of `#Record` type for `--record` projection | The authoritative recording schema in the submodule |

### Supporting

| Component | Version | Purpose | When to Use |
|-----------|---------|---------|-------------|
| protocols/dialectics.opt.cue | (existing) | Kernel primitives (#Run, #KnownProtocol) | Used to populate source_run.protocol and run_id fields in #Record |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Claude-native JSON generation | cue eval / jq | CUE runtime adds toolchain dependency; out of scope per REQUIREMENTS.md |
| Inline schema reproduction in SKILL.md | Read tool for schemas at render time | Inline would bloat SKILL.md; Read is already the established pattern |

**Installation:** None required. No new packages or dependencies.

## Architecture Patterns

### Recommended Project Structure

```
.claude/skills/socrates/
├── SKILL.md                  # Modified: adds ## Flag Handling section, ## Output Rendering section
├── protocols/
│   ├── dialectics.opt.cue    # Unchanged — kernel types
│   ├── routing.opt.cue       # Unchanged — routing logic
│   ├── adversarial/*.opt.cue # Unchanged — source for --structured projection
│   ├── evaluative/*.opt.cue  # Unchanged — source for --structured projection
│   └── exploratory/*.opt.cue # Unchanged — source for --structured projection
└── dialectics/
    └── governance/
        └── recording.cue     # Read by Claude when --record flag detected
```

No new files. One file modified: SKILL.md.

### Pattern 1: Flag Parsing Before Routing

**What:** Extract flags from $ARGUMENTS before routing proceeds. Strip flags from the problem text so routing sees only the problem description.
**When to use:** At the Input step, before routing is invoked.

```
## Flag Handling

Before routing, scan $ARGUMENTS for recognized flags:
- `--structured`: structured output mode
- `--record`: record output mode
- Both flags may appear together

Strip flags from $ARGUMENTS before passing the remainder to routing.
Store which flags were detected — they determine output rendering after execution.

If $ARGUMENTS is ONLY flags (no problem text remains after stripping):
Respond: "Please describe a problem for me to analyze."
Stop.
```

**Why early:** Routing and execution are unchanged. The flag affects only post-execution rendering. Detecting early and stripping keeps routing and execution instructions unmodified.

### Pattern 2: Deferred Rendering Branch

**What:** Normal execution proceeds identically regardless of flags. After execution completes (or gate-fails), rendering branches based on detected flags.
**When to use:** At the end of the Execution section, as a post-execution rendering step.

```
## Output Rendering

After execution completes:

If no flags detected → render narrative prose (default, existing behavior).

If --structured detected → render JSON structured output (see below).
If --record detected → render #Record JSON output (see below).
If both detected → render combined JSON: {"structured": {...}, "record": {...}}.
```

**Why deferred:** Execution logic is complex and already correct. Branching at the output stage means zero impact on the 250-line execution section already written in Phase 3.

### Pattern 3: Protocol Instance Schema Projection

**What:** For `--structured`, Claude projects the completed protocol run into the protocol's typed instance schema as JSON.
**When to use:** After execution, when `--structured` flag is detected.

The key insight: every protocol `.opt.cue` file already defines a top-level instance type (`#CFFPInstance`, `#HEPInstance`, `#AAPInstance`, etc.) that is the complete typed output for that run. Claude has already loaded this schema. The structured output is a JSON realization of this type.

Example envelope pattern (from locked decisions):
```json
{
  "protocol": "CFFP",
  "routed_via": "competing_candidates",
  "output": {
    "protocol": {"name": "...", "version": "0.2.1"},
    "construct": {"name": "...", "description": "..."},
    "version": "1.0",
    "phase1": {
      "invariants": [
        {"id": "I1", "description": "...", "testable": true, "structural": true, "class": "termination"}
      ]
    },
    "phase2": {"candidates": [...]},
    "phase3": {"counterexamples": [...], "composition_failures": [...]},
    "derived": {"eliminated": [...], "survivors": [...]},
    "phase5": {"obligations": [...], "all_provable": true},
    "phase6": {"canonical": {"construct": "...", "formal_statement": "...", ...}},
    "outcome": "canonical",
    "outcome_notes": "..."
  }
}
```

### Pattern 4: Gate Failure as Structured Error

**What:** When a gate fails in `--structured` mode, the error itself is structured JSON.
**When to use:** Any point where execution would hard-stop in narrative mode.

```json
{
  "outcome": "gate_failed",
  "gate": "Phase 1 — invariants: at least one invariant required",
  "completed_phases": ["routing"],
  "suggestions": [
    "Describe a construct with at least one verifiable behavioral constraint",
    "Rephrase the problem to make the invariants explicit"
  ]
}
```

**Why:** Programmatic consumers get actionable error data, not prose. The shape mirrors what a Phase 5 gate failure would report but generalized to any gate.

### Pattern 5: #Record Projection

**What:** For `--record`, Claude reads `governance/recording.cue` and projects the completed run into a `#Record`.
**When to use:** After execution, when `--record` flag is detected.

The `#Record` type requires these fields (from recording.cue):
- `record_id`: string — generated ID for this record
- `source_run`: `#SourceRun` — protocol, run_id, run_version, subject, started, completed (ISO 8601)
- `dispute`: `#DisputeCharacterization` — kind (maps to routing structural feature), description, prior_runs (default `[]`)
- `resolution`: `#ResolutionSummary` — status (decided/open/rejected), decision?, open_questions?, eliminated_count, survivors
- `acknowledged_limitations`: `[...#AcknowledgedLimitation]` — from scope_narrowing rebuttals
- `dependencies`: `#Dependencies` — consumed (prior run IDs), produced (artifacts)
- `tags`: `[...string]` — auto-generated from protocol type, dispute kind, resolution status
- `next_actions`: `[...#NextAction]` — only when protocol explicitly names follow-up
- `notes`: string (default `""`)

Dispute kind mapping (structural feature → #DisputeKind):
| Structural Feature | #DisputeKind |
|--------------------|--------------|
| competing_candidates | candidate_selection |
| term_inconsistency | term_ambiguity |
| argument_fragility | assumption_audit |
| unknown_design_space | design_mapping |
| construct_incoherence | construct_repair |
| implementation_gap | implementation_check |
| revision_pressure / deprecation_pressure | governance_case |
| cross_run_conflict | cross_run_conflict |
| structural_transfer | analogy_transfer |
| composition_emergence | composition_emergence |
| observation_validity | observation_validity |
| resource_constrained_choice | prioritization |
| causal_ambiguity | (no direct match — use "candidate_selection" with a note, since HEP is the causal protocol) |

### Pattern 6: ID Generation Strategy

**What:** Generate `run_id` and `record_id` as pseudo-unique strings without external tooling.
**When to use:** When populating `#SourceRun.run_id` and `#Record.record_id`.

Options (Claude's discretion per CONTEXT.md):
1. **Deterministic from content:** Combine protocol acronym + timestamp fragment + subject hash-like prefix. E.g., `"cffp-20260228-a7f3"`. Readable, not guaranteed unique but sufficient for audit purposes.
2. **UUID-style:** Generate a v4-style UUID string. More unique, less readable. Claude can generate plausible UUID strings without a library.

Recommendation: Use deterministic format `{protocol_lower}-{YYYYMMDD}-{4-char-hex-like}` for readability and traceability. The `record_id` should differ from `run_id` by prefixing `rec-`: `"rec-cffp-20260228-a7f3"`.

### Pattern 7: Composite Sequence Structured Output

**What:** OVP → HEP composite produces a sequence array, not a single protocol object.
**When to use:** When routing produces a composite sequence and `--structured` is detected.

```json
{
  "sequence": [
    {
      "protocol": "OVP",
      "routed_via": "observation_validity",
      "output": { ... OVP instance ... }
    },
    {
      "protocol": "HEP",
      "routed_via": "causal_ambiguity",
      "output": { ... HEP instance ... }
    }
  ]
}
```

Early termination in composite (e.g., OVP returns `artifact`):
```json
{
  "sequence": [
    {
      "protocol": "OVP",
      "routed_via": "observation_validity",
      "output": { ... OVP instance with outcome: "artifact" ... }
    }
  ],
  "early_termination": {
    "reason": "OVP verdict is artifact — HEP would operate on a false premise",
    "stopped_at": "OVP",
    "next_step": "Investigate what the artifact actually reflects"
  }
}
```

### Anti-Patterns to Avoid

- **Mixing prose into JSON:** The locked decision is "pure JSON only — no prose wrapping." If Claude adds any explanatory text outside the JSON block, the output is invalid for programmatic consumption.
- **Partial projection:** Omitting phases from the `output` object because they're "not the interesting part" breaks the full-trace requirement. All executed phases must appear as JSON objects.
- **Re-running execution for structured output:** The structured output is a projection of what was already computed during narrative execution. Don't re-execute the protocol. Execute once, render differently.
- **Reading recording.cue eagerly:** recording.cue should only be read when `--record` flag is detected. Loading it unconditionally wastes context on every invocation.
- **Speculative next_actions:** The locked decision is next_actions populated only when the protocol explicitly names a follow-up. Don't add generic suggestions.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| JSON schema validation | Custom type-checking logic in SKILL.md | Claude projects from loaded .opt.cue schema directly | Schema is already loaded; Claude's projection is the validation |
| ID generation | External UUID library | Deterministic string pattern in SKILL.md instructions | No toolchain allowed; deterministic format is sufficient for audit IDs |
| Timestamp generation | System clock call | ISO 8601 string from Claude's knowledge of current date/time | Claude knows the current date; "2026-02-28T00:00:00Z" placeholder is acceptable |
| Dispute kind lookup | Separate lookup file | Inline mapping table in SKILL.md Flag Handling section | 12-row table; inline is clearer and faster than a file read |

**Key insight:** This entire phase is projection, not computation. Claude reads a schema it already has loaded, and writes JSON that conforms to it. The "implementation" is SKILL.md instructions telling Claude how to do the projection faithfully.

## Common Pitfalls

### Pitfall 1: Prose Contamination in JSON Output

**What goes wrong:** Claude adds a preamble like "Here is the structured output:" before the JSON block, or adds trailing explanation.
**Why it happens:** Claude's default behavior is to contextualize output. SKILL.md must explicitly say "no prose before or after the JSON block."
**How to avoid:** SKILL.md instruction: "Output ONLY the JSON object. No preamble, no trailing explanation, no markdown code fences wrapping context." Use a code fence (```json ... ```) only as a formatting wrapper, not as justification for adding text outside it.
**Warning signs:** Any text between closing ``` and end of response.

### Pitfall 2: Omitting Phases from Structured Output

**What goes wrong:** Claude outputs only `phase6` (the "interesting" result) and skips phases 1-5 in the `output` object.
**Why it happens:** Optimizing for brevity is Claude's default. The locked decision requires full phase trace.
**How to avoid:** SKILL.md instruction must explicitly state: "The `output` field contains all executed phases as JSON objects. Phase 3b appears if triggered. Phase 4 appears if survivors > 1. All phases that were executed appear in the output."
**Warning signs:** A structured output response that's short (< 50 lines) for a multi-phase adversarial protocol.

### Pitfall 3: Incorrect Dispute Kind Mapping

**What goes wrong:** Claude maps `causal_ambiguity` (HEP's structural feature) to a nonexistent `#DisputeKind` value, or uses a wrong kind entirely.
**Why it happens:** `causal_ambiguity` has no exact match in `#DisputeKind`. The recording.cue enum doesn't include it.
**How to avoid:** SKILL.md provides the explicit mapping table. For HEP-routed problems, use `"candidate_selection"` (since HEP is the protocol for selecting among causal candidates) and add a note in the `dispute.description` field clarifying it's causal hypothesis elimination.
**Warning signs:** `#Record` dispute.kind value not matching the enum in recording.cue.

### Pitfall 4: Reading recording.cue on Every Invocation

**What goes wrong:** SKILL.md instructs Claude to always read recording.cue as part of the execution preamble.
**Why it happens:** Overly defensive "read all governance files" approach.
**How to avoid:** SKILL.md flag handling section: "Read `dialectics/governance/recording.cue` only when `--record` flag is detected." This is the progressive disclosure pattern established in Phase 1.
**Warning signs:** recording.cue in every session's Read tool calls regardless of flags used.

### Pitfall 5: Ambiguous/Unroutable Routing with Structured Flag

**What goes wrong:** User passes `--structured but problem is unroutable. Claude doesn't know what protocol schema to project into.
**Why it happens:** The routing outcome determines which schema to use. Unroutable = no schema selection = nowhere to project.
**How to avoid:** SKILL.md handles this in the "ambiguous/unroutable routing" handlers. When `--structured` is active and routing returns `ambiguous`, ask the clarifying question in plain text (no JSON — structured output can't be produced without a known protocol). When routing returns `unroutable`, return a structured error: `{"outcome": "unroutable", "message": "..."}`. Per Claude's Discretion in CONTEXT.md, this handling is researcher-recommended.
**Warning signs:** Empty JSON output or Claude asking routing questions in JSON format.

### Pitfall 6: Timestamp Placeholder vs. Actual Time

**What goes wrong:** `#SourceRun.started` and `completed` fields are left as `""` or `"TIMESTAMP"` placeholders.
**Why it happens:** Claude doesn't have precise real-time clock access.
**How to avoid:** SKILL.md instruction: "For timestamps, use the current date in ISO 8601 format. Use today's date (2026-02-28) as the date portion. Use `T00:00:00Z` as the time portion unless a more precise time is available from context. `started` and `completed` may use the same timestamp — the distinction is for future tooling." This is pragmatic for an audit trail used by Claude Code users.
**Warning signs:** Empty timestamp fields in #Record output.

## Code Examples

Verified patterns from schema analysis:

### --structured Output: Full Envelope (CFFP Example)

```json
{
  "protocol": "CFFP",
  "routed_via": "competing_candidates",
  "output": {
    "protocol": {
      "name": "Constraint-First Formalization Protocol",
      "version": "0.2.1",
      "description": "Invariant-driven semantic design. Candidates survive pressure or die."
    },
    "construct": {
      "name": "...",
      "description": "...",
      "depends_on": []
    },
    "version": "1.0",
    "phase1": {
      "invariants": [
        {
          "id": "I1",
          "description": "...",
          "testable": true,
          "structural": true,
          "class": "termination"
        }
      ]
    },
    "phase2": {
      "candidates": [
        {
          "id": "C1",
          "description": "...",
          "formalism": {
            "structure": "...",
            "evaluation_rule": "...",
            "resolution_rule": "..."
          },
          "claims": [{"invariant_id": "I1", "argument": "..."}],
          "complexity": {"time": "O(n)", "space": "O(1)", "static": "linear"},
          "failure_modes": []
        }
      ]
    },
    "phase3": {
      "counterexamples": [],
      "composition_failures": []
    },
    "derived": {
      "eliminated": [],
      "survivors": [{"candidate_id": "C1", "scope_narrowings": []}]
    },
    "phase5": {
      "obligations": [
        {"property": "...", "argument": "...", "provable": true}
      ],
      "all_provable": true
    },
    "phase6": {
      "canonical": {
        "construct": "...",
        "formal_statement": "...",
        "evaluation_def": "...",
        "satisfies": ["I1"],
        "acknowledged_limitations": []
      }
    },
    "outcome": "canonical",
    "outcome_notes": "..."
  }
}
```

### --record Output: Full #Record

```json
{
  "record_id": "rec-cffp-20260228-a7f3",
  "source_run": {
    "protocol": "CFFP",
    "run_id": "cffp-20260228-a7f3",
    "run_version": "0.2.1",
    "subject": "...",
    "started": "2026-02-28T00:00:00Z",
    "completed": "2026-02-28T00:00:00Z"
  },
  "dispute": {
    "kind": "candidate_selection",
    "description": "...",
    "prior_runs": []
  },
  "resolution": {
    "status": "decided",
    "decision": "...",
    "eliminated_count": 1,
    "survivors": ["C1"]
  },
  "acknowledged_limitations": [],
  "dependencies": {
    "consumed": [],
    "produced": []
  },
  "tags": ["adversarial", "cffp", "decided"],
  "next_actions": [],
  "notes": ""
}
```

### --structured + --record Combined Response

```json
{
  "structured": {
    "protocol": "CFFP",
    "routed_via": "competing_candidates",
    "output": { ... full protocol instance ... }
  },
  "record": {
    "record_id": "rec-cffp-20260228-a7f3",
    ... full #Record ...
  }
}
```

### Gate Failure in Structured Mode

```json
{
  "outcome": "gate_failed",
  "gate": "Phase 1 — invariants: at least one invariant required ([_, ...] constraint)",
  "completed_phases": ["routing"],
  "suggestions": [
    "Describe a construct with at least one verifiable behavioral constraint",
    "Rephrase the problem to identify what property must always hold"
  ]
}
```

### Revision Loop in Structured Output

```json
"phase3b": {
  "triggered": true,
  "passes": [
    {
      "pass": 1,
      "outcome": "all_eliminated",
      "diagnosis": "invariants_too_strong",
      "resolution": "revise_invariants",
      "notes": "All 2 candidates eliminated by I2 (decidability invariant too strict)"
    },
    {
      "pass": 2,
      "outcome": "survivors",
      "survivors": ["C2"],
      "notes": "Revised I2 to allow partial decidability; C2 now survives"
    }
  ]
}
```

### Composite Sequence with Early Termination

```json
{
  "sequence": [
    {
      "protocol": "OVP",
      "routed_via": "observation_validity",
      "output": {
        ...
        "outcome": "artifact",
        "outcome_notes": "The reported latency spike is a measurement artifact from clock skew"
      }
    }
  ],
  "early_termination": {
    "reason": "OVP verdict is 'artifact' — the observation is not a real phenomenon, so HEP would operate on a false premise",
    "stopped_at": "OVP",
    "suggested_next": "Investigate what genuine phenomenon the artifact might reflect"
  }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Separate output file generation | SKILL.md instruction-only, Claude projects inline | Phase 4 (this phase) | No file artifacts created; output appears directly in Claude's response |
| Runtime CUE validation | Claude interprets schemas; no cue eval | Project-wide decision (Phase 1) | Zero toolchain dependency |
| Narrative-only output | Narrative default + flag-gated structured/record modes | Phase 4 (this phase) | Power users get machine-readable output without disrupting normal users |

**Deprecated/outdated:**
- None applicable — this is a new capability with no legacy to replace.

## Implementation Plan Recommendation

Phase 4 should be **one plan** modifying SKILL.md in two focused sections:

**Plan 04-01:** Add two new sections to SKILL.md:

1. **`## Flag Handling`** (insert after `## Input`, before `## Protocol Files`):
   - Scan $ARGUMENTS for `--structured` and/or `--record`
   - Strip flags from $ARGUMENTS before routing sees the problem
   - Store detected flags
   - Handle empty-after-strip case

2. **`## Output Rendering`** (insert after `## Execution`, as the final section):
   - If no flags: existing narrative behavior (no change needed — just document the branch)
   - If `--structured`: render envelope JSON from protocol instance schema
   - If `--record`: read recording.cue, project into #Record, render JSON
   - If both: render combined JSON object
   - Ambiguous/unroutable cases with flags: specific handlers
   - Sub-section: gate failure format
   - Sub-section: revision loop representation
   - Sub-section: composite sequence format
   - Sub-section: ID generation pattern
   - Sub-section: timestamp convention

**Line budget for new sections:** ~60-80 lines total. SKILL.md currently ~250 lines; target ~310-330 after Phase 4.

## Open Questions

1. **Ambiguous routing with `--structured` flag**
   - What we know: Routing can return `ambiguous`, requiring a clarifying question
   - What's unclear: Should the clarifying question itself be in JSON, or is plain-text acceptable since no protocol is selected yet?
   - Recommendation: Plain text clarification. Structured output requires a selected protocol; asking "which direction?" in JSON would be meaningless to both humans and machines. After clarification and re-routing, apply `--structured` to the now-routed result. Add explicit instruction in SKILL.md.

2. **Timestamp precision**
   - What we know: Claude knows today's date (2026-02-28); doesn't have real-time clock
   - What's unclear: Whether `T00:00:00Z` placeholder is acceptable, or if the record should note imprecision
   - Recommendation: Use `2026-02-28T00:00:00Z` for both `started` and `completed`. Add a `notes` field entry: "Timestamps represent execution date; precise wall-clock time unavailable in Claude Code context." This is honest and doesn't break the schema (notes: string with a default of "").

3. **HEP dispute kind mapping gap**
   - What we know: `causal_ambiguity` structural feature has no exact `#DisputeKind` equivalent in recording.cue
   - What's unclear: Whether to use `candidate_selection` (closest semantic match) or treat this as a schema gap
   - Recommendation: Map to `"candidate_selection"` with an explanatory `dispute.description`. Recording.cue v0.1.0 predates this awareness; the mapping is a pragmatic projection, not a schema bug.

## Sources

### Primary (HIGH confidence)

- `/Users/javier/projects/socrates/.claude/skills/socrates/dialectics/governance/recording.cue` — Full #Record type, all required fields, #DisputeKind enum, #ResolutionStatus enum, #SourceProtocol enum
- `/Users/javier/projects/socrates/.claude/skills/socrates/protocols/adversarial/cffp.opt.cue` — #CFFPInstance type, all phase types, #Outcome enum
- `/Users/javier/projects/socrates/.claude/skills/socrates/protocols/adversarial/hep.opt.cue` — #HEPInstance type, #Phase3b with revision_count, #Phase4 branching
- `/Users/javier/projects/socrates/.claude/skills/socrates/protocols/evaluative/aap.opt.cue` — #AAPInstance type (6-phase evaluative pattern)
- `/Users/javier/projects/socrates/.claude/skills/socrates/protocols/evaluative/ovp.opt.cue` — #OVPInstance type, #ValidatedObservation (composite handoff source)
- `/Users/javier/projects/socrates/.claude/skills/socrates/protocols/dialectics.opt.cue` — #Run type, #KnownProtocol enum
- `/Users/javier/projects/socrates/.claude/skills/socrates/protocols/routing.opt.cue` — #StructuralFeature enum (for dispute kind mapping)
- `/Users/javier/projects/socrates/.claude/skills/socrates/SKILL.md` — Current SKILL.md structure, existing sections, line count baseline
- `.planning/phases/04-structured-output/04-CONTEXT.md` — All locked decisions and discretion areas

### Secondary (MEDIUM confidence)

- `.planning/phases/03-protocol-execution/03-01-PLAN.md` — Plan structure template for Phase 4 plan authoring
- `.planning/REQUIREMENTS.md` — OUTP-02, OUTP-03 requirement text
- `.planning/STATE.md` — Accumulated project decisions relevant to Phase 4

### Tertiary (LOW confidence)

- None. All findings derive from direct schema inspection and locked decisions.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new dependencies; all components already exist in the project
- Architecture patterns: HIGH — derived directly from locked decisions in CONTEXT.md and schema field inspection
- Pitfalls: HIGH — derived from schema structure analysis and Claude behavior patterns established in prior phases
- ID generation / timestamp: MEDIUM — Claude's discretion area; recommendations are pragmatic but not validated against a runtime

**Research date:** 2026-02-28
**Valid until:** 2026-03-30 (stable — no external dependencies, no ecosystem changes can affect this)

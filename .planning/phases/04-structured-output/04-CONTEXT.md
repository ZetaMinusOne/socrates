# Phase 4: Structured Output - Context

**Gathered:** 2026-02-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Add `--structured` and `--record` flags to the `/socrates` skill so power users can get typed, CUE-schema-compliant JSON output instead of narrative prose. The narrative output mode (default, no flags) is unchanged. This phase does not add new protocols, routing logic, or execution behavior — it adds an alternative output rendering path for the existing execution pipeline.

</domain>

<decisions>
## Implementation Decisions

### Output rendering format
- Format is JSON, pretty-printed with indentation
- `--structured` output is pure JSON only — no prose wrapping, no routing block, no context bridge
- Top-level envelope with metadata: `{"protocol": "CFFP", "routed_via": "competing_candidates", "output": {...}}` — self-describing, includes protocol used and routing info alongside the protocol output

### Flag behavior & edge cases
- Gate failures in `--structured` mode return a structured error object: `{"outcome": "gate_failed", "gate": "...", "completed_phases": [...], "suggestions": [...]}`
- Composite sequences (e.g., OVP → HEP) produce a single combined JSON object: `{"sequence": [{"protocol": "OVP", "output": {...}}, {"protocol": "HEP", "output": {...}}]}`
- When both `--structured` and `--record` are passed together, return both in one response: `{"structured": {protocol output}, "record": {#Record}}`
- Flags are parsed from `$ARGUMENTS` text (e.g., user types `--structured why did X fail?`)

### Reasoning trace in structured output
- Full phase trace included — all phases appear as JSON objects, not just the terminal output type
- Challenge/rebuttal narrative text included as string description fields (verbose but complete audit trail)
- Revision loops include both passes: `[{"pass": 1, "outcome": "all_eliminated", ...}, {"pass": 2, "outcome": "survivors", ...}]`
- Evaluative protocols use the same full-phase pattern as adversarial for consistency — every phase is a JSON object in a phases array

### Record completeness
- `prior_runs` field defaults to empty array `[]` for standalone runs — exists for future cross-run reconciliation
- Tags are auto-generated only from protocol run data: protocol type, dispute kind, resolution status (e.g., `["adversarial", "cffp", "decided"]`)
- `next_actions` populated only when the protocol explicitly names a follow-up (CDP → CFFP instructions, RCP blocked → CBP needed) — no speculative suggestions

### Claude's Discretion
- ID generation strategy for `run_id` and `record_id` (deterministic hash vs UUID)
- Exact envelope field names and nesting structure
- How to handle `--structured` with ambiguous or unroutable routing outcomes
- Timestamp format and timezone handling in records

</decisions>

<specifics>
## Specific Ideas

- The envelope pattern `{"protocol": "...", "routed_via": "...", "output": {...}}` keeps structured output self-describing — consumers don't need external context to interpret the JSON
- Gate failures as structured objects means programmatic consumers get actionable error data, not just a prose explanation
- Full phase traces with narrative text in string fields means the structured output serves as both a machine-readable and human-reviewable artifact

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 04-structured-output*
*Context gathered: 2026-02-28*

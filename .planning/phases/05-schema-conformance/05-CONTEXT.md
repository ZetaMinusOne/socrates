# Phase 5: Schema Conformance Alignment - Context

**Gathered:** 2026-02-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Fix SKILL.md instructions to exactly match CUE schema definitions. The v1.0 audit identified 4 specific schema-instruction mismatches affecting `--structured` and `--record` output correctness. This phase corrects those mismatches AND performs a full enum/type sweep to catch any others. Core narrative output (default mode) is unaffected by most fixes.

</domain>

<decisions>
## Implementation Decisions

### ADP version fallback
- Claude's discretion on how to handle the missing `#Protocol.version` for ADP's `--record` flow (omit field, use fallback value, or other approach)
- Claude's discretion on whether to make the fix ADP-specific or add a general fallback rule for protocols without version fields
- Claude's discretion on whether ADP gets a special exception section or inline exceptions within uniform instructions
- Claude's discretion on whether fallback values are marked/silent in the record output

### Instruction granularity
- Claude's discretion on whether to use per-protocol tables, inline conditionals, or another format for protocol-specific resolutions
- **Full enum sweep**: Do NOT limit to the 4 audit-identified issues — verify ALL enum values, labels, and type references in SKILL.md against their source schemas. Fix everything found.
- Claude's discretion on how to handle newly-discovered mismatches — judge by severity, fix critical ones, note minor ones
- Claude's discretion on whether to reorganize SKILL.md sections by protocol category — restructure only if needed for clarity

### AAP tier descriptions
- Claude's discretion on whether schema tier labels (structural, significant, moderate, minor) need added descriptions or are self-explanatory
- Claude's discretion on whether to reference all 4 schema tiers in execution instructions
- Claude's discretion on whether narrative output uses exact schema labels or natural language paraphrases (structured output must use exact labels)
- Claude's discretion on whether to check the full FragilityMap structure or just tier labels — part of the full sweep

### Type reference style
- Claude's discretion on how to reference per-protocol instance types (pattern instruction like `#{ACRONYM}Instance`, explicit table, or read-from-schema instruction)
- Claude's discretion on whether to explicitly call out ADP's `#ADPRecord` exception or let inference handle it
- Claude's discretion on whether structured output section references types directly or instructs schema file reading
- Consistent with full sweep: fix all type mismatches found, judging by severity

### Claude's Discretion
All four discussion areas were delegated to Claude's judgment. Key constraint: the full enum/type sweep must happen — don't limit fixes to just the 4 audit items. Beyond that, Claude has flexibility on instruction formatting, exception handling patterns, and SKILL.md organization.

</decisions>

<specifics>
## Specific Ideas

- Full sweep approach: while fixing the 4 known issues, systematically verify every enum, label, and type reference in SKILL.md against the source .opt.cue files
- The 4 audit-identified issues are the known floor, not the ceiling — fix anything else the sweep catches
- Narrative output can be more natural; structured output must use exact schema values

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 05-schema-conformance*
*Context gathered: 2026-02-28*

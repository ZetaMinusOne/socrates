# Phase 5: Schema Conformance Alignment - Research

**Researched:** 2026-02-28
**Domain:** CUE schema definitions vs. SKILL.md instruction correctness
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

None — all four discussion areas were delegated to Claude's judgment. The one hard constraint is:

- **Full enum sweep:** Do NOT limit to the 4 audit-identified issues — verify ALL enum values, labels, and type references in SKILL.md against their source schemas. Fix everything found.

### Claude's Discretion

All four discussion areas were delegated to Claude's judgment:

**ADP version fallback:**
- How to handle the missing `#Protocol.version` for ADP's `--record` flow (omit field, use fallback value, or other approach)
- Whether to make the fix ADP-specific or add a general fallback rule for protocols without version fields
- Whether ADP gets a special exception section or inline exceptions within uniform instructions
- Whether fallback values are marked/silent in the record output

**Instruction granularity:**
- Whether to use per-protocol tables, inline conditionals, or another format for protocol-specific resolutions
- How to handle newly-discovered mismatches — judge by severity, fix critical ones, note minor ones
- Whether to reorganize SKILL.md sections by protocol category — restructure only if needed for clarity

**AAP tier descriptions:**
- Whether schema tier labels need added descriptions or are self-explanatory
- Whether to reference all 4 schema tiers in execution instructions
- Whether narrative output uses exact schema labels or natural language paraphrases (structured output must use exact labels)
- Whether to check the full FragilityMap structure or just tier labels (part of the full sweep)

**Type reference style:**
- How to reference per-protocol instance types (pattern instruction like `#{ACRONYM}Instance`, explicit table, or read-from-schema instruction)
- Whether to explicitly call out ADP's `#ADPRecord` exception or let inference handle it
- Whether structured output section references types directly or instructs schema file reading
- Fix all type mismatches found, judging by severity

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| EXEC-05 | When no candidates survive adversarial pressure, the revision loop (#RevisionLoop) triggers feedback rather than forcing a false conclusion | Fix 1 (CDP/ATP resolution enum) corrects the terminal path instruction so the revision loop skip uses correct resolution enum values per schema |
| OUTP-02 | User can pass `--structured` flag to get typed results matching the protocol's CUE output schema | Fix 1 (resolution enums), Fix 3 (AAP tier labels), Fix 4 (instance type names), Fix 5 (ADP instance type) all affect structured output correctness |
| OUTP-03 | User can pass `--record` flag to get output formatted as a #Record compatible with governance/recording.cue | Fix 2 (ADP version fallback) fixes the one broken `--record` flow |

</phase_requirements>

## Summary

This phase is a pure SKILL.md text editing task. There is no library installation, no new file creation, and no structural rework. The work is: read the source CUE schemas, identify every place where SKILL.md instructions produce enum values, type names, or labels that don't match what the schemas actually define, and correct those instructions.

The v1.0 audit identified 4 specific gaps. This phase is also required to do a **full sweep** — systematically checking every enum, label, and type reference in SKILL.md against its source `.opt.cue` file. The full sweep revealed a 5th issue (ADP's instance type name) and confirmed the original 4 are the only critical ones.

**Primary recommendation:** Make 5 targeted text edits to SKILL.md. No reorganization needed. All fixes are inline corrections that keep the instruction concise and do not require adding new sections.

## Findings: Full Enum/Type Sweep

This section documents every SKILL.md claim cross-referenced against the actual schema definition. Issues are classified: **CRITICAL** (affects structured/record output correctness) or **COSMETIC** (affects only narrative correctness or instruction clarity).

### Issue 1: CDP/ATP terminal resolution enum values [CRITICAL]

**SKILL.md location:** Line 199 (Phase 3b / revision loop section)

**Current instruction:**
```
3. Check for skip-retry diagnoses: if diagnosis is `construct_incoherent` (CFFP), `construct_not_decomposable` (CDP), or `transfer_not_viable` (ATP), skip retry entirely. Apply the `reframe_and_close` resolution...
```

**Schema reality:**

| Protocol | Diagnosis | Correct resolution | SKILL.md says |
|----------|-----------|-------------------|---------------|
| CFFP | `construct_incoherent` | `reframe_and_close` | `reframe_and_close` ✓ CORRECT |
| CDP | `construct_not_decomposable` | `close_as_unified` | `reframe_and_close` ✗ WRONG |
| ATP | `transfer_not_viable` | `close_as_rejected` | `reframe_and_close` ✗ WRONG |

**Source:** `cdp.opt.cue` line 207: `resolution: "revise_evidence" | "revise_candidates" | "close_as_unified"` — `reframe_and_close` is not a valid CDP resolution enum value. `atp.opt.cue` line 127: `resolution: "revise_correspondence" | "revise_candidates" | "close_as_rejected"` — `reframe_and_close` is not a valid ATP resolution enum value.

**Impact:** `--structured` output for CDP/ATP terminal paths will include an invalid `resolution` enum value. Narrative output is unaffected since Claude infers intent. Affects EXEC-05 and OUTP-02.

**Fix:** Name the per-protocol resolution values explicitly. The instruction should state: CFFP → `reframe_and_close`, CDP → `close_as_unified`, ATP → `close_as_rejected`.

---

### Issue 2: ADP missing #Protocol.version for --record [CRITICAL]

**SKILL.md location:** Line 308 (Output Rendering > Record output)

**Current instruction:**
```
source_run.run_version: From `#Protocol.version` in the loaded `.opt.cue` file
```

**Schema reality:** ADP (`adp.opt.cue`) has **no** `#Protocol` type and no `version` field. All other 12 protocols define `#Protocol { name, version, description }`. ADP defines only `#ADPPersona`, `#ADPSubject`, `#ADPRoundType`, `#ADPRecord`, `#ADPOutcome`, etc. — no `#Protocol`.

**Confirmed:** Reading `adp.opt.cue` in full: the word "version" does not appear as a top-level struct field anywhere in the file.

**Impact:** ADP + `--record` cannot populate `source_run.run_version` from schema. Affects OUTP-03.

**Fix options (Claude's discretion):**
1. **Omit gracefully:** When ADP is the source protocol, set `source_run.run_version` to `"n/a"` or `""` with a note in `notes` field.
2. **Use a sentinel:** Use `"adp-unversioned"` — makes the omission explicit and queryable.
3. **Use recording.cue's own version:** Use `"0.1.0"` (the recording.cue version), treating the record version as schema-driven not protocol-driven.

**Recommendation:** Use `"n/a"` — it is honest (no version exists), brief, and does not require Claude to guess or invent a version. Include a note in `notes` field: `"ADP protocol has no #Protocol.version field"`.

**Fix scope options:**
- ADP-specific exception inline in the `source_run.run_version` bullet
- General fallback rule: "If the protocol has no `#Protocol.version`, use `"n/a"`"

**Recommendation:** Add a general fallback rule — ADP is currently the only protocol without `#Protocol`, but this rule is more robust and self-documenting. The ADP exception is then handled by the general rule without needing a special ADP carve-out.

---

### Issue 3: AAP FragilityMap tier labels [CRITICAL]

**SKILL.md location:** Line 231 (Execution > Evaluative protocols > AAP note)

**Current instruction:**
```
the fragility map (#FragilityMap) lists assumptions by tier (load-bearing, structural, background)
```

**Schema reality:** `aap.opt.cue` defines `#FragilityTier` with:
```
tier:  1 | 2 | 3 | 4
label: "structural" | "significant" | "moderate" | "minor"
```

The `#Assumption` type uses `preliminary_load: "structural" | "significant" | "moderate" | "minor"`. The `#StressTestResult` uses `refined_load: "structural" | "significant" | "moderate" | "minor"`.

**SKILL.md tier names vs. schema:**
| SKILL.md name | Schema label | Match? |
|---------------|-------------|--------|
| `load-bearing` | (not a schema value) | ✗ WRONG |
| `structural` | `structural` | ✓ CORRECT |
| `background` | (not a schema value) | ✗ WRONG |
| (missing) | `significant` | ✗ MISSING |
| (missing) | `moderate` | ✗ MISSING |
| (missing) | `minor` | ✗ MISSING |

**Impact:** Both narrative AAP output (uses wrong tier names) and `--structured` AAP output (invalid enum values) are affected. This is the most user-visible issue because AAP tier labels appear in the human-readable fragility map section. Affects EXEC-02 and OUTP-02.

**Fix:** Replace the tier list with the 4 correct schema labels: `structural`, `significant`, `moderate`, `minor`. Optionally add tier numbers (Tier 1–4) for clarity.

**Note on AAP phase count:** SKILL.md line 231 says "AAP has 6 phases" — this is CORRECT per the schema (Phase1 through Phase6 are all defined in `aap.opt.cue`). The phase names given are slightly informal but semantically accurate:
- Schema Phase1 = subject + extraction (assumptions)
- Schema Phase2 = plausibility + coupling
- SKILL.md calls these "subject, extraction, plausibility, stress-test, fragility map, and recommendations"
This labeling is not schema-exact (schema uses Phase1–Phase6 not named phases) but is not wrong enough to fix — it is narrative guidance, not an enum. Leave as-is.

---

### Issue 4: #ProtocolInstance type reference [CRITICAL — precision]

**SKILL.md location:** Line 283 (Output Rendering > Structured output)

**Current instruction:**
```
Field names and nesting follow the protocol's `#ProtocolInstance` type from its `.opt.cue` file.
```

**Schema reality:** No `.opt.cue` file defines a type named `#ProtocolInstance`. The actual per-protocol instance types are:

| Protocol | Instance type in schema |
|----------|------------------------|
| CFFP | `#CFFPInstance` |
| CDP | `#CDPInstance` |
| CBP | `#CBPInstance` |
| HEP | `#HEPInstance` |
| ATP | `#ATPInstance` |
| EMP | `#EMPInstance` |
| AAP | `#AAPInstance` |
| CGP | `#CGPInstance` |
| IFA | `#IFAInstance` |
| OVP | `#OVPInstance` |
| PTP | `#PTPInstance` |
| RCP | `#RCPInstance` |
| ADP | `#ADPRecord` (different pattern — no `#ADPInstance`) |

**Impact:** Claude can infer `#{ACRONYM}Instance` from context and the convention holds for 12 of 13 protocols, so this is unlikely to cause a literal failure in practice. However, the instruction is imprecise — it teaches a type name that does not exist — and for ADP specifically, the implied `#ADPInstance` is wrong; the correct type is `#ADPRecord`.

**Fix:** Replace `#ProtocolInstance` with `#{ACRONYM}Instance` (the pattern) and add an explicit exception for ADP: "For ADP, use `#ADPRecord` (the exploratory protocol uses a record-typed output, not an instance wrapper)."

---

### Issue 5: ADP structured output type name [CRITICAL — specific case of Issue 4]

**Note:** This is a consequence of Issue 4. When Claude sees the pattern `#{ACRONYM}Instance` and substitutes ADP, it would produce `#ADPInstance`, which does not exist. The correct type is `#ADPRecord`.

**Schema confirmation:** `adp.opt.cue` defines `#ADPRecord` at line 116. There is no `#ADPInstance` anywhere in the file.

**Fix:** Explicitly name `#ADPRecord` as the ADP exception when fixing Issue 4.

---

### Sweep: Other Protocol Instance Types — No Additional Issues Found

All other 12 protocols follow the `#{ACRONYM}Instance` pattern exactly:
- `#CFFPInstance`, `#CDPInstance`, `#CBPInstance`, `#HEPInstance`, `#ATPInstance`, `#EMPInstance` — confirmed in adversarial `.opt.cue` files
- `#AAPInstance`, `#CGPInstance`, `#IFAInstance`, `#OVPInstance`, `#PTPInstance`, `#RCPInstance` — confirmed in evaluative `.opt.cue` files

No additional instance type naming issues exist beyond ADP.

---

### Sweep: Phase3b Diagnoses and Resolutions — Partial Issue Found

The SKILL.md only names skip-retry diagnoses explicitly. The instruction says: "skip retry entirely. Apply the `reframe_and_close` resolution" for the 3 skip-retry diagnoses. Issue 1 above covers this.

For completeness, here are all Phase3b resolution enums across all adversarial protocols:

| Protocol | Diagnoses | Resolutions |
|----------|-----------|-------------|
| CFFP | `invariants_too_strong`, `candidates_too_weak`, `construct_incoherent` | `revise_invariants`, `revise_candidates`, `reframe_and_close` |
| CDP | `evidence_insufficient`, `candidates_too_weak`, `construct_not_decomposable` | `revise_evidence`, `revise_candidates`, `close_as_unified` |
| CBP | `usages_insufficient`, `candidates_too_weak`, `term_irredeemable` | `collect_more_usages`, `revise_candidates`, `close_as_retired` |
| HEP | `exhaustiveness_failed`, `space_needs_expansion`, `new_hypotheses_needed` | `revise_observation`, `expand_space`, `generate_hypotheses`, `close_as_exhausted` |
| ATP | `correspondence_too_strong`, `candidates_too_weak`, `transfer_not_viable` | `revise_correspondence`, `revise_candidates`, `close_as_rejected` |
| EMP | `candidates_too_weak`, `behavior_not_emergent`, `observation_insufficient` | `revise_candidates`, `close_as_non_emergent`, `gather_more_observations` |

SKILL.md only names skip-retry diagnoses (CFFP, CDP, ATP). The non-skip-retry paths delegate to schema-directed execution ("let the loaded schema's type definitions drive what each phase requires"), which is correct — Claude reads the file and follows its enum values. The only fix needed is Issue 1 (the named skip-retry resolutions for CDP/ATP).

CBP, HEP, EMP skip-retry diagnoses (`term_irredeemable`, `close_as_exhausted`, `behavior_not_emergent`) are not named in SKILL.md — they fall under the general schema-directed execution instruction. This is intentional and correct: only the 3 protocols with "hard stop, no retry" skip diagnoses needed explicit instruction. However, there is an implicit correction needed: SKILL.md's current instruction says `reframe_and_close` for ALL three named skip-diagnoses. After the fix, only CFFP uses `reframe_and_close`; CDP uses `close_as_unified` and ATP uses `close_as_rejected`.

---

### Sweep: AAP Phase Structure — No Additional Issues Beyond Issue 3

The AAP schema defines 6 phases. SKILL.md says "AAP has 6 phases." The phase descriptions are narrative, not enum-backed — no enum mismatch. Only the tier label names (Issue 3) are wrong.

Additional AAP schema observations for completeness:
- `#AssumptionCluster.cluster_fragility` uses `"structural" | "significant" | "moderate" | "minor"` — same enum as individual assumption tiers
- `#AuditRecord.outcome` uses `#Outcome` which is `"mapped" | "incomplete" | "incoherent"` — SKILL.md does not name these explicitly; they are schema-directed
- `#FragilityMap.overall_fragility` uses `"brittle" | "fragile" | "robust" | "resilient"` — SKILL.md does not name these explicitly; schema-directed

No additional enum issues in AAP beyond the tier labels.

---

### Sweep: Recording.cue — No Issues Found

The `#Record` field population rules in SKILL.md match `recording.cue`:
- `record_id` format: not schema-defined (Claude-invented convention) — correct
- `source_run.protocol`: typed as `#SourceProtocol` which matches all 13 protocol acronyms — correct
- `source_run.run_version`: Issue 2 (ADP) — the only problem
- `dispute.kind`: SKILL.md mapping table covers all 13 `#DisputeKind` values — confirmed correct
- `resolution.status`: `"decided" | "open" | "rejected"` matches `#ResolutionStatus` — correct
- `tags`: Claude-generated array, not schema-typed — no issue
- `next_actions.protocol`: typed as `#SourceProtocol` (optional field) — correct

---

### Sweep: Routing Output Enums — No Issues Found

SKILL.md routing section uses `"routed"`, `"ambiguous"`, `"unroutable"` as outcome labels. These are SKILL.md-internal routing outcome labels, not schema enum values. The routing.cue schema is read at runtime and the inline comments are the mapping table. No enum mismatch.

---

### Sweep: All Outcome Enums by Protocol — No Additional Issues

| Protocol | Schema `#Outcome` values | SKILL.md reference |
|----------|--------------------------|-------------------|
| CFFP | `"canonical" \| "collapse" \| "open"` | Not named explicitly; schema-directed |
| CDP | `"split" \| "unified" \| "open"` | Not named explicitly; schema-directed |
| CBP | `"sharpened" \| "split" \| "retired" \| "open"` | Not named explicitly; schema-directed |
| HEP | `"converged" \| "open" \| "exhausted"` | Not named explicitly; schema-directed |
| ATP | `"validated" \| "rejected" \| "open"` | Not named explicitly; schema-directed |
| EMP | `"mapped" \| "non_emergent" \| "open"` | Not named explicitly; schema-directed |
| AAP | `"mapped" \| "incomplete" \| "incoherent"` | Not named explicitly; schema-directed |
| CGP | `"admissible_revision" \| "inadmissible" \| "deprecated" \| "conditional_retention" \| "deferred"` | Not named explicitly; schema-directed |
| IFA | `"faithful" \| "divergent" \| "indeterminate"` | Not named explicitly; schema-directed |
| OVP | `"validated" \| "contested" \| "artifact"` | Not named explicitly; schema-directed |
| PTP | `"ranked" \| "tied" \| "insufficient_data"` | Not named explicitly; schema-directed |
| RCP | `"compatible" \| "reconciled" \| "conflicted" \| "incommensurable" \| "mixed"` | Not named explicitly; schema-directed |
| ADP | `#ADPOutcome: "design_mapped" \| "exhaustion" \| "scope_reduction"` | Named correctly in SKILL.md line 249 ✓ |

No outcome enum mismatches found.

---

### Sweep: Gate Field Names — Already Correct in SKILL.md

SKILL.md line 209 lists:
- CFFP: `all_provable` ← correct (`cffp.opt.cue` line 167: `all_provable: bool`)
- CDP: `all_ready` ← correct (`cdp.opt.cue` line 245: `all_ready: bool`)
- CBP, HEP, ATP, EMP: `all_satisfied` ← correct (all four schemas use `all_satisfied: bool`)

No gate field name issues.

---

### Sweep: ADP Execution Instructions — Additional Observation

SKILL.md line 241 lists ADP subject types: `new_construct`, `new_domain`, `breaking_change`, `decision`. Cross-referenced against `adp.opt.cue` lines 16–49: `#ADPSubject` defines exactly these four optional fields. Correct.

SKILL.md line 243 lists round types: `probe`, `pressure`, `synthesis`, `handoff`. `adp.opt.cue` line 51: `#ADPRoundType: "probe" | "pressure" | "synthesis" | "handoff"`. Correct.

SKILL.md line 249 lists terminal outcomes: `design_mapped`, `exhaustion`, `scope_reduction`. `adp.opt.cue` line 114: `#ADPOutcome: "design_mapped" | "exhaustion" | "scope_reduction"`. Correct.

---

### Sweep: OVP → HEP Handoff — No Issues

SKILL.md line 257: "Extract OVP's Phase 4 `validated_observation` — its phenomenon, confidence level, and caveats." Cross-referenced: `ovp.opt.cue` defines `#ValidatedObservation { phenomenon: string, confidence: "high" | "medium", caveats: [...string] }`. The field references are correct.

---

## Standard Stack

This phase involves no new libraries. The work is entirely text editing of one file.

| Item | Role | Notes |
|------|------|-------|
| SKILL.md | Target file | One file, ~339 lines; 5 targeted text edits |
| `.opt.cue` files | Reference documents | Already exist; read for verification |
| `recording.cue` | Reference document | Already exists; read for verification |

## Architecture Patterns

### Fix Pattern: Inline Protocol-Specific Values

For Issue 1 (resolution enums), the cleanest fix is to expand the single generic instruction into per-protocol named values in a brief inline table or list. This is clearer than a conditional branch and matches the style of the gate field names table already in SKILL.md (lines 209–212).

**Before (current SKILL.md line 199):**
```
Apply the `reframe_and_close` resolution, explain why retrying won't help...
```

**After (recommended):**
```
Apply the protocol-specific skip-retry resolution — the resolution enum value differs per protocol:
- CFFP (`construct_incoherent`): `reframe_and_close`
- CDP (`construct_not_decomposable`): `close_as_unified`
- ATP (`transfer_not_viable`): `close_as_rejected`
Explain why retrying won't help...
```

### Fix Pattern: ADP Version Fallback Rule

For Issue 2, a general fallback rule is cleaner than ADP-specific exception prose. The fallback rule handles ADP as the current case and any future protocol that also lacks `#Protocol`.

**Before (current SKILL.md line 308):**
```
`source_run.run_version`: From `#Protocol.version` in the loaded `.opt.cue` file
```

**After (recommended):**
```
`source_run.run_version`: From `#Protocol.version` in the loaded `.opt.cue` file. If the protocol has no `#Protocol` type (currently: ADP), use `"n/a"` and add a note in the `notes` field.
```

### Fix Pattern: Tier Label Correction

For Issue 3, the SKILL.md AAP note references a nonexistent set of tier names. The fix replaces the parenthetical tier list with the 4 correct schema label values. The tier numbers (1–4) map to the labels in schema order.

**Before (current SKILL.md line 231):**
```
the fragility map (#FragilityMap) lists assumptions by tier (load-bearing, structural, background)
```

**After (recommended):**
```
the fragility map (#FragilityMap) lists assumptions by tier: Tier 1 (`structural`), Tier 2 (`significant`), Tier 3 (`moderate`), Tier 4 (`minor`)
```

### Fix Pattern: Protocol Instance Type Name

For Issue 4, replace the non-existent generic name with the pattern plus the ADP exception.

**Before (current SKILL.md line 283):**
```
Field names and nesting follow the protocol's `#ProtocolInstance` type from its `.opt.cue` file.
```

**After (recommended):**
```
Field names and nesting follow the protocol's instance type from its `.opt.cue` file: `#{ACRONYM}Instance` for all protocols except ADP, which uses `#ADPRecord`.
```

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Schema validation | CUE eval toolchain | Direct schema reading | Project decision: Claude interprets schemas directly; no toolchain dependency |
| Enum lookups | Inline enum tables in SKILL.md | Schema-directed execution | SKILL.md already delegates most enum decisions to "read the schema file" — only exceptions need explicit naming |

**Key insight:** This phase fixes the places where the current SKILL.md departed from schema-directed execution by hard-coding wrong values. The fixes bring instructions back into alignment, not away from it.

## Common Pitfalls

### Pitfall 1: Over-specifying ADP version fallback
**What goes wrong:** Trying to fill `source_run.run_version` with a plausible-looking version string (e.g., `"0.1.0"`) that isn't actually in the ADP schema — this would be a lie rather than a graceful omission.
**Why it happens:** Desire to produce a "complete" looking record.
**How to avoid:** Use `"n/a"` — it is honest. The field exists in `#SourceRun` as `run_version: string` with no enum constraint, so `"n/a"` is type-valid.

### Pitfall 2: Fixing only the 4 audit items without doing the sweep
**What goes wrong:** Missing Issue 5 (ADP `#ADPRecord` vs. `#ADPInstance`) which is a consequence of Issue 4.
**Why it happens:** Issue 4 and Issue 5 look like one issue but they have two distinct SKILL.md locations — the generic type name instruction AND the ADP-specific fix both need updating.
**How to avoid:** After fixing Issue 4, verify that the ADP-specific exception (`#ADPRecord`) is also named.

### Pitfall 3: Changing AAP phase count or phase names
**What goes wrong:** The sweep reveals that AAP phase naming in SKILL.md is slightly informal but not wrong — over-fixing could introduce new problems.
**Why it happens:** "If the tier labels are wrong, maybe everything about the AAP section is wrong."
**How to avoid:** Only fix Issue 3 (tier labels). The phase count (6) and narrative phase names are correct enough for their purpose (guiding narrative execution, not producing enum output).

### Pitfall 4: Adding resolution enum tables for all 13 protocols
**What goes wrong:** Over-engineering the fix by adding complete Phase3b tables for all protocols. SKILL.md's schema-directed execution pattern deliberately avoids this — Claude reads the `.opt.cue` file for non-named cases.
**Why it happens:** "If we're fixing CDP/ATP, shouldn't we fix CBP, HEP, EMP too?"
**How to avoid:** Only name the skip-retry (hard-stop) resolutions, because those need to override the general "read from schema" pattern. The non-skip-retry resolutions are already handled by schema-directed execution.

### Pitfall 5: Modifying the dispute kind mapping table
**What goes wrong:** Assuming the dispute kind table also has errors and modifying it unnecessarily.
**Why it happens:** The table is adjacent to the `source_run.run_version` instruction that has a known error.
**How to avoid:** The full sweep confirms the dispute kind table is correct — all 13 `#DisputeKind` values match exactly. Leave it untouched.

## Code Examples

### SKILL.md line 199 — Resolution enum fix

Target text (current, abbreviated):
```
3. Check for skip-retry diagnoses: if diagnosis is `construct_incoherent` (CFFP), `construct_not_decomposable` (CDP), or `transfer_not_viable` (ATP), skip retry entirely. Apply the `reframe_and_close` resolution, explain why retrying won't help, and give the user reframe suggestions. Stop.
```

Target text (corrected):
```
3. Check for skip-retry diagnoses: if diagnosis is `construct_incoherent` (CFFP), `construct_not_decomposable` (CDP), or `transfer_not_viable` (ATP), skip retry entirely. Apply the protocol's skip-retry resolution — `reframe_and_close` for CFFP, `close_as_unified` for CDP, `close_as_rejected` for ATP — explain why retrying won't help, and give the user reframe suggestions. Stop.
```

### SKILL.md line 231 — AAP tier label fix

Target text (current):
```
- **AAP note:** AAP has 6 phases — subject, extraction, plausibility, stress-test, fragility map, and recommendations. Give the stress-test and fragility map phases their own section headers; the fragility map (#FragilityMap) lists assumptions by tier (load-bearing, structural, background). The recommendations phase references the tier rankings.
```

Target text (corrected):
```
- **AAP note:** AAP has 6 phases — subject, extraction, plausibility, stress-test, fragility map, and recommendations. Give the stress-test and fragility map phases their own section headers; the fragility map (#FragilityMap) lists assumptions by tier: Tier 1 (`structural`), Tier 2 (`significant`), Tier 3 (`moderate`), Tier 4 (`minor`). The recommendations phase references the tier rankings.
```

### SKILL.md line 283 — Instance type name fix

Target text (current):
```
Field names and nesting follow the protocol's `#ProtocolInstance` type from its `.opt.cue` file.
```

Target text (corrected):
```
Field names and nesting follow the protocol's instance type from its `.opt.cue` file: `#{ACRONYM}Instance` for all protocols except ADP, which uses `#ADPRecord`.
```

### SKILL.md line 308 — ADP version fallback fix

Target text (current):
```
- `source_run.run_version`: From `#Protocol.version` in the loaded `.opt.cue` file
```

Target text (corrected):
```
- `source_run.run_version`: From `#Protocol.version` in the loaded `.opt.cue` file. If the protocol has no `#Protocol` type (currently: ADP only), use `"n/a"` and note this in the `notes` field.
```

## State of the Art

This is a single-file instruction correction task — no technology patterns or framework versions are relevant.

## Open Questions

1. **ADP version sentinel value**
   - What we know: `"n/a"` is type-valid for `run_version: string`, honest, and brief
   - What's unclear: Whether users who query records by `run_version` would expect something more informative
   - Recommendation: Use `"n/a"` — it is the simplest correct answer. The `notes` field clarifies why.

2. **CBP/HEP/EMP skip-retry resolutions**
   - What we know: These protocols have terminal diagnoses (`term_irredeemable`, `close_as_exhausted`, `behavior_not_emergent`) but SKILL.md only names the 3 skip-retry cases (CFFP/CDP/ATP)
   - What's unclear: Whether CBP, HEP, and EMP skip-diagnoses should also be named explicitly
   - Recommendation: Leave them under schema-directed execution. The existing SKILL.md pattern is intentional — only hard-coded skip-retry paths need explicit naming. CBP/HEP/EMP can read their own resolution values from the loaded schema.

## Sources

### Primary (HIGH confidence)
- `/Users/javier/projects/socrates/.claude/skills/socrates/protocols/adversarial/cdp.opt.cue` — CDP Phase3b resolution enum: `"revise_evidence" | "revise_candidates" | "close_as_unified"`
- `/Users/javier/projects/socrates/.claude/skills/socrates/protocols/adversarial/atp.opt.cue` — ATP Phase3b resolution enum: `"revise_correspondence" | "revise_candidates" | "close_as_rejected"`
- `/Users/javier/projects/socrates/.claude/skills/socrates/protocols/adversarial/cffp.opt.cue` — CFFP Phase3b resolution enum: `"revise_invariants" | "revise_candidates" | "reframe_and_close"`
- `/Users/javier/projects/socrates/.claude/skills/socrates/protocols/evaluative/aap.opt.cue` — `#FragilityTier.label: "structural" | "significant" | "moderate" | "minor"`
- `/Users/javier/projects/socrates/.claude/skills/socrates/protocols/exploratory/adp.opt.cue` — No `#Protocol` type, no `version` field; top-level record type is `#ADPRecord`
- `/Users/javier/projects/socrates/.claude/skills/socrates/dialectics/governance/recording.cue` — `#SourceRun.run_version: string` (unconstrained — `"n/a"` is valid)
- `/Users/javier/projects/socrates/.planning/v1.0-MILESTONE-AUDIT.md` — 4 known audit gaps with exact SKILL.md line references
- `/Users/javier/projects/socrates/.claude/skills/socrates/SKILL.md` — Current instruction text; full 339-line read

### Secondary (MEDIUM confidence)
- N/A — all sources are primary project files

### Tertiary (LOW confidence)
- None

## Metadata

**Confidence breakdown:**
- Issues found: HIGH — All confirmed by direct schema file reading
- Fix correctness: HIGH — Verified fix values against schema source of truth
- Fix scope: HIGH — Full sweep completed across all 13 protocols and 5 governance files
- Sweep completeness: HIGH — Every protocol's Phase3b, instance types, outcome enums, and gate fields were cross-checked

**Research date:** 2026-02-28
**Valid until:** Until any `.opt.cue` file changes (schema changes would invalidate the confirmed enum values). Otherwise stable indefinitely.

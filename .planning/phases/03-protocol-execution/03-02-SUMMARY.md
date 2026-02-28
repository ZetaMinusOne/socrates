---
phase: 03-protocol-execution
plan: 02
subsystem: skill
tags: [execution, evaluative-protocols, exploratory-protocols, adp, multi-protocol-handoff, narrative-output]

# Dependency graph
requires:
  - "03-01 (SKILL.md ## Execution section: adversarial protocol execution instructions, narrative structure, eager gate pattern)"
  - "01-01 (SKILL.md structure: Preflight, Input, Protocol Files, Routing, Execution sections)"
  - "01-02 (protocols/evaluative/{acronym}.opt.cue and protocols/exploratory/adp.opt.cue files)"
provides:
  - "SKILL.md ### Evaluative protocols subsection: subject → criteria → assess → verdict arc, no revision loops"
  - "RCP Phase 1 blocked check with CBP referral instruction"
  - "CGP case kind routing (revision/deprecation/combined)"
  - "AAP 6-phase FragilityMap rendering guidance"
  - "PTP sensitivity analysis note on weight-dependent rankings"
  - "SKILL.md ### Exploratory protocol (ADP) subsection: multi-persona rounds in third-person narrator voice"
  - "ADP referee constraint checks and three terminal outcomes (design_mapped, exhaustion, scope_reduction)"
  - "SKILL.md ### Multi-protocol handoff subsection: explicit handoff section format"
  - "OVP → HEP state transfer: validated_observation → phenomenon, caveats → known_exclusions"
  - "Early termination logic for invalidating first-protocol outcomes"
  - "No redundant routing block on second protocol start"
affects: [phase-4-structured-output]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Evaluative protocol arc: establish subject → define criteria → assess → deliver verdict (no revision loops)"
    - "Third-person narrator voice for ADP multi-persona rounds: narrator describes each persona's argument, not first-person dialogue or bare transcript"
    - "Explicit state transfer in composite sequences: OVP validated_observation → HEP #Phenomenon.observation, OVP caveats → HEP known_exclusions"
    - "Early termination on invalidating first-protocol outcomes (OVP artifact → stop HEP)"

key-files:
  created: []
  modified:
    - .claude/skills/socrates/SKILL.md

key-decisions:
  - "Evaluative protocols explicitly have no revision loops: a failed or indeterminate verdict is terminal — state this clearly so Claude does not attempt retry behavior carried from adversarial execution"
  - "RCP blocked check placed after Phase 1 vocabulary alignment: if blocked: true, stop and refer to CBP before proceeding — this is a prerequisite gate unique to RCP"
  - "CGP case kind determined from user's problem description: Claude determines revision/deprecation/combined and populates only the relevant phase checks — avoids rendering irrelevant preservation/erosion checks"
  - "ADP narrator voice is third person (narrator describes persona arguments), not first-person persona dialogue and not bare transcript — this was Claude's discretion per CONTEXT.md, resolved here as third-person narrator"
  - "OVP → HEP handoff uses OVP's refined validated_observation as HEP starting point: do NOT re-derive phenomenon from original problem — preserves OVP's epistemic work"

# Metrics
duration: 1min
completed: 2026-02-28T15:59:00Z
---

# Phase 3 Plan 02: Protocol Execution — Evaluative, Exploratory, and Multi-Protocol Handoff Summary

**Complete execution coverage for all 13 protocols: evaluative protocol arc (subject → criteria → assess → verdict, no revision loops) with RCP/CGP/AAP/PTP protocol-specific handling; ADP exploratory execution with third-person narrator voice for multi-persona rounds and three terminal outcomes; OVP → HEP multi-protocol handoff with explicit state transfer and early termination logic**

## Performance

- **Duration:** 1 min
- **Started:** 2026-02-28T15:57:28Z
- **Completed:** 2026-02-28T15:59:00Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- `### Evaluative protocols (AAP, IFA, RCP, CGP, PTP, OVP)` subsection added to `## Execution` in SKILL.md:
  - General evaluative arc: establish subject → define criteria → assess → deliver verdict
  - Explicit "no revision loops" statement preventing adversarial retry behavior from bleeding into evaluative execution
  - RCP Phase 1 blocked check: if `blocked: true`, stop and instruct user to resolve homonyms via CBP first
  - CGP case kind routing: determine revision/deprecation/combined from problem description, render only relevant checks
  - AAP 6-phase note: stress-test and fragility map get own section headers; FragilityMap lists tiers (load-bearing, structural, background)
  - PTP sensitivity analysis: note when top ranking changes under criteria weight perturbation

- `### Exploratory protocol (ADP)` subsection added:
  - Schema-directed execution via `protocols/exploratory/adp.opt.cue`
  - ADP subject types enumerated (new_construct, new_domain, breaking_change, decision)
  - Third-person narrator voice established: "The formalist raises a decidability concern, arguing that..." — not first-person dialogue, not bare transcript
  - Referee constraint checks: proposals failing `#ConstraintCheckSet.passed: false` are blocked; violated constraint stated
  - Round progression: probe → pressure → synthesis (with additional rounds if synthesis doesn't converge)
  - Three terminal outcomes: `design_mapped` (renders #DesignMap, notes CFFP-ready constructs), `exhaustion`, `scope_reduction`

- `### Multi-protocol handoff` subsection added:
  - Explicit handoff section format between protocols
  - OVP → HEP state transfer: `validated_observation` (phenomenon, confidence, caveats) → HEP `#Phenomenon.observation`; OVP caveats → HEP `known_exclusions`
  - Prohibition on re-deriving phenomenon from original problem — use OVP's refined output
  - Early termination: OVP `artifact` outcome invalidates HEP (would operate on false premise) — stop, explain, suggest alternatives
  - No redundant routing block when second protocol begins
  - General pattern for future composites: check first protocol's terminal output type, map to second protocol's Phase 1 input

- Total SKILL.md: 249 lines (was 203 lines; added 46 lines across 3 subsections)
- Complete Execution section now has 4 subsections: Adversarial (Plan 01), Evaluative (Task 1), Exploratory ADP (Task 2), Multi-protocol handoff (Task 2)

## Task Commits

1. **Task 1: Add evaluative protocol execution instructions** — `d9e88cc` (feat)
2. **Task 2: Add ADP exploratory and multi-protocol handoff instructions** — `86f5b7c` (feat)

## Files Created/Modified

- `.claude/skills/socrates/SKILL.md` — Added 3 new subsections to `## Execution`: Evaluative protocols (16 lines), Exploratory protocol ADP (15 lines), Multi-protocol handoff (13 lines). 249 lines total (was 203 lines).

## Decisions Made

- Resolved ADP persona voice as third-person narrator (was Claude's discretion per CONTEXT.md): narrator describes each persona's argument and its relationship to other arguments — this produces flowing narrative rather than a dramatic script or a dry transcript
- Evaluative protocols explicitly have no revision loops: stated up front in the general evaluative arc description so Claude does not apply adversarial retry behavior to evaluative runs
- OVP → HEP handoff uses OVP's refined output, not the original problem: preserves the epistemic work OVP did validating the observation — HEP starts from a higher-quality input

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Phase 3 Plan 02 (evaluative + exploratory + handoff) is complete
- SKILL.md now covers all 13 protocols across 3 families with complete execution instructions
- Phase 3 is fully complete: adversarial (Plan 01), evaluative + ADP + handoff (Plan 02)
- Phase 4 (structured output) can begin: adds typed/structured output alongside narrative prose when requested

## Self-Check: PASSED

- FOUND: `.claude/skills/socrates/SKILL.md` (249 lines, under 350-line budget)
- FOUND commit: `d9e88cc` (feat(03-02) — evaluative protocol execution instructions)
- FOUND commit: `86f5b7c` (feat(03-02) — ADP exploratory and multi-protocol handoff instructions)
- VERIFIED: `### Evaluative protocols` subsection exists at line 205
- VERIFIED: General evaluative arc (subject → criteria → assess → verdict) stated at line 207
- VERIFIED: "No revision loops" explicit at line 207
- VERIFIED: RCP Phase 1 blocked check at line 213
- VERIFIED: CGP case kind routing at line 215
- VERIFIED: AAP 6-phase note with FragilityMap at line 217
- VERIFIED: PTP sensitivity analysis note at line 219
- VERIFIED: `### Exploratory protocol (ADP)` subsection exists at line 221
- VERIFIED: Third-person narrator voice specified at line 229 (with explicit anti-patterns: not first-person, not bare transcript)
- VERIFIED: Referee constraint checks at line 231
- VERIFIED: Three terminal outcomes at line 235
- VERIFIED: `### Multi-protocol handoff` subsection exists at line 237
- VERIFIED: OVP → HEP state transfer (validated_observation → phenomenon, caveats → known_exclusions) at line 243
- VERIFIED: Early termination for OVP artifact → stop HEP at line 245
- VERIFIED: No redundant routing block instruction at line 247
- VERIFIED: No "future update" placeholder text anywhere in SKILL.md
- VERIFIED: 13 protocols covered: CFFP, CDP, CBP, HEP, ATP, EMP (adversarial); AAP, IFA, RCP, CGP, PTP, OVP (evaluative); ADP (exploratory)
- VERIFIED: Complete section flow: Preflight → Input → Protocol Files → Routing → Execution (4 subsections)

---
*Phase: 03-protocol-execution*
*Completed: 2026-02-28*

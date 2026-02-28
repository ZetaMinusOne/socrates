---
phase: 03-protocol-execution
plan: 01
subsystem: skill
tags: [execution, adversarial-protocols, obligation-gates, revision-loops, narrative-output]

# Dependency graph
requires:
  - "02-01 (SKILL.md ## Routing section: routing block display + Phase 3 handoff stub)"
  - "01-01 (SKILL.md structure: Preflight, Input, Protocol Files, Routing, Execution sections)"
  - "01-02 (protocols/adversarial/{acronym}.opt.cue files with phase type definitions)"
provides:
  - "SKILL.md ## Execution section: complete adversarial protocol execution instructions"
  - "Context bridge sentence pattern connecting routing to execution"
  - "Schema-directed phase execution for all 6 adversarial protocols (CFFP, CDP, CBP, HEP, ATP, EMP)"
  - "Eager gate enforcement at every phase transition (not only Phase 5)"
  - "Revision loop with skip-retry diagnoses (construct_incoherent, construct_not_decomposable, transfer_not_viable)"
  - "Phase 5 gate field names per protocol (all_provable/CFFP, all_ready/CDP, all_satisfied/others)"
  - "CDP cffp_instructions handoff for subsequent CFFP runs"
affects: [phase-3-plan-02-execution-evaluative-exploratory]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Schema-directed execution: SKILL.md instructs Claude to read .opt.cue schema then follow its type definitions — no hard-coded phase sequences"
    - "Eager gate enforcement: check preconditions at every phase transition using [_, ...] CUE constraint pattern as the trigger signal"
    - "Skip-retry classification: 3 specific Phase3b diagnoses (construct_incoherent, construct_not_decomposable, transfer_not_viable) bypass revision loop"
    - "Per-protocol gate fields: all_provable (CFFP), all_ready (CDP), all_satisfied (CBP/HEP/ATP/EMP) — correct field per schema"

key-files:
  created: []
  modified:
    - .claude/skills/socrates/SKILL.md

key-decisions:
  - "Schema-directed execution in SKILL.md rather than phase-by-phase hard-coding: Claude reads the .opt.cue file and follows its type definitions, preventing drift when schemas evolve"
  - "HEP Phase 2 note clarifies hypotheses are established in Phase 1 (not Phase 2): HEP's Phase1 type contains the hypothesis list, matching the schema structure accurately"
  - "HEP Phase4 branching documented explicitly: single survivor triggers ConfidenceAssessment, multiple survivors trigger DiscriminatingExperiment design — this is schema-defined behavior"

# Metrics
duration: 1min
completed: 2026-02-28T15:54:57Z
---

# Phase 3 Plan 01: Protocol Execution — Adversarial Protocols Summary

**Complete adversarial protocol execution instructions added to SKILL.md: schema-directed phase execution for all 6 adversarial protocols, eager obligation gate enforcement at every phase transition, revision loop with skip-retry exception for 3 terminal diagnoses, and correct per-protocol Phase 5 gate field names**

## Performance

- **Duration:** 1 min
- **Started:** 2026-02-28T15:53:31Z
- **Completed:** 2026-02-28T15:54:57Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- `## Execution` section in SKILL.md completely replaced: the 4-line placeholder ("Protocol execution will be implemented in a future update...") is replaced with 47 lines of complete adversarial protocol execution instructions
- Context bridge pattern defined: "Because your problem involves [characteristic], we'll apply [ACRONYM] — [clause]." with explicit "No confirmation gate" instruction
- Narrative structure rules established: phase headers (`### Phase N: [name]`), inline terminology on first use, output length scaling with complexity, no schema field dumps
- Eager gate enforcement principle stated: check `[_, ...]` CUE constraints at every phase transition, not only at Phase 5
- `### Adversarial protocols (CFFP, CDP, CBP, HEP, ATP, EMP)` subsection added with:
  - Schema-directed execution instruction: read `.opt.cue` file, let type definitions drive phase requirements
  - Phase 1 starting conditions per protocol (invariants/CFFP, incoherence evidence/CDP, phenomenon+hypotheses/HEP, source construct/ATP, composed forms/EMP)
  - Phase 2 candidate generation with eager gate
  - Phase 3 adversarial pressure with protocol-specific challenge types, rebuttal evaluation, and derived computation
  - Phase 3b revision loop: brief failure summary, explicit diagnosis label, skip-retry check for 3 terminal diagnoses, single retry with full second pass, no infinite loops
  - Phase 4 selection with HEP branching documented
  - Phase 5 obligation gate with per-protocol gate field names (all_provable/CFFP, all_ready/CDP, all_satisfied/others)
  - Phase 6 conditional on Phase 5 passing with protocol-specific outputs
  - CDP cffp_instructions handoff note
- Total SKILL.md: 203 lines (well within 300-line budget)

## Task Commits

1. **Task 1: Replace Execution placeholder with adversarial protocol execution instructions** — `75cfaeb` (feat)

## Files Created/Modified

- `.claude/skills/socrates/SKILL.md` — Replaced 2-line Execution placeholder with 47-line complete adversarial protocol execution section. 203 lines total (was 160 lines).

## Decisions Made

- Chose schema-directed execution pattern over hard-coding phase sequences in SKILL.md: instructs Claude to read the selected protocol's `.opt.cue` and follow its type definitions, so SKILL.md stays valid when schemas evolve upstream
- Documented HEP's Phase 1 hypothesis list accurately: HEP's `#Phase1` type contains the hypothesis array, so Phase 2 note clarifies candidates are "hypotheses already in Phase 1 for HEP" — not re-generated in Phase 2
- Documented HEP Phase4 branching explicitly: single survivor → `#ConfidenceAssessment`, multiple survivors → discriminating experiments — this is schema-defined conditional behavior that affects execution flow

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Phase 3 Plan 01 (adversarial protocols) is complete
- Phase 3 Plan 02 can begin: evaluative protocols (AAP, CGP, IFA, OVP, PTP, RCP) and exploratory protocol (ADP) execution instructions need to be added
- The adversarial execution pattern established here (schema-directed, eager gates, revision loops, narrative prose) serves as the template for evaluative and exploratory sections

## Self-Check: PASSED

- FOUND: `.claude/skills/socrates/SKILL.md` (203 lines, under 300-line budget)
- FOUND commit: `75cfaeb` (feat — adversarial protocol execution instructions)
- VERIFIED: `## Execution` section exists and contains no "future update" placeholder language
- VERIFIED: Context bridge instruction present at top of Execution section (line 158)
- VERIFIED: Narrative structure guidance present (phase headers, inline terminology, no schema dumps)
- VERIFIED: `### Adversarial protocols` subsection exists (line 164)
- VERIFIED: Eager gate enforcement at Phase 1→2 and Phase 2→3 transitions (lines 162, 176-178)
- VERIFIED: 3 skip-retry diagnoses enumerated: `construct_incoherent`, `construct_not_decomposable`, `transfer_not_viable` (line 185)
- VERIFIED: 3 Phase 5 gate field variants: `all_provable` (CFFP), `all_ready` (CDP), `all_satisfied` (others) (lines 195-197)
- VERIFIED: Phase 6 conditional on Phase 5 gate passing (line 201)
- VERIFIED: CDP `cffp_instructions` note present (line 203)
- VERIFIED: No schema field dumps — instructions direct Claude to read `.opt.cue` files
- VERIFIED: `protocols/adversarial/{acronym}.opt.cue` path referenced in execution instructions (line 166)
- VERIFIED: No user confirmation gate between routing and execution (line 158)
- VERIFIED: Eager enforcement principle stated ("every transition, not only at the schema's formal Phase 5 gate") (line 162)

---
*Phase: 03-protocol-execution*
*Completed: 2026-02-28*

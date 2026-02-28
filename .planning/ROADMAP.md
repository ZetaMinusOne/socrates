# Roadmap: Socrates

## Overview

Socrates ships as a Claude Code `/socrates` slash command in four strictly linear phases. Each phase validates a foundation the next phase depends on — submodule and skill scaffolding before routing, routing before protocol execution, narrative execution before structured output. The result is a zero-dependency skill that auto-routes any problem through one of 13 CUE-schema-defined dialectic protocols and returns rigorous, protocol-driven reasoning in prose by default.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Foundation** - Skill registered, submodule wired, progressive disclosure file structure in place (completed 2026-02-28)
- [x] **Phase 2: Routing** - Auto-routing via routing.cue validated with transparent protocol selection (completed 2026-02-28)
- [x] **Phase 3: Protocol Execution** - All 13 protocols executable with narrative output, obligation gates, and revision loop (completed 2026-02-28)
- [x] **Phase 4: Structured Output** - `--structured` and `--record` flags produce typed CUE-schema-compliant output (completed 2026-02-28)
- [x] **Phase 5: Schema Conformance Alignment** - Fix SKILL.md instructions to match actual CUE schema definitions for resolution enums, tier labels, type references, and ADP version field (completed 2026-02-28)

## Phase Details

### Phase 1: Foundation
**Goal**: Users can invoke `/socrates` and the skill is correctly registered, the dialectics submodule is accessible, and the progressive file structure is in place so no subsequent phase requires structural rework
**Depends on**: Nothing (first phase)
**Requirements**: INFRA-01, INFRA-02, INFRA-03, INFRA-04, INFRA-05
**Success Criteria** (what must be TRUE):
  1. User types `/socrates` in Claude Code and the command appears with the correct argument hint showing expected input format
  2. SKILL.md frontmatter registers the skill with `disable-model-invocation: true` and all required supporting file references
  3. The dialectics git submodule is initialized and all .cue files are readable by Claude via the Read tool (preflight check passes)
  4. SKILL.md instructs Claude to load protocol files on demand — no protocol content is inlined in SKILL.md itself
  5. Protocol .cue files are stripped of non-essential comments and whitespace to fit within the 16,000-character context budget
**Plans**: 2 plans
Plans:
- [ ] 01-01-PLAN.md — Register skill, wire submodule, create SKILL.md with progressive disclosure
- [ ] 01-02-PLAN.md — Strip CUE files and generate optimized protocol files for context budget

### Phase 2: Routing
**Goal**: Users describe any problem and the skill transparently selects the correct dialectic protocol before any protocol execution begins
**Depends on**: Phase 1
**Requirements**: ROUT-01, ROUT-02, ROUT-03
**Success Criteria** (what must be TRUE):
  1. User describes a problem and the skill reads governance/routing.cue, extracts structural features, and selects a protocol — without the user naming any protocol
  2. Every skill invocation shows which protocol was selected and a one-sentence rationale before execution proceeds
  3. When routing.cue identifies a composite problem, the skill sequences multiple protocols and executes them in order
**Plans**: 1 plan
Plans:
- [x] 02-01-PLAN.md — Add routing logic, display handlers, and outcome paths to SKILL.md

### Phase 3: Protocol Execution
**Goal**: Users receive rigorous narrative reasoning for any problem, with all 13 protocols faithfully executing their CUE-schema-defined phases, obligation gates, and revision loops
**Depends on**: Phase 2
**Requirements**: EXEC-01, EXEC-02, EXEC-03, EXEC-04, EXEC-05, OUTP-01
**Success Criteria** (what must be TRUE):
  1. User invokes `/socrates` with any problem type and receives a narrative prose response that traces routing rationale, protocol phase execution, and conclusion
  2. All 6 adversarial protocols (CFFP, CDP, CBP, HEP, ATP, EMP) execute their full challenge-rebuttal cycles without skipping phases
  3. All 6 evaluative protocols (AAP, IFA, RCP, CGP, PTP, OVP) execute their validation and judgment phases without skipping phases
  4. The exploratory protocol (ADP) executes its possibility-mapping phases
  5. When an adversarial protocol hits an obligation gate, execution pauses until all obligations are satisfied — no derivation proceeds with unmet gates
  6. When no candidates survive adversarial pressure, the revision loop triggers and returns feedback rather than forcing a false conclusion
**Plans**: 2 plans
Plans:
- [x] 03-01-PLAN.md — Adversarial protocol execution with obligation gates, revision loops, and narrative structure
- [ ] 03-02-PLAN.md — Evaluative and exploratory protocol execution with multi-protocol handoff

### Phase 4: Structured Output
**Goal**: Power users can pass `--structured` or `--record` to get typed output matching CUE schemas instead of narrative prose
**Depends on**: Phase 3
**Requirements**: OUTP-02, OUTP-03
**Success Criteria** (what must be TRUE):
  1. User passes `--structured` and receives output in the typed format defined by the selected protocol's CUE output schema — no prose mixed in
  2. User passes `--record` and receives output formatted as a #Record compatible with governance/recording.cue (queryable audit trail format)
**Plans**: 1 plan
Plans:
- [x] 04-01-PLAN.md — Add --structured and --record flag handling with structured JSON output rendering

### Phase 5: Schema Conformance Alignment
**Goal**: SKILL.md instructions exactly match CUE schema definitions so that `--structured` and `--record` output produces valid enum values, correct type references, and accurate tier labels for all 13 protocols
**Depends on**: Phase 4
**Requirements**: EXEC-05, OUTP-02, OUTP-03
**Gap Closure:** Closes gaps from v1.0 audit
**Success Criteria** (what must be TRUE):
  1. CDP terminal path uses `close_as_unified` resolution; ATP terminal path uses `close_as_rejected` — matching their respective CUE schemas
  2. ADP + `--record` flow handles the missing `#Protocol.version` gracefully without producing an invalid `source_run.run_version` value
  3. AAP FragilityMap tier labels in SKILL.md match `#FragilityTier.label` enum values from aap.opt.cue (structural, significant, moderate, minor)
  4. SKILL.md references protocol-specific instance types (`#{ACRONYM}Instance`) instead of non-existent generic `#ProtocolInstance`
**Plans**: 1 plan
Plans:
- [x] 05-01-PLAN.md — Fix all schema-instruction mismatches in SKILL.md

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation | 2/2 | Complete   | 2026-02-28 |
| 2. Routing | 1/1 | Complete    | 2026-02-28 |
| 3. Protocol Execution | 2/2 | Complete   | 2026-02-28 |
| 4. Structured Output | 1/1 | Complete   | 2026-02-28 |
| 5. Schema Conformance | 1/1 | Complete    | 2026-02-28 |

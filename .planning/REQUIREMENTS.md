# Requirements: Socrates

**Defined:** 2026-02-28
**Core Value:** Users get rigorous, protocol-driven reasoning on any problem without needing to know which dialectic method to apply

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Skill Infrastructure

- [ ] **INFRA-01**: Skill registers as `/socrates` slash command in Claude Code with correct SKILL.md frontmatter
- [ ] **INFRA-02**: User sees argument hint when typing `/socrates` showing expected input format
- [ ] **INFRA-03**: Git submodule wired to riverline-labs/dialectics so all .cue files are readable by Claude
- [ ] **INFRA-04**: Supporting files structure loads protocol .cue files on demand (progressive disclosure) rather than inlining all 13
- [ ] **INFRA-05**: Protocol .cue files are optimized for agent context window — comments and non-essential content stripped to minimize token waste

### Routing

- [ ] **ROUT-01**: User describes a problem and the skill automatically selects the correct protocol via governance/routing.cue structural feature matching
- [ ] **ROUT-02**: Output includes which protocol was selected and why (protocol transparency)
- [ ] **ROUT-03**: When routing.cue identifies a composite problem requiring multiple protocols, the skill chains them in sequence (multi-protocol sequencing)

### Protocol Execution

- [ ] **EXEC-01**: Skill can execute all 6 adversarial protocols (CFFP, CDP, CBP, HEP, ATP, EMP) by reading their .cue schemas
- [ ] **EXEC-02**: Skill can execute all 6 evaluative protocols (AAP, IFA, RCP, CGP, PTP, OVP) by reading their .cue schemas
- [ ] **EXEC-03**: Skill can execute the exploratory protocol (ADP) by reading its .cue schema
- [ ] **EXEC-04**: Obligation gates (#ObligationGate) are enforced during adversarial protocol execution — derivation blocked until all obligations satisfied
- [ ] **EXEC-05**: When no candidates survive adversarial pressure, the revision loop (#RevisionLoop) triggers feedback rather than forcing a false conclusion

### Output

- [ ] **OUTP-01**: User receives narrative prose by default explaining routing rationale, protocol execution steps, and conclusion
- [ ] **OUTP-02**: User can pass `--structured` flag to get typed results matching the protocol's CUE output schema instead of narrative
- [ ] **OUTP-03**: User can pass `--record` flag to get output formatted as a #Record compatible with governance/recording.cue (queryable audit trail)

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Distribution

- **DIST-01**: Skill packaged as MCP server for Claude Desktop compatibility
- **DIST-02**: Claude Desktop support with equivalent functionality

### Extensibility

- **EXTN-01**: User can author custom protocols following the CUE schema conventions
- **EXTN-02**: Obligation gate reporting — explicit pass/fail report for each gate in output

## Out of Scope

| Feature | Reason |
|---------|--------|
| CUE runtime execution (`cue eval`) | Claude interprets schemas directly; no toolchain dependency |
| Claude Desktop support | Claude Code only for v1; different installation mechanism |
| Custom protocol authoring | Massive scope expansion; users consume existing 13 protocols |
| Persistent run history/database | Beyond skill scope; users save recording output themselves |
| Web UI or chat interface | Contradicts Claude Code distribution decision |
| Streaming structured output | CUE-typed output must be complete to be valid |
| Protocol selection override | Bypasses routing which is core value; users phrase problems to trigger routing |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| INFRA-01 | — | Pending |
| INFRA-02 | — | Pending |
| INFRA-03 | — | Pending |
| INFRA-04 | — | Pending |
| ROUT-01 | — | Pending |
| ROUT-02 | — | Pending |
| ROUT-03 | — | Pending |
| EXEC-01 | — | Pending |
| EXEC-02 | — | Pending |
| EXEC-03 | — | Pending |
| EXEC-04 | — | Pending |
| EXEC-05 | — | Pending |
| OUTP-01 | — | Pending |
| OUTP-02 | — | Pending |
| INFRA-05 | — | Pending |
| OUTP-03 | — | Pending |

**Coverage:**
- v1 requirements: 16 total
- Mapped to phases: 0
- Unmapped: 16

---
*Requirements defined: 2026-02-28*
*Last updated: 2026-02-28 after initial definition*

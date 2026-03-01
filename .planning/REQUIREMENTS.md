# Requirements: Socrates

**Defined:** 2026-02-28
**Core Value:** Users get rigorous, protocol-driven reasoning on any problem without needing to know which dialectic method to apply

## v1.0 Requirements (Complete)

All v1.0 requirements shipped and verified.

### Skill Infrastructure

- [x] **INFRA-01**: Skill registers as `/socrates` slash command in Claude Code with correct SKILL.md frontmatter
- [x] **INFRA-02**: User sees argument hint when typing `/socrates` showing expected input format
- [x] **INFRA-03**: Git submodule wired to riverline-labs/dialectics so all .cue files are readable by Claude
- [x] **INFRA-04**: Supporting files structure loads protocol .cue files on demand (progressive disclosure) rather than inlining all 13
- [x] **INFRA-05**: Protocol .cue files are optimized for agent context window — comments and non-essential content stripped to minimize token waste

### Routing

- [x] **ROUT-01**: User describes a problem and the skill automatically selects the correct protocol via governance/routing.cue structural feature matching
- [x] **ROUT-02**: Output includes which protocol was selected and why (protocol transparency)
- [x] **ROUT-03**: When routing.cue identifies a composite problem requiring multiple protocols, the skill chains them in sequence (multi-protocol sequencing)

### Protocol Execution

- [x] **EXEC-01**: Skill can execute all 6 adversarial protocols (CFFP, CDP, CBP, HEP, ATP, EMP) by reading their .cue schemas
- [x] **EXEC-02**: Skill can execute all 6 evaluative protocols (AAP, IFA, RCP, CGP, PTP, OVP) by reading their .cue schemas
- [x] **EXEC-03**: Skill can execute the exploratory protocol (ADP) by reading its .cue schema
- [x] **EXEC-04**: Obligation gates (#ObligationGate) are enforced during adversarial protocol execution — derivation blocked until all obligations satisfied
- [x] **EXEC-05**: When no candidates survive adversarial pressure, the revision loop (#RevisionLoop) triggers feedback rather than forcing a false conclusion

### Output

- [x] **OUTP-01**: User receives narrative prose by default explaining routing rationale, protocol execution steps, and conclusion
- [x] **OUTP-02**: User can pass `--structured` flag to get typed results matching the protocol's CUE output schema instead of narrative
- [x] **OUTP-03**: User can pass `--record` flag to get output formatted as a #Record compatible with governance/recording.cue (queryable audit trail)

## v1.1 Requirements

Requirements for plugin distribution milestone. Each maps to roadmap phases.

### Plugin Scaffold

- [ ] **PLUG-01**: User can run `/plugin marketplace add riverline-labs/socrates` to register the marketplace
- [ ] **PLUG-02**: User can run `/plugin install socrates-skill@socrates` to install the plugin from the marketplace
- [x] **PLUG-03**: Plugin manifest (plugin.json) includes name, version, description, author, homepage, repository, and license
- [x] **PLUG-04**: Plugin version in plugin.json follows semver and enables update detection for cached installations

### Path Migration

- [x] **PATH-01**: User can invoke `/socrates` after plugin install and all protocol file reads resolve correctly via `$CLAUDE_PLUGIN_ROOT`
- [x] **PATH-02**: SKILL.md preflight check reads `$CLAUDE_PLUGIN_ROOT/socrates/protocols/dialectics.opt.cue` (not hardcoded `.claude/skills/` path)
- [x] **PATH-03**: All ~18 protocol file references in SKILL.md use `$CLAUDE_PLUGIN_ROOT/socrates/protocols/` prefix

### Build & Distribution

- [x] **BLDG-01**: User can install the plugin without running `git submodule update --init` or any build step
- [x] **BLDG-02**: All 15 pre-built `.opt.cue` files (13 protocols + dialectics + routing) are committed to git and present in the repo
- [x] **BLDG-03**: Developer can run a build command (Makefile) to regenerate `.opt.cue` files from the dialectics submodule

### Session Hook

- [x] **HOOK-01**: User opens a new Claude Code session and the skill context is automatically injected via SessionStart hook
- [x] **HOOK-02**: Session-start hook works on macOS, Linux, and Windows via cross-platform extensionless script (no run-hook.cmd wrapper needed per superpowers pattern evolution)
- [x] **HOOK-03**: Hook scripts use LF line endings enforced by `.gitattributes` to prevent Windows checkout breakage

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Distribution

- **DIST-01**: Skill packaged as MCP server for Claude Desktop compatibility
- **DIST-02**: Claude Desktop support with equivalent functionality

### Extensibility

- **EXTN-01**: User can author custom protocols following the CUE schema conventions
- **EXTN-02**: Obligation gate reporting — explicit pass/fail report for each gate in output

### Plugin Enhancements

- **PLGE-01**: `.claude/settings.json` with `extraKnownMarketplaces` for zero-friction project onboarding
- **PLGE-02**: Multiple plugins listed in marketplace (when riverline-labs builds more tools)

## Out of Scope

| Feature | Reason |
|---------|--------|
| CUE runtime execution (`cue eval`) | Claude interprets schemas directly; no toolchain dependency |
| Claude Desktop support | Claude Code only for v1.1; different installation mechanism |
| Custom protocol authoring | Massive scope expansion; users consume existing 13 protocols |
| Persistent run history/database | Beyond skill scope; users save recording output themselves |
| Web UI or chat interface | Contradicts Claude Code distribution decision |
| Streaming structured output | CUE-typed output must be complete to be valid |
| Protocol selection override | Bypasses routing which is core value; users phrase problems to trigger routing |
| Separate marketplace repo | Single-repo approach chosen; simpler, no sync burden |
| CI/release pipeline for builds | Pre-built files committed directly; no automation needed |
| npm distribution | Git-based install sufficient; npm adds registry publish burden |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| INFRA-01 | Phase 1 | Complete |
| INFRA-02 | Phase 1 | Complete |
| INFRA-03 | Phase 1 | Complete |
| INFRA-04 | Phase 1 | Complete |
| INFRA-05 | Phase 1 | Complete |
| ROUT-01 | Phase 2 | Complete |
| ROUT-02 | Phase 2 | Complete |
| ROUT-03 | Phase 2 | Complete |
| EXEC-01 | Phase 3 | Complete |
| EXEC-02 | Phase 3 | Complete |
| EXEC-03 | Phase 3 | Complete |
| EXEC-04 | Phase 3 | Complete |
| EXEC-05 | Phase 5 | Complete |
| OUTP-01 | Phase 3 | Complete |
| OUTP-02 | Phase 5 | Complete |
| OUTP-03 | Phase 5 | Complete |
| PLUG-01 | Phase 9 | Pending |
| PLUG-02 | Phase 9 | Pending |
| PLUG-03 | Phase 10 | Complete |
| PLUG-04 | Phase 10 | Complete |
| PATH-01 | Phase 10 | Complete |
| PATH-02 | Phase 10 | Complete |
| PATH-03 | Phase 10 | Complete |
| BLDG-01 | Phase 7 | Complete |
| BLDG-02 | Phase 7 | Complete |
| BLDG-03 | Phase 7 | Complete |
| HOOK-01 | Phase 8 | Complete |
| HOOK-02 | Phase 8 | Complete |
| HOOK-03 | Phase 8 | Complete |

**Coverage:**
- v1.0 requirements: 16 total (all complete)
- v1.1 requirements: 13 total
- Mapped to phases: 16 (v1.0) + 13 (v1.1)
- Unmapped: 0

---
*Requirements defined: 2026-02-28*
*Last updated: 2026-03-01 after Phase 8 completion (HOOK-01, HOOK-02, HOOK-03 marked complete)*

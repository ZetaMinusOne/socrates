# Roadmap: Socrates

## Milestones

- ✅ **v1.0 MVP** - Phases 1-5 (shipped 2026-02-28)
- 🚧 **v1.1 Plugin Distribution** - Phases 6-9 (in progress)

## Phases

<details>
<summary>✅ v1.0 MVP (Phases 1-5) - SHIPPED 2026-02-28</summary>

- [x] **Phase 1: Foundation** - Skill registered, submodule wired, progressive disclosure file structure in place (completed 2026-02-28)
- [x] **Phase 2: Routing** - Auto-routing via routing.cue validated with transparent protocol selection (completed 2026-02-28)
- [x] **Phase 3: Protocol Execution** - All 13 protocols executable with narrative output, obligation gates, and revision loop (completed 2026-02-28)
- [x] **Phase 4: Structured Output** - `--structured` and `--record` flags produce typed CUE-schema-compliant output (completed 2026-02-28)
- [x] **Phase 5: Schema Conformance Alignment** - Fix SKILL.md instructions to match actual CUE schema definitions for resolution enums, tier labels, type references, and ADP version field (completed 2026-02-28)

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
- [x] 01-01-PLAN.md — Register skill, wire submodule, create SKILL.md with progressive disclosure
- [x] 01-02-PLAN.md — Strip CUE files and generate optimized protocol files for context budget

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
- [x] 03-02-PLAN.md — Evaluative and exploratory protocol execution with multi-protocol handoff

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

</details>

### 🚧 v1.1 Plugin Distribution (In Progress)

**Milestone Goal:** Make Socrates installable via `/plugin` from a marketplace — single-repo, pre-built protocol files, zero consumer setup.

- [x] **Phase 6: Plugin Scaffold and Path Migration** - Plugin manifest created, directory restructured, all SKILL.md path references migrated to `$CLAUDE_PLUGIN_ROOT` (completed 2026-03-01)
- [x] **Phase 7: Pre-Built Protocol Files** - All 15 `.opt.cue` files committed to git and verified present after a clean plugin install (completed 2026-03-01)
- [x] **Phase 8: Session Hook** - SessionStart hook injects SKILL.md frontmatter as additionalContext on startup/resume/clear; extensionless script with BASH_SOURCE[0] path derivation (completed 2026-03-01)
- [ ] **Phase 9: Marketplace Wiring and End-to-End Validation** - `marketplace.json` published, full install flow verified via `/plugin marketplace add` and `/plugin install`
- [x] **Phase 10: Repository Cleanup and Phase 6 Verification** - Fix submodule gitlink, remove old paths from HEAD, create Phase 6 VERIFICATION.md (gap closure) (completed 2026-03-01)

## Phase Details

### Phase 6: Plugin Scaffold and Path Migration
**Goal**: Users who install the plugin via `--plugin-dir` can invoke `/socrates` and have all protocol file reads resolve correctly — manifest exists, directory structure matches plugin conventions, and every hardcoded path is replaced with `$CLAUDE_PLUGIN_ROOT`
**Depends on**: Phase 5
**Requirements**: PLUG-03, PLUG-04, PATH-01, PATH-02, PATH-03
**Success Criteria** (what must be TRUE):
  1. `plugin.json` exists at `socrates/.claude-plugin/plugin.json` with name, version, description, author, homepage, repository, and license — and the plugin name differs from the marketplace name
  2. `plugin.json` version follows semver and is set only in `plugin.json` (not duplicated in marketplace manifest, which would override it)
  3. User installs via `--plugin-dir ./socrates` and invokes `/socrates <problem>` — the preflight check reads `$CLAUDE_PLUGIN_ROOT/socrates/protocols/dialectics.opt.cue` without a file-not-found error
  4. All ~18 protocol file Read references in SKILL.md use the `$CLAUDE_PLUGIN_ROOT/socrates/protocols/` prefix — zero occurrences of the old `.claude/skills/socrates/` path remain
  5. SKILL.md lives at `socrates/skills/socrates/SKILL.md` and the slash command registers correctly under the plugin namespace
**Plans**: 2 plans
Plans:
- [x] 06-01-PLAN.md — Create plugin manifest, restructure directory, test --plugin-dir path resolution
- [x] 06-02-PLAN.md — Migrate all 24 path references in SKILL.md and verify end-to-end

### Phase 7: Pre-Built Protocol Files
**Goal**: A consumer who installs the plugin gets all 15 protocol files in their plugin cache without running any build step or submodule init — every file Claude needs is committed to git and present after install
**Depends on**: Phase 6
**Requirements**: BLDG-01, BLDG-02, BLDG-03
**Success Criteria** (what must be TRUE):
  1. User installs the plugin (clean cache, no prior setup) and runs `/socrates <problem>` — all protocol files load without any "file not found" or "submodule not initialized" errors
  2. `git ls-files socrates/protocols/ | wc -l` returns 15 (13 protocol files + dialectics.opt.cue + routing.opt.cue)
  3. Developer runs `make build` (or equivalent) and the 15 `.opt.cue` files are regenerated from the `dialectics/` submodule via `scripts/strip_cue.py`
**Plans**: 1 plan
Plans:
- [x] 07-01-PLAN.md — Regenerate and commit 15 pre-built protocol files, add make check staleness target, track build infrastructure

### Phase 8: Session Hook
**Goal**: Users who open a new Claude Code session, resume a session, or run `/clear` have the Socrates skill context automatically available — no manual invocation required to prime the session
**Depends on**: Phase 7
**Requirements**: HOOK-01, HOOK-02, HOOK-03
**Success Criteria** (what must be TRUE):
  1. After plugin install, running `/clear` in Claude Code causes the SessionStart hook to fire and inject SKILL.md content as `additionalContext` — Claude responds to `/socrates` without needing to read SKILL.md manually
  2. The hook executes correctly on macOS, Linux, and Windows via the `run-hook.cmd` polyglot dispatcher calling an extensionless `session-start` script
  3. All shell scripts in `socrates/hooks/` have LF line endings enforced by `.gitattributes` — no CRLF contamination on Windows checkout
**Plans**: 1 plan
Plans:
- [x] 08-01-PLAN.md — Create SessionStart hook files (hooks.json, session-start script, .gitattributes) and verify correctness

### Phase 9: Marketplace Wiring and End-to-End Validation
**Goal**: Any user can install Socrates with two commands — add the marketplace and install the plugin — and get a fully working skill with zero additional setup
**Depends on**: Phase 8
**Requirements**: PLUG-01, PLUG-02
**Success Criteria** (what must be TRUE):
  1. User runs `/plugin marketplace add riverline-labs/socrates` and the marketplace is registered in Claude Code
  2. User runs `/plugin install socrates-skill@socrates` (or the confirmed correct invocation form) and the plugin installs cleanly — no submodule init, no build step, no manual path configuration
  3. After a real GitHub-sourced install (not `--plugin-dir`), user runs `/socrates <problem>` and receives a complete narrative response with correct protocol routing and execution
  4. After the same install, user runs `/socrates --record <problem>` and the `$CLAUDE_PLUGIN_ROOT/dialectics/governance/recording.cue` file is readable and `--record` output is valid
**Plans**: TBD

### Phase 10: Repository Cleanup and Phase 6 Verification
**Goal**: Repository state is clean for downstream phases — submodule gitlink registered at correct path, old paths removed from HEAD, and Phase 6 requirements formally verified so they count as satisfied
**Depends on**: Phase 7
**Requirements**: PLUG-03, PLUG-04, PATH-01, PATH-02, PATH-03
**Gap Closure:** Closes INTEG-01, INTEG-02, and verification gaps from v1.1 audit
**Success Criteria** (what must be TRUE):
  1. `git ls-files --stage socrates/dialectics` returns a gitlink entry (mode 160000) — fresh `git clone && git submodule update --init` succeeds
  2. `git status` shows no unstaged deletes under `.claude/skills/socrates/` — all 18 old paths removed from HEAD via `git rm`
  3. VERIFICATION.md exists for Phase 6 confirming PLUG-03, PLUG-04, PATH-01, PATH-02, PATH-03 are satisfied (cross-referenced with SUMMARY frontmatter and UAT results)
  4. ROADMAP.md progress table accurately reflects Phase 6 plan execution status
**Plans**: 1 plan
Plans:
- [x] 10-01-PLAN.md — Fix git index, create Phase 6 VERIFICATION.md, update ROADMAP progress

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6 → 7 → 10 → 8 → 9
(Phase 10 is a gap closure phase that must execute before Phase 8 — fixes repository state Phase 8/9 depend on)

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Foundation | v1.0 | 2/2 | Complete | 2026-02-28 |
| 2. Routing | v1.0 | 1/1 | Complete | 2026-02-28 |
| 3. Protocol Execution | v1.0 | 2/2 | Complete | 2026-02-28 |
| 4. Structured Output | v1.0 | 1/1 | Complete | 2026-02-28 |
| 5. Schema Conformance | v1.0 | 1/1 | Complete | 2026-02-28 |
| 6. Plugin Scaffold and Path Migration | v1.1 | 2/2 | Complete | 2026-03-01 |
| 7. Pre-Built Protocol Files | v1.1 | 1/1 | Complete | 2026-03-01 |
| 8. Session Hook | v1.1 | 1/1 | Complete | 2026-03-01 |
| 9. Marketplace Wiring and E2E Validation | v1.1 | 0/? | Not started | - |
| 10. Repository Cleanup and Phase 6 Verification | v1.1 | Complete    | 2026-03-01 | 2026-03-01 |

# Project Research Summary

**Project:** Socrates — Claude Code dialectic reasoning skill
**Domain:** Claude Code custom skill — CUE-schema-driven dialectic reasoning protocol executor
**Researched:** 2026-02-28
**Confidence:** HIGH

## Executive Summary

Socrates is a Claude Code skill that gives users a `/socrates` slash command to apply structured dialectic reasoning protocols to any problem. The skill auto-routes user problems to one of 13 CUE-schema-defined protocols (adversarial, evaluative, or exploratory) drawn from the `riverline-labs/dialectics` framework, then executes the selected protocol faithfully, producing narrative prose by default and typed structured output when the `--structured` flag is passed. The canonical implementation uses a single `SKILL.md` entrypoint with YAML frontmatter, the dialectics repo referenced as a git submodule, and progressive disclosure — Claude loads only the selected protocol file rather than all 13 upfront, keeping well within Claude Code's 16,000-character skill context budget.

The recommended approach is deterministic and dependency-ordered: submodule setup before any skill logic, routing integration before any protocol execution, one validated protocol before all thirteen. The CUE files are interpreted by Claude as structured behavioral specifications — no CUE binary or toolchain is required at runtime, keeping the skill zero-dependency. The key architectural bet is that schema-constrained execution with explicit obligation gates produces more rigorous reasoning than freeform prompting, and that auto-routing removes the barrier of knowing which protocol to apply.

The primary risks are protocol fidelity drift (Claude narrating about a protocol instead of executing it), silent skill exclusion from context budget overflow, and routing overconfidence (wrong protocol selected without visible rationale). All three are preventable with well-established patterns: explicit execution checklists in SKILL.md, progressive disclosure file structure, and mandatory routing transparency before protocol execution begins. Research confidence is HIGH across all four areas — official Anthropic documentation, direct dialectics repo inspection, and official CUE language specs were primary sources.

## Key Findings

### Recommended Stack

The skill requires no traditional software stack. The entire implementation is a set of markdown and CUE files, a YAML frontmatter config in SKILL.md, and a git submodule. Claude Code's skill system handles invocation, context loading, and tool access. The only version constraint that matters is Claude Code >= 2.0.76, which is when submodule file read support was confirmed.

**Core technologies:**
- `SKILL.md` (Claude Code Skills format): Skill entrypoint and `/socrates` command registration — the only format with `argument-hint`, `allowed-tools`, `disable-model-invocation`, and supporting file references; supersedes legacy `.claude/commands/` format
- YAML frontmatter: Embeds skill metadata directly in SKILL.md; `disable-model-invocation: true` is required to prevent Claude from auto-triggering heavyweight protocol execution mid-conversation
- CUE files via git submodule: `riverline-labs/dialectics` provides all 13 protocol schemas and governance files; submodule keeps them in sync without copy drift; no CUE toolchain needed at runtime — Claude reads `.cue` files as structured specifications
- Supporting files (`routing-guide.md`, `protocols/README.md`): Reduce context pressure by providing navigable human-readable companions to the raw CUE files; loaded on-demand

See `.planning/research/STACK.md` for full rationale and installation commands.

### Expected Features

The feature research confirms a tight MVP definition. All P1 features cluster around the core loop: submodule setup → SKILL.md skeleton → routing → protocol execution → narrative output → revision loop. This loop is the entire product hypothesis and must be validated before any differentiating features are added.

**Must have (table stakes):**
- `/socrates` slash command — the entire UX entry point; nothing works without it
- Free-form problem input via `$ARGUMENTS` — users describe problems in natural language
- Auto-routing via `governance/routing.cue` — users must not need to know protocol names
- Protocol execution for all 13 protocols — core promise; incomplete coverage breaks trust
- Narrative output by default — readable prose explaining reasoning process and conclusion
- Obligation gate enforcement — anti-hallucination mechanism; skipping it breaks protocol fidelity
- Revision loop execution — zero-survivor feedback loop must execute rather than force false conclusions
- Git submodule wired to riverline-labs/dialectics — .cue files must be accessible

**Should have (competitive differentiators):**
- Protocol transparency in output — show which protocol was selected and why; builds trust and is required for debugging routing failures
- Structured output flag (`--structured`) — typed output matching CUE schema; turns the skill into a structured reasoning API for power users
- Recording schema output — produces `#Record`-compatible structured output for audit trails
- Multi-protocol sequencing — `routing.cue` can return chained protocols; executing sequences handles composite problems

**Defer (v2+):**
- Obligation gate reporting (explicit pass/fail per gate — useful for debugging, not typical use)
- MCP packaging (only if users need Claude Desktop or other tool contexts)
- Custom protocol authoring (explicit anti-feature per PROJECT.md; scope expansion without clear demand)
- Persistent run history / database (requires storage layer; out of scope for a Claude Code skill)

See `.planning/research/FEATURES.md` for prioritization matrix and anti-features analysis.

### Architecture Approach

The architecture is a four-layer prompt-driven pipeline with no persistent state and no runtime dependencies beyond Claude Code itself. The layers are: (1) skill entry point (SKILL.md), (2) routing layer (routing.cue), (3) protocol execution layer (individual .cue files loaded on-demand), and (4) output layer (narrative or structured). All communication between layers is in-context reasoning — Claude reads a file, extracts structured information, and applies it as behavioral constraints on the next step.

**Major components:**
1. `SKILL.md` — Registers the skill, controls invocation, instructs output mode detection, and issues explicit `Read` directives for all downstream files; must stay under 500 lines
2. `governance/routing.cue` — Maps 14 structural problem features to 13 protocols with confidence scores and sequencing rules; mandatory first read on every invocation
3. `dialectics.cue` (kernel) — Defines shared primitives (`#Rebuttal`, `#Challenge`, `#ObligationGate`, `#RevisionLoop`, `#Derivation`, `#Finding`); must be read before any protocol file
4. Protocol `.cue` files (13, loaded one at a time) — Phase-by-phase execution schema; read only after routing selects the relevant protocol
5. `governance/recording.cue` — Standardizes completed runs into queryable records; applied after execution; required for structured output mode

The governing architectural pattern is **progressive disclosure**: SKILL.md references files rather than inlining them; Claude loads only what the current invocation needs. This directly prevents the silent skill exclusion pitfall caused by exceeding the 16,000-character context budget.

See `.planning/research/ARCHITECTURE.md` for data flow diagrams and anti-patterns.

### Critical Pitfalls

Six critical pitfalls were identified. All are preventable if the implementation follows the dependency order the architecture research specifies. The first three are the ones most likely to silently produce a broken-looking result rather than an obvious error.

1. **Protocol fidelity drift** — Claude narrates about protocols instead of executing them. Prevent by writing explicit execution checklists in SKILL.md for every schema construct (what to DO, not what the field IS), and by including worked example traces in `examples/` before building all 13 protocols.

2. **Skill token budget overflow** — SKILL.md grows beyond 500 lines or total skill content exceeds 16,000 characters, causing silent skill exclusion. Prevent by establishing progressive disclosure from day one — never inline protocol content in SKILL.md. Verify with `/context` after each protocol is added.

3. **Routing overconfidence** — Wrong protocol selected silently, producing rigorous-but-irrelevant output. Prevent by making routing an explicit, visible step: always show which protocol was selected and why before execution begins. Build routing before any full protocol execution so it can be tested independently.

4. **Git submodule initialization gap** — The dialectics submodule directory is empty after clone; skill silently degrades. Prevent with a preflight check in SKILL.md referencing a specific CUE file path, a setup script, and prominent README documentation.

5. **CUE schema misreading** — Claude treats CUE constraints as documentation rather than behavioral contracts. Prevent by explicitly translating each CUE schema into plain-language rules alongside the schema reference (e.g., "The `position` field MUST be exactly 'plaintiff' or 'defendant'").

6. **Structured output non-compliance** — `--structured` flag partially honored; output mixes prose with schema fields. Prevent by building narrative mode first, stabilizing it, then adding structured mode with exact output templates marked `ALWAYS use this exact template structure`.

See `.planning/research/PITFALLS.md` for recovery strategies and the phase-to-pitfall mapping.

## Implications for Roadmap

The dependency graph from architecture research directly maps to a 4-phase implementation order. No phase can begin before the previous one is validated — this is a strict linear dependency chain, not a parallel build.

### Phase 1: Foundation — Submodule, SKILL.md Skeleton, and File Structure

**Rationale:** Everything else depends on the dialectics files being accessible and SKILL.md being structurally correct. This phase has no creative decisions — it is mechanical setup with a clear pass/fail outcome. Build-order research confirms this must come first.

**Delivers:** A working `.claude/skills/socrates/` directory with SKILL.md registered, the dialectics submodule initialized, all file paths confirmed readable by Claude via the Read tool, and the progressive disclosure structure established.

**Addresses:** Table-stakes features — `/socrates` command, git submodule, SKILL.md frontmatter, supporting files structure.

**Avoids:** Skill token budget overflow (progressive disclosure established from day one), submodule initialization gap (preflight check baked in from the start).

**Research flag:** Standard patterns — Claude Code skill setup is well-documented; no additional research needed.

### Phase 2: Routing Integration

**Rationale:** Routing must be validated independently before any protocol execution is attempted. Architecture research explicitly flags routing as an intermediate result that must be observable. A wrong routing decision invalidates all subsequent protocol work.

**Delivers:** Claude correctly reads `governance/routing.cue`, extracts the 14 structural features from user problem text, selects a primary protocol with a one-sentence rationale, and surfaces the routing decision visibly before any protocol is loaded. Test matrix: at least 13 test inputs covering all protocol types.

**Addresses:** Auto-routing, protocol transparency (routing rationale in output).

**Avoids:** Routing overconfidence (transparent routing decision), invisible routing (must appear before execution).

**Research flag:** Needs light validation — routing.cue's 14 structural features and their protocol mappings should be manually verified against several real problems before committing to the routing logic.

### Phase 3: Protocol Execution — One Protocol End-to-End, Then All 13

**Rationale:** Start with one representative protocol (CDP or CFFP per architecture research) to validate the full execution pattern: read kernel → read protocol → execute phases → enforce obligation gates → execute revision loop → produce narrative output. Once this pattern is proven, the remaining 12 protocols follow the same structure with no new infrastructure.

**Delivers:** All 13 protocols executable via `/socrates`, each producing narrative output with: routing rationale, protocol phase execution trace, obligation gate check results, and final conclusion. Revision loop executes when no survivors emerge.

**Addresses:** Protocol execution (all 13), narrative output, obligation gate enforcement, revision loop execution.

**Avoids:** Protocol fidelity drift (execution checklists and worked examples established in first protocol, applied to all 13), CUE schema misreading (plain-language translations written alongside schema references).

**Research flag:** Needs research for Phase 3 planning — protocol execution fidelity testing for each of the 13 protocols requires protocol-specific knowledge. Consider a targeted research spike on the 6 adversarial protocols (most complex: multi-round challenge-rebuttal cycles) before building them.

### Phase 4: Structured Output and Recording

**Rationale:** Architecture research and pitfall research are unambiguous: do not build structured output simultaneously with narrative output. Narrative mode must be stable before structured output is layered on top. This phase is a post-validation addition, not a parallel track.

**Delivers:** `--structured` flag parses from `$ARGUMENTS`, switches output to typed format matching each protocol's CUE output schema, `recording.cue` applied to produce `#Record`-compatible run records. Output templates verified against all 13 protocol schemas.

**Addresses:** Structured output flag, recording schema output, `--structured` argument hint.

**Avoids:** Narrative vs. structured output non-compliance (explicit output templates, sequential not concurrent build).

**Research flag:** Standard patterns — structured output template approach is well-documented in Anthropic skill best practices; no additional research needed.

### Phase Ordering Rationale

- **Linear, not parallel:** Every phase depends on the previous one's validation. Routing cannot be tested without the submodule; protocol execution cannot be built without routing; structured output cannot be validated without narrative protocol execution.
- **Validate before expanding:** Architecture research is explicit — build one protocol to pattern, then replicate. The 13 protocols are not 13 independent tasks; they are one pattern times 13.
- **Pitfall prevention by phase:** The three most dangerous pitfalls (fidelity drift, token overflow, routing overconfidence) are all prevented in Phases 1-2, before any protocol content is written.
- **MVP is Phases 1-3:** Phase 4 is a validated enhancement, not a launch requirement. Narrative mode is the default and the core promise.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 3:** Adversarial protocol execution semantics — the 6 adversarial protocols (ATP, CBP, CDP, CFFP, EMP, HEP) each have multi-round challenge-rebuttal cycles; research their phase structures and distinguish them from single-pass evaluative protocols before building
- **Phase 2:** Routing boundary cases — routing.cue's 14 structural features may overlap for some problem types; test the discrimination logic against ambiguous inputs before committing to the routing implementation

Phases with standard patterns (skip research-phase):
- **Phase 1:** Claude Code skill setup is well-documented via official Anthropic docs and has been verified against official examples
- **Phase 4:** Structured output template approach follows established Anthropic skill best practices; no novel patterns needed

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Official Claude Code skills documentation, live dialectics repo inspection, official CUE language spec — all primary sources |
| Features | HIGH | Official Claude Code docs + direct inspection of routing.cue, recording.cue, dialectics.cue — no inference required |
| Architecture | HIGH | Component boundaries match official skills architecture; data flow verified against known Claude Code skill behavior |
| Pitfalls | HIGH | Official Anthropic skill authoring best practices, official GitHub issues (skill exclusion, submodule), official CUE docs — majority of pitfalls sourced from HIGH-confidence references |

**Overall confidence:** HIGH

### Gaps to Address

- **Routing boundary precision:** routing.cue's 14 structural features are documented in the file, but the exact discrimination logic between closely-related protocols (e.g., CBP vs. CDP for certain problem types) needs empirical testing during Phase 2, not just spec reading.
- **Protocol execution fidelity at scale:** Research confirms the execution pattern for CUE-as-spec interpretation, but whether Claude consistently follows multi-phase adversarial protocols without fidelity drift depends on the quality of execution checklists written in Phase 3. This is a quality-of-authorship gap, not a research gap — resolved by building and testing, not more research.
- **Submodule commit pinning:** Research recommends pinning the submodule to a specific commit rather than tracking a branch. The correct commit to pin to (stable v0.2.1 of dialectics) should be confirmed against the upstream repo during Phase 1 setup.

## Sources

### Primary (HIGH confidence)
- [Claude Code Skills Official Docs](https://code.claude.com/docs/en/skills) — SKILL.md format, frontmatter reference, invocation control, supporting files, context budget
- [riverline-labs/dialectics GitHub](https://github.com/riverline-labs/dialectics) — Protocol structure, .cue file organization, governance files
- [governance/routing.cue](https://raw.githubusercontent.com/riverline-labs/dialectics/main/governance/routing.cue) — RoutingInput/RoutingResult schema, 14 structural features, protocol mapping
- [governance/recording.cue](https://raw.githubusercontent.com/riverline-labs/dialectics/main/governance/recording.cue) — #Record schema
- [dialectics.cue](https://raw.githubusercontent.com/riverline-labs/dialectics/main/dialectics.cue) — Kernel primitives
- [protocols/adversarial/cffp.cue](https://raw.githubusercontent.com/riverline-labs/dialectics/main/protocols/adversarial/cffp.cue) — CUE syntax patterns
- [Anthropic Skill Authoring Best Practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices) — Workflow checklists, token budget, output validation
- [Anthropic official skills examples](https://github.com/anthropics/skills) — Canonical skill structure reference
- [CUE Language Specification](https://cuelang.org/docs/reference/spec/) — Type system semantics

### Secondary (MEDIUM confidence)
- [Claude Code Issue #7852](https://github.com/anthropics/claude-code/issues/7852) — Git submodule read support confirmed in v2.0.76+
- [Claude Code Issue #13586](https://github.com/anthropics/claude-code/issues/13586) — Silent skill exclusion on naming conflicts confirmed
- [Anthropic Engineering: Agent Skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills) — Context window budget details
- [Claude Agent Skills deep dive — Lee Hanchung](https://leehanchung.github.io/blogs/2025/10/26/claude-skills-deep-dive/) — Internal architecture analysis verified against official docs
- [Custom Commands and Skills Errors — SFEIR Institute](https://institute.sfeir.com/en/claude-code/claude-code-custom-commands-and-skills/errors/) — Community-verified error catalog
- [Git Submodule Pitfalls — Porteneuve/Medium](https://medium.com/@porteneuve/mastering-git-submodules-34c65e940407) — Documented submodule failure modes

### Tertiary (LOW confidence)
- [LLM Hallucination in Multi-Step Agents](https://medium.com/@faryalriz9/how-to-build-multi-step-llm-agents-that-dont-hallucinate-b45b33baa043) — LLM error propagation in multi-step protocols; consistent with higher-confidence sources
- [Reasoning Prompt Engineering Techniques 2025 — Adaline Labs](https://labs.adaline.ai/p/reasoning-prompt-engineering-techniques) — LLM reasoning failure mode context

---
*Research completed: 2026-02-28*
*Ready for roadmap: yes*

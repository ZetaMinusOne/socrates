# Pitfalls Research

**Domain:** Claude Code skill — LLM structured reasoning with schema interpretation (CUE)
**Researched:** 2026-02-28
**Confidence:** HIGH (Anthropic official docs verified + multiple independent sources)

---

## Critical Pitfalls

### Pitfall 1: Protocol Fidelity Drift — Claude Narrates Instead of Executes

**What goes wrong:**
Claude reads the CUE schema, understands its structure, then produces a narrative that _describes_ the protocol rather than _executing_ it. Output says "Step 1 involves challenging the premise..." instead of actually performing the challenge, deriving outputs, tracking obligations, and surfacing a structured conclusion. The skill reads like a summary of a dialectic rather than the result of one.

**Why it happens:**
CUE schemas describe data shapes, not imperative procedures. When Claude encounters `challenge: string` in a CUE struct, it knows to produce a challenge, but without explicit instruction on what "executing a challenge cycle" means in practice, Claude pattern-matches to explanation mode — its default register for unfamiliar technical content. The skill prompt is a schema, not a runbook.

**How to avoid:**
The SKILL.md must not just reference the CUE files — it must include explicit execution semantics for each schema construct. For every CUE field type (rebuttal, obligation gate, derivation, revision loop), write what Claude must _do_, not just what the field _is_. Use workflow checklists (per Anthropic best practices) so Claude tracks protocol execution step-by-step rather than summarizing it. Include worked examples in `examples/` with protocol traces showing input → intermediate steps → conclusion.

**Warning signs:**
- Output contains phrases like "the protocol would..." or "according to this framework..."
- Conclusion appears before working through all protocol phases
- Rebuttal/challenge cycles missing or collapsed into a single paragraph
- Structured output flag returns fields that are empty or minimally populated

**Phase to address:** Protocol foundation phase — the very first working protocol built must demonstrate full execution fidelity, not just structural output. Add a validation test: does the output contain all required CUE output fields with non-trivial content?

---

### Pitfall 2: Routing Overconfidence — Wrong Protocol Selected Silently

**What goes wrong:**
The auto-router (via `governance/routing.cue`) picks a protocol that doesn't match the problem type. An evaluative problem gets routed to adversarial (or vice versa). Claude executes the wrong protocol correctly and confidently, producing a rigorous but irrelevant result. The user has no visibility into why a particular protocol was chosen.

**Why it happens:**
Protocol routing requires interpreting problem semantics against protocol signatures. LLMs struggle to distinguish task difficulty and problem type from surface-level phrasing — research confirms models "fail to distinguish between straightforward and challenging instances" and that "perceived difficulty varies across LLMs." The routing logic is defined in CUE (a constraint language), but Claude is interpreting it as a semantic document, not running it as a constraint solver.

**How to avoid:**
Treat routing as an explicit, transparent, auditable step — not a background decision. The skill must:
1. Show the user which protocol was selected and why (one-sentence rationale)
2. Offer correction opportunity before full execution begins
3. Include protocol signatures with clear discriminating criteria (what types of problems each handles)
4. Test routing against boundary cases: ambiguous problems that could go either way

Do not let routing be a silent preprocessing step. Make it visible.

**Warning signs:**
- User feedback that conclusions feel "off" or "not what I was asking"
- Protocol names appearing in output that don't match problem framing
- Exploratory problems being routed to adversarial protocols (most common mismatch)
- No rationale text accompanying protocol selection

**Phase to address:** Routing implementation phase. Build routing before any full protocol execution so it can be validated independently.

---

### Pitfall 3: Skill Prompt Token Bloat — Silent Skill Exclusion

**What goes wrong:**
The SKILL.md grows too large (or the total skill budget is exceeded) and Claude Code silently excludes the skill from context. The `/socrates` command appears to do nothing, or Claude responds as if it has no special instructions. This is a silent failure — no error is shown.

**Why it happens:**
Anthropic enforces a character budget for skills: 2% of context window, with a 16,000 character fallback. If total loaded skill content exceeds this, skills are dropped without warning. With 13 protocols, governance files, and CUE schema references, the naive approach of loading everything up front will routinely exceed this limit.

**How to avoid:**
Use progressive disclosure architecture from day one:
- `SKILL.md` stays under 500 lines (per Anthropic official docs) — contains only routing logic, protocol names/descriptions, and pointers
- Each protocol lives in its own file (`protocols/CFFP.md`, `protocols/AAP.md`, etc.) and is loaded only when that protocol is selected
- CUE schema files are referenced, not inlined
- Run `/context` during development to check the skill budget warning

**Warning signs:**
- `/socrates` produces generic Claude behavior (no protocol structure)
- `/context` shows a budget warning or excluded skills
- SKILL.md file exceeds 500 lines
- All 13 protocol descriptions inlined into a single file

**Phase to address:** Skill architecture phase (Phase 1). File layout decisions made early determine whether this problem occurs at all. Never revisit by inlining — establish progressive disclosure as the foundational pattern.

---

### Pitfall 4: Git Submodule Initialization Gap — CUE Files Not Present

**What goes wrong:**
The project clones correctly but the `riverline-labs/dialectics` submodule directory is empty. The skill references CUE files that don't exist. Claude either errors or silently ignores the missing schema context and produces generic output.

**Why it happens:**
Git submodules are not automatically initialized on clone. `git clone <repo>` leaves submodule directories empty. Contributors who don't know about `--recurse-submodules` or the separate `git submodule update --init` step will have a broken setup. This is the #1 documented submodule pitfall across the ecosystem.

**How to avoid:**
- Document the required setup command prominently in the skill's README and SKILL.md itself
- Add a setup script or Makefile target that runs `git submodule update --init --recursive`
- In SKILL.md, include a preflight check that references a specific CUE file path and fails gracefully with a clear message if the file is missing: "Submodule not initialized. Run: git submodule update --init --recursive"
- Pin the submodule to a specific commit, not a branch, to prevent upstream changes from silently changing protocol semantics

**Warning signs:**
- `dialectics/` directory exists but is empty
- File read commands on CUE paths return "not found"
- `git submodule status` shows `-` prefix (not initialized) rather than `+` or ` `

**Phase to address:** Project setup / Phase 1. This must be documented and verified before any protocol work begins.

---

### Pitfall 5: CUE Schema Misreading — Constraints Treated as Documentation

**What goes wrong:**
CUE uses a lattice-based type system where types and values unify. Claude may interpret a CUE constraint like `position: "plaintiff" | "defendant"` as documentation of possible values rather than a hard constraint on the protocol execution. Claude then produces output that uses different field names, skips enum enforcement, or ignores disjunctions.

**Why it happens:**
CUE is a superset of JSON with significantly different semantics — especially around value unification, constraints, and disjunctions. Claude's training includes CUE knowledge but the CUE semantic model (graph unification based on NLP techniques from the 90s) is not the same as JSON Schema, TypeScript types, or other schema systems Claude sees more frequently. The risk of semantic drift is high when interpreting unfamiliar type system semantics as prose.

**How to avoid:**
Do not rely on Claude inferring CUE constraint semantics from the CUE files alone. In SKILL.md (or per-protocol files), explicitly translate each CUE schema into plain-language rules:
- "The `position` field must be exactly 'plaintiff' or 'defendant' — no other values"
- "The `rebuttal` struct requires ALL of: claim, counter-argument, and burden-shift"
- "Obligation gates must be checked in sequence before proceeding to next phase"

Provide example CUE struct instances showing valid completed protocol runs alongside the schema definitions.

**Warning signs:**
- Output fields that don't match CUE schema field names exactly
- Missing required fields in structured output
- Position/role constraints ignored (both sides of adversarial treated as same voice)
- Disjunctive types collapsed (only one option ever used regardless of context)

**Phase to address:** Protocol foundation phase. Before implementing all 13 protocols, build and test one protocol (e.g., CDP) with explicit CUE translation in the skill files to establish the pattern.

---

### Pitfall 6: Narrative vs. Structured Output Flag Not Enforced

**What goes wrong:**
The structured output flag (`--structured` or equivalent) is supposed to switch from narrative to typed output matching CUE schemas. In practice, Claude partially honors the flag — it may use some schema fields but include prose, add unrequested commentary, or produce output that fails to parse as the expected format.

**Why it happens:**
Structured output in a skill context relies entirely on prompt instruction-following, not programmatic schema enforcement. As documented in Claude's own skill best practices: "output validation relies entirely on Claude's instruction-following — notoriously unreliable for consistency." There is no grammar-constrained generation in a skill context (unlike the Claude API's structured output feature which compiles JSON schemas into generation grammars).

**How to avoid:**
- Define exact output templates in the skill files for structured mode, with zero ambiguity about format
- Mark the structured output section with `ALWAYS use this exact template structure:` (per Anthropic's "strict requirements" template pattern)
- Test structured output against all 13 protocol output schemas independently
- Consider using a validator step: after producing structured output, Claude checks each required field is present and non-empty before returning
- For the MVP, define structured output as a subset of the CUE schema (the most critical fields) rather than the full schema — reduces drift surface

**Warning signs:**
- Structured output contains prose paragraphs mixed with schema fields
- Missing required schema fields in structured output
- Field values that are plausible but not matching the schema type (e.g., array returned where string expected)
- Structured output format changes between invocations for the same input

**Phase to address:** Structured output phase (after narrative mode is stable). Do not build both modes simultaneously — get narrative mode right first, then layer structured output on top.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Inline all 13 protocol descriptions in SKILL.md | Simpler file structure | Exceeds skill token budget, silently excluded | Never — use progressive disclosure from day one |
| Copy CUE files into skill directory instead of submodule | Avoids submodule complexity | Schema drift from upstream, manual sync debt | Never — use the submodule as specified |
| Skip routing transparency (silent protocol selection) | Faster execution path | Wrong protocols silently chosen, no debugging surface | Never — routing must be visible |
| Use informal protocol descriptions instead of translating CUE constraints | Easier to write | Claude interprets loosely, protocol fidelity degrades | Only acceptable in exploration spike, not in production skill |
| Hardcode routing decision in SKILL.md prose instead of following routing.cue | Simpler to implement | Does not stay in sync with upstream governance changes | Never — read routing.cue directly |
| Build narrative and structured output simultaneously | Ship both features at once | Neither mode tested properly, schema compliance issues | Never — sequential is required |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| git submodule (dialectics) | Referencing CUE files without verifying submodule is initialized | Add preflight check in SKILL.md; document init command prominently |
| CUE schema files | Reading `.cue` files and treating constraint syntax as JSON-like documentation | Translate each schema field into explicit plain-language execution rules alongside the CUE reference |
| governance/routing.cue | Ignoring routing.cue and writing ad hoc routing logic in SKILL.md prose | Read routing.cue to understand the routing criteria; implement routing following those criteria |
| governance/recording.cue | Skipping recording entirely (out of scope for MVP) | Confirm recording is explicitly out of scope; document what is deferred to avoid confusion |
| Claude Code skill directory | Placing skill files in `.claude/commands/` (older pattern) | Use `.claude/skills/socrates/SKILL.md` structure; commands and skills are unified but skills support supporting files |
| Multiple CUE protocol files | Loading all 13 protocol files at skill startup | Load only the selected protocol file after routing decision |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Front-loading all 13 protocol schemas | Skill silently excluded from context; `/socrates` produces generic output | Progressive disclosure: load only routed protocol | Immediately — exceeds 16,000 char budget |
| Long SKILL.md with all protocol descriptions | Slow initial context load; budget exceeded | Keep SKILL.md under 500 lines; one file per protocol | First time a second user tries the skill |
| Deeply nested CUE file references | Claude reads partial files via `head -100`; misses constraint definitions | Keep reference structure one level deep from SKILL.md | Whenever Claude navigates multi-hop references |
| No reasoning boundary between phases | Protocol phases bleed together; early mistakes compound into garbage conclusions | Use explicit phase completion markers and checklists | Immediately visible in any multi-phase adversarial protocol |
| Routing executes full protocol before confirming selection | Wrong protocol runs to completion, wasting context | Two-step: select and confirm, then execute | Every time routing gets it wrong (which will be often at first) |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Invisible protocol selection | User doesn't know which protocol ran; can't evaluate fitness | Show selected protocol and one-sentence rationale before execution |
| No correction opportunity before execution | Wrong protocol wastes a full context turn | After routing, pause and confirm before executing (or make it skipable with a flag) |
| Raw CUE field names in output | Output reads like machine output; non-expert users confused | Map CUE field names to human-readable labels in narrative mode |
| Structured output by default | Power feature presented first; casual users alienated | Narrative default (per PROJECT.md decision); structured output behind explicit flag |
| No progress indication on long protocols | Adversarial protocols with multiple rebuttal cycles appear stuck | Use phase headers in output so user can see progression |
| `/socrates` works differently each invocation | Undoes user trust in the tool | Deterministic routing and structured phase execution required |

---

## "Looks Done But Isn't" Checklist

- [ ] **Protocol execution:** Verify output contains ALL required CUE output fields, not just some — check schema against output field by field
- [ ] **Routing:** Verify routing covers all 13 protocols, not just the most common types — test with edge cases like ADP (exploratory) routing
- [ ] **Narrative output:** Verify narrative mode explains _what the reasoning process was_, not just _what the conclusion is_ — the process is the value
- [ ] **Structured output flag:** Verify flag actually changes output structure and that all schema fields are present — parse the output programmatically in tests
- [ ] **Submodule sync:** Verify CUE files read by the skill are from the submodule, not a stale copy — check file paths point into `dialectics/`
- [ ] **Token budget:** Run `/context` and verify no skills are excluded after loading all 13 protocol files into the session
- [ ] **Adversarial protocols:** Verify challenge-rebuttal cycles actually cycle — multi-round adversarial protocols are not the same as single-pass evaluative ones
- [ ] **Obligation gates:** Verify obligation gates are checked and block progression when not satisfied — they are not optional commentary

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Protocol fidelity drift discovered in prod | HIGH | Audit all protocol SKILL.md files; add explicit execution checklists; re-test all 13 protocols |
| Skill token budget exceeded | LOW | Split protocol files; verify with `/context`; no re-architecture needed |
| Submodule not initialized for users | LOW | Add setup script; update documentation; add preflight check in SKILL.md |
| Wrong protocol selected (routing failure) | MEDIUM | Add routing transparency; build test set of routing examples across all 13 protocols; iterate on routing logic |
| CUE schema misread discovered | MEDIUM | Add explicit CUE-to-plain-English translation for each affected protocol; re-test structured output compliance |
| Narrative vs. structured output mode confusion | LOW | Enforce explicit template in skill; add structured output validation loop |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Protocol fidelity drift | Phase 1 (first protocol built) | Protocol trace shows all phase markers; output fields match schema |
| Routing overconfidence | Phase 2 (routing implementation) | Test matrix: 13 problems × 13 protocols; check routing decisions |
| Skill token bloat | Phase 1 (architecture) | Run `/context` after each protocol added; no budget warnings |
| Submodule initialization gap | Phase 1 (project setup) | Fresh clone test: does the skill work without additional steps? |
| CUE schema misreading | Phase 1 (first protocol) | Compare CUE schema field list to actual output field list |
| Structured output non-compliance | Phase N (structured output feature) | Parse structured output with JSON parser; check required fields |
| Invisible routing | Phase 2 (routing) | Routing decision appears in output before protocol execution begins |
| Narrative-only output | Phase 1 | Execution trace visible in output; not just conclusion |

---

## Sources

- [Anthropic Skill Authoring Best Practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices) — HIGH confidence, official Anthropic documentation. Verified 2026-02-28.
- [Claude Code Skills Documentation](https://code.claude.com/docs/en/skills) — HIGH confidence, official Anthropic documentation. Verified 2026-02-28.
- [Claude Code Skills Deep Dive — Lee Hanchung](https://leehanchung.github.io/blogs/2025/10/26/claude-skills-deep-dive/) — MEDIUM confidence, third-party technical analysis of Claude Code skills source code.
- [Custom Commands and Skills Errors — SFEIR Institute](https://institute.sfeir.com/en/claude-code/claude-code-custom-commands-and-skills/errors/) — MEDIUM confidence, community-verified error catalog.
- [Git Submodule Pitfalls — Porteneuve/Medium](https://medium.com/@porteneuve/mastering-git-submodules-34c65e940407) — MEDIUM confidence, widely-cited submodule reference.
- [Against Git Submodules — Tim Hutt](https://blog.timhutt.co.uk/against-submodules/) — MEDIUM confidence, covers documented failure modes.
- [LLM Hallucination in Multi-Step Agents — Medium/Faryalriz](https://medium.com/@faryalriz9/how-to-build-multi-step-llm-agents-that-dont-hallucinate-b45b33baa043) — LOW confidence (WebSearch only), consistent with higher-confidence sources on error propagation.
- [Naming Conflict Bug — Claude Code GitHub Issue #13586](https://github.com/anthropics/claude-code/issues/13586) — HIGH confidence, official GitHub issue confirming silent skill exclusion on naming conflicts.
- [CUE Language Introduction](https://cuelang.org/docs/introduction/) — HIGH confidence, official CUE documentation. Used to verify CUE type system semantics.
- [Reasoning Prompt Engineering Techniques 2025 — Adaline Labs](https://labs.adaline.ai/p/reasoning-prompt-engineering-techniques) — LOW confidence (WebSearch only), used for LLM reasoning failure mode context.

---
*Pitfalls research for: Socrates — Claude Code dialectic reasoning skill*
*Researched: 2026-02-28*

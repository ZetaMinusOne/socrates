# Feature Research

**Domain:** Claude Code skill — dialectic reasoning protocol executor
**Researched:** 2026-02-28
**Confidence:** HIGH (Claude Code skill system from official docs; dialectics framework from direct repo inspection)

## Feature Landscape

### Table Stakes (Users Expect These)

Features a Claude Code skill must have for users to consider it functional. Missing these = broken product.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| `/socrates` slash command invocation | Claude Code skills are invoked via `/name` — this is the entire UX entry point | LOW | `name: socrates` in SKILL.md frontmatter, the directory name determines this |
| Free-form problem description as input | Users describe a problem in natural language; skill must accept $ARGUMENTS or inline text | LOW | Standard Claude Code skill argument passing via `$ARGUMENTS` |
| Protocol execution (all 13) | Core promise: any problem gets routed to the right protocol and executed faithfully | HIGH | Requires reading and correctly following each of the 13 .cue schemas — adversarial (6), evaluative (6), exploratory (1) |
| Narrative output by default | Users expect an explanation of the reasoning process, not raw JSON — readable English prose | MEDIUM | Requires translating structured protocol outputs into narrative; is the default mode per PROJECT.md |
| Auto-routing via governance/routing.cue | Users should not need to know protocol names — problem description triggers correct selection | HIGH | routing.cue uses structural feature matching: term_inconsistency → CBP, causal_ambiguity → HEP, etc. |
| Git submodule reference to riverline-labs/dialectics | .cue files must be available for Claude to read; submodule keeps them in sync with upstream | LOW | Standard git submodule; Claude Code has been fixed to fully initialize submodules in plugins |
| Argument hint in autocomplete | When user types `/socrates `, they should see a hint showing what to type | LOW | `argument-hint: "[problem description]"` in frontmatter |
| SKILL.md with correct frontmatter | Claude Code requires SKILL.md with YAML frontmatter for skills to register and work | LOW | Required structure: name, description, argument-hint, allowed-tools |

### Differentiators (Competitive Advantage)

Features that distinguish this skill from a generic "think hard about this" prompt.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Structured output flag (`--structured` or similar) | Power users and downstream tooling can get typed results matching each protocol's CUE output schema; this turns Claude into a structured reasoning API | MEDIUM | Requires detecting the flag in $ARGUMENTS and switching output format; each protocol has different output schema |
| Protocol transparency in output | Telling the user which protocol was selected and why — not just the conclusion — builds trust and teaches the framework | LOW | Narrative output should include a brief routing rationale section before diving into protocol execution |
| Obligation gates enforced | The dialectics framework uses #ObligationGate as an anti-hallucination mechanism; the skill should enforce these rather than skip them | HIGH | Requires faithfully following the `all_satisfied: bool` gate before proceeding to derivation |
| Revision loop execution | When no survivors emerge from adversarial pressure, the framework requires looping back for revision rather than forcing a false conclusion | HIGH | The zero-survivor feedback mechanism in #RevisionLoop must be respected, not silently dropped |
| Recording schema output (optional) | After execution, produce a #Record compatible with governance/recording.cue for users who want queryable audit trails | MEDIUM | Secondary use case; the #Record schema has: record_id, source_run, dispute, resolution, acknowledged_limitations, dependencies, tags, next_actions |
| Domain coverage map used for routing | The DOMAIN_MAP.md explains eight question dimensions (existence, identity, unity, causation, possibility, fragility, prioritization, consistency) — referencing this in routing explanations teaches the user something | LOW | Only requires including domain map content as supporting file referenced from SKILL.md |
| Multi-protocol sequencing | routing.cue can produce `sequencing` when multiple protocols must run in order; executing this chain rather than stopping at one protocol handles composite problems | HIGH | RoutingResult includes optional secondary protocols and sequencing; implementing sequence execution is non-trivial |
| Supporting files for each protocol | Instead of embedding all 13 protocol schemas inline in SKILL.md, reference each .cue file as a supporting file — keeps SKILL.md under 500 lines and loads protocols on demand | MEDIUM | Claude Code skill directory structure supports this; SKILL.md references `dialectics/protocols/adversarial/cffp.cue` etc. |

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem good but create scope problems, complexity, or contradict the project's constraints.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| CUE runtime execution (`cue eval` / `cue vet`) | Seems like validation would catch errors | Requires CUE toolchain installed on user machine; creates runtime dependency; PROJECT.md explicitly rules this out; Claude is the interpreter | Claude reads .cue files as structured specs and follows them; no binary needed |
| MCP server packaging | More powerful distribution mechanism | Out of scope per PROJECT.md; adds packaging complexity; Claude Code skill is sufficient for the use case | Stay with Claude Code skill; MCP can be Phase 2 if needed |
| Custom protocol authoring | Users might want to write their own protocols | Massive scope expansion; requires schema validation, protocol design guidance, CUE authoring tooling; PROJECT.md explicitly excludes this | Consume existing 13 protocols; point users to riverline-labs/dialectics to author upstream |
| Claude Desktop support | Broader reach | Different skill installation mechanism; untested protocol behavior outside Code context; PROJECT.md explicitly targets Claude Code only | Claude Code only for v1 |
| Streaming structured output | Feels modern and responsive | CUE-typed output must be complete to be valid; streaming partial JSON/CUE breaks schema constraints; adds parsing complexity with no real benefit | Return complete output after full protocol execution |
| Protocol selection override (user forces a specific protocol) | Power users want to pick the protocol directly | Bypasses routing logic that is core to the value proposition; users who know which protocol they want can just describe their problem in protocol-specific terms | Document protocol descriptions so users who know the framework can phrase problems to trigger specific routing |
| Persistent run history/database | Useful for tracking reasoning over time | Requires storage, retrieval, query interfaces — far beyond a Claude Code skill scope; the recording.cue schema is for structured output, not for Claude to maintain a database | Produce recording-schema output that users can save if they want; don't manage storage |
| Web UI or chat interface | Accessibility for non-technical users | Contradicts the Claude Code distribution decision entirely; entire separate product | Stay in Claude Code terminal context |

## Feature Dependencies

```
[Git submodule: riverline-labs/dialectics]
    └──required by──> [Protocol execution (all 13)]
                          └──required by──> [Auto-routing via routing.cue]
                                                └──enables──> [/socrates slash command]

[/socrates slash command]
    └──required by──> [Narrative output]
    └──required by──> [Structured output flag]

[Protocol execution]
    └──required by──> [Obligation gate enforcement]
    └──required by──> [Revision loop execution]
    └──required by──> [Recording schema output]

[Narrative output] ──conflicts──> [Structured output flag]
    (they are mutually exclusive modes, selected by flag)

[Auto-routing via routing.cue] ──enables──> [Multi-protocol sequencing]
    (routing.cue can return sequencing; sequencing requires routing to work first)

[Supporting files structure] ──enhances──> [Protocol execution]
    (loading protocol .cue files on demand rather than all at once)
```

### Dependency Notes

- **Git submodule requires protocol execution:** Without the .cue files accessible, Claude has no schemas to follow. Submodule setup must be Phase 1 day 1.
- **Protocol execution requires routing:** Routing is how the user's problem reaches a protocol. Direct invocation is not exposed, so routing is not optional.
- **Obligation gates require protocol execution:** Gates are embedded in adversarial protocol flow; cannot be implemented separately.
- **Recording schema output requires protocol execution:** #Record wraps a completed run; it cannot exist without a run to wrap.
- **Structured output conflicts with narrative output:** These are two output modes for the same execution. Flag detection must be early in skill execution to set the mode before output begins.
- **Multi-protocol sequencing requires routing:** routing.cue is what produces sequencing information; sequencing cannot be implemented without routing working first.

## MVP Definition

### Launch With (v1)

Minimum viable product that validates the core concept: auto-routing + protocol execution + narrative output.

- [ ] SKILL.md with correct frontmatter (`name: socrates`, description, argument-hint, `disable-model-invocation: true` so users control when it runs)
- [ ] Git submodule wired to riverline-labs/dialectics so all .cue files are accessible
- [ ] Supporting files structure referencing all 13 protocol .cue files and both governance files
- [ ] Auto-routing: Claude reads governance/routing.cue, extracts structural features from user problem, selects primary protocol
- [ ] Protocol execution: Claude reads selected protocol's .cue schema and executes the full cycle (generate, challenge, rebuttal, derivation, obligation gate)
- [ ] Narrative output: readable prose explaining routing rationale, protocol execution steps, and conclusion
- [ ] Revision loop: if no survivors, execute the zero-survivor feedback loop rather than forcing a false result

### Add After Validation (v1.x)

Features to add once core routing and execution are working correctly.

- [ ] Structured output flag (`--structured` or `--raw`) — add once output schema from each protocol is confirmed consistent
- [ ] Recording schema output — add once protocol execution is stable; produces #Record-compatible output
- [ ] Multi-protocol sequencing — add when routing confidence is validated; requires routing.cue to return secondary protocols and skill to chain execution

### Future Consideration (v2+)

Features to defer until the skill has real users and validated use cases.

- [ ] Protocol transparency improvements — richer explanation of why routing selected a specific protocol (needs user feedback to know how much detail is wanted)
- [ ] Obligation gate reporting — explicit pass/fail report for each gate in the output (useful for debugging, not for typical use)
- [ ] MCP packaging — only if users need Claude Desktop or other tool support

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| /socrates slash command | HIGH | LOW | P1 |
| Git submodule setup | HIGH | LOW | P1 |
| SKILL.md frontmatter | HIGH | LOW | P1 |
| Auto-routing via routing.cue | HIGH | HIGH | P1 |
| Protocol execution (all 13) | HIGH | HIGH | P1 |
| Narrative output | HIGH | MEDIUM | P1 |
| Obligation gate enforcement | HIGH | HIGH | P1 |
| Revision loop execution | HIGH | HIGH | P1 |
| Supporting files structure | MEDIUM | LOW | P1 |
| Structured output flag | MEDIUM | MEDIUM | P2 |
| Protocol transparency in output | MEDIUM | LOW | P2 |
| Recording schema output | MEDIUM | MEDIUM | P2 |
| Multi-protocol sequencing | MEDIUM | HIGH | P2 |
| Domain coverage map in routing | LOW | LOW | P2 |
| Custom protocol authoring | LOW | HIGH | P3 (anti-feature) |
| Persistent run history | LOW | HIGH | P3 (anti-feature) |

**Priority key:**
- P1: Must have for launch
- P2: Should have, add when possible
- P3: Nice to have, future consideration

## Competitor Feature Analysis

No direct competitors exist in the Claude Code skill ecosystem for dialectic reasoning. Closest analogs:

| Feature | Generic "think hard" prompts | Chain-of-thought reasoning | Socrates skill |
|---------|------------------------------|---------------------------|----------------|
| Protocol selection | User must choose | None | Auto-routed by structural features |
| Formalism | Freeform | Freeform | CUE-schema-constrained |
| Anti-hallucination | None | None | Obligation gates |
| Output type | Prose | Prose | Narrative (default) or typed structured |
| Reusability | None | None | 13 domain-specific protocols |
| Audit trail | None | None | Recording schema output |
| Protocol fidelity | Variable | Variable | Schema-constrained execution |
| Distribution | Prompt | Prompt | Claude Code slash command |

The differentiating bet: schema-constrained execution + obligation gates produces more rigorous reasoning than freeform prompting, and auto-routing removes the barrier of knowing which protocol to apply.

## Sources

- [Claude Code Skills — Official Documentation](https://code.claude.com/docs/en/skills) — HIGH confidence; official Anthropic docs, February 2026
- [riverline-labs/dialectics GitHub repository](https://github.com/riverline-labs/dialectics) — HIGH confidence; direct repo inspection
- [governance/routing.cue — routing logic](https://raw.githubusercontent.com/riverline-labs/dialectics/main/governance/routing.cue) — HIGH confidence; direct file fetch
- [governance/recording.cue — recording schema](https://raw.githubusercontent.com/riverline-labs/dialectics/main/governance/recording.cue) — HIGH confidence; direct file fetch
- [dialectics.cue — kernel primitives](https://raw.githubusercontent.com/riverline-labs/dialectics/main/dialectics.cue) — HIGH confidence; direct file fetch
- PROJECT.md constraints (MCP out of scope, CUE runtime out of scope, custom protocol authoring out of scope, Claude Code only) — HIGH confidence; primary source document
- [Claude Code Skill vs Command: 2026 Best Practices](https://oneaway.io/blog/claude-skill-vs-command) — MEDIUM confidence; community source, consistent with official docs

---
*Feature research for: Claude Code dialectic reasoning skill (Socrates)*
*Researched: 2026-02-28*

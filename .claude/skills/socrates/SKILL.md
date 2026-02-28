---
name: socrates
description: Apply structured dialectic reasoning to any problem. Use when facing competing design candidates, argument stress-testing, assumption audits, causal claims, analogy evaluation, formalization, or possibility mapping. Accepts a problem description and auto-routes to the correct protocol.
argument-hint: "<describe your problem>"
disable-model-invocation: true
allowed-tools: Read
---

## Preflight

Read the file at path: `protocols/dialectics.opt.cue`

If the file is not found or empty, respond exactly:
"Setup required: the dialectics submodule is not initialized or protocol files have not been generated.
Run: git submodule update --init --recursive
Then check that protocols/dialectics.opt.cue exists.
If missing, regenerate the optimized protocol files from the dialectics submodule."
Stop here. Do not proceed.

## Input

If `$ARGUMENTS` is empty or blank:
Respond: "I apply structured dialectic reasoning to your problem — from testing assumptions to mapping possibility spaces. What would you like to reason through?"
Stop here. Do not proceed with protocol steps.

## Protocol Files

Optimized (pre-stripped) protocol files are in `protocols/`. Read ONLY the file for the selected protocol. Never load all protocols at once.

**Kernel and governance:**
- Kernel primitives: `protocols/dialectics.opt.cue`
- Routing logic: `protocols/routing.opt.cue`

**Adversarial protocols (6):**
- `protocols/adversarial/atp.opt.cue` — Assumption Testing Protocol
- `protocols/adversarial/cbp.opt.cue` — Challenge-Based Protocol
- `protocols/adversarial/cdp.opt.cue` — Counter-Dialectic Protocol
- `protocols/adversarial/cffp.opt.cue` — Claim-Flaw-Fix Protocol
- `protocols/adversarial/emp.opt.cue` — Epistemological Mapping Protocol
- `protocols/adversarial/hep.opt.cue` — Hypothesis Elimination Protocol

**Evaluative protocols (6):**
- `protocols/evaluative/aap.opt.cue` — Argument Assessment Protocol
- `protocols/evaluative/cgp.opt.cue` — Comparative Grounding Protocol
- `protocols/evaluative/ifa.opt.cue` — Inference Fidelity Assessment
- `protocols/evaluative/ovp.opt.cue` — Option Viability Protocol
- `protocols/evaluative/ptp.opt.cue` — Position Testing Protocol
- `protocols/evaluative/rcp.opt.cue` — Reasoning Chain Protocol

**Exploratory protocols (1):**
- `protocols/exploratory/adp.opt.cue` — Analytic Decomposition Protocol

## Execution

Protocol routing and execution are not yet implemented. If you reach this point with a non-empty argument, inform the user:
"The /socrates skill is in setup mode — protocol routing and execution will be available in a future update."

# Phase 10: Repository Cleanup and Phase 6 Verification - Research

**Researched:** 2026-03-01
**Domain:** Git submodule index repair, git index cleanup, GSD verification documentation
**Confidence:** HIGH

## Summary

Phase 10 is a gap-closure phase with three discrete tasks that fix audit-identified defects in the repository state left by Phases 6 and 7. The domain is not a new technology stack — it is git plumbing operations and GSD process documentation.

The two integration gaps (INTEG-01, INTEG-02) are clean git index operations. INTEG-01 requires registering a gitlink entry in HEAD at the correct path (`socrates/dialectics`) — the `.gitmodules` file already names the correct path but no gitlink entry exists in the git index for it. INTEG-02 requires removing 18 old tracked paths under `.claude/skills/socrates/` from the git index; none of these paths exist on disk, so removal is entirely index-only and safe. Both fixes are achievable in a single commit.

The verification gap (INTEG-03 / Phase 6 verification) requires creating a `VERIFICATION.md` for Phase 6 that cross-references the evidence already captured in `06-01-SUMMARY.md`, `06-02-SUMMARY.md`, and `06-UAT.md`. All 5 requirements (PLUG-03, PLUG-04, PATH-01, PATH-02, PATH-03) have passing UAT results and complete SUMMARY frontmatter — the VERIFICATION.md is a synthesis document, not a re-execution of tests. The ROADMAP.md also needs two line edits: Phase 6 status from "Unverified" to "Complete" and the plan checkboxes from unchecked to checked.

**Primary recommendation:** Execute as three sequential git tasks — (1) fix gitlink in one commit, (2) remove old paths in the same or separate commit, (3) create VERIFICATION.md and update ROADMAP in a docs commit. No new libraries, no re-running UAT.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| PLUG-03 | Plugin manifest (plugin.json) includes name, version, description, author, homepage, repository, and license | Already implemented in 06-01. Evidence: `socrates/.claude-plugin/plugin.json` verified in UAT test 1. VERIFICATION.md synthesizes existing evidence. |
| PLUG-04 | Plugin version in plugin.json follows semver and enables update detection | Already implemented in 06-01 (version=0.1.0). Evidence: UAT test 1 PASS. VERIFICATION.md synthesizes existing evidence. |
| PATH-01 | User can invoke `/socrates` after plugin install and all protocol file reads resolve correctly via `$CLAUDE_PLUGIN_ROOT` | Already implemented in 06-02. Evidence: UAT test 3 PASS (preflight passes, protocol execution works). |
| PATH-02 | SKILL.md preflight check reads `$CLAUDE_PLUGIN_ROOT/socrates/protocols/dialectics.opt.cue` | Already implemented in 06-02. Evidence: UAT test 3+4 PASS. |
| PATH-03 | All ~18 protocol file references in SKILL.md use `$CLAUDE_PLUGIN_ROOT/socrates/protocols/` prefix | Already implemented in 06-02. Evidence: UAT test 4 PASS (`grep -c` returns 0 for old paths). |
</phase_requirements>

## Standard Stack

### Core

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| git | system | Index manipulation, submodule registration, rm operations | Only tool that can modify the git index |

### Supporting

| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| `git ls-files --stage` | system | Verify index state before and after fix | Confirm gitlink appears at correct path with mode 160000 |
| `git rm --cached` | system | Remove files/gitlinks from index without touching disk | Remove old tracked paths that no longer exist on disk |
| `git update-index` | system | Add gitlink entry directly to index | Register gitlink at new path when `git add` won't pick up broken submodule worktree |
| `git submodule` | system | Verify submodule status, deinit old name | Clean up .git/config stale entry |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `git update-index --cacheinfo` | `git submodule add` | `submodule add` would fail because the submodule remote already exists in .gitmodules; `update-index` is more surgical |
| Single commit for all fixes | Separate commits | A single atomic commit is cleaner and easier to verify; separate commits provide bisect clarity but are unnecessary here |

## Architecture Patterns

### Pattern 1: Git Gitlink Registration for Moved Submodule

**What:** When a submodule directory is moved manually (not via `git mv`), the git index retains the gitlink at the old path. The `.gitmodules` can be updated but the index must be separately corrected.

**When to use:** When `.gitmodules` references `socrates/dialectics` but `git ls-files --stage | grep 160000` shows the gitlink at `.claude/skills/socrates/dialectics`.

**Exact commands:**
```bash
# Step 1: Remove old gitlink from index
git rm --cached ".claude/skills/socrates/dialectics"

# Step 2: Register new gitlink at correct path (same SHA)
# SHA from: git ls-files --stage | grep 160000 | awk '{print $2}'
# Current SHA: 10528fb0206418c6fa204d0e9bf0f652acf23e5f
git update-index --add --cacheinfo 160000,10528fb0206418c6fa204d0e9bf0f652acf23e5f,socrates/dialectics

# Verify:
git ls-files --stage socrates/dialectics
# Expected: 160000 10528fb0206418c6fa204d0e9bf0f652acf23e5f 0	socrates/dialectics
```

**Important:** The SHA must match the submodule commit currently in use. Do not use the literal SHA above — verify it from `git ls-files --stage | grep 160000` immediately before running the update-index command.

### Pattern 2: Index-Only Removal of Deleted Tracked Files

**What:** Files that were deleted from disk but never `git rm`'d remain tracked in the index. They show as "deleted" in `git status`. `git rm --cached` removes them from the index without affecting disk.

**When to use:** For the 17 regular files (+ gitlink already handled above) under `.claude/skills/socrates/`.

**Exact commands:**
```bash
# After gitlink is already removed (Pattern 1), remove all remaining .claude/skills/socrates/ files
git rm --cached -r ".claude/skills/socrates/"

# Verify:
git ls-files ".claude/skills/socrates" | wc -l
# Expected: 0
git status
# Expected: no unstaged deletes under .claude/skills/socrates/
```

**Note:** Since `.claude/` does not exist on disk, `git rm --cached -r` is safe — no disk content will be touched. The gitlink entry `.claude/skills/socrates/dialectics` should already be removed by Pattern 1 before running this; if run together, git rm -r handles submodule entries differently so Pattern 1 first is cleaner.

### Pattern 3: Phase VERIFICATION.md as Evidence Synthesis

**What:** A VERIFICATION.md that does not re-run tests but synthesizes existing SUMMARY frontmatter and UAT results to formally satisfy the GSD verification requirement.

**When to use:** Phase 6 was executed outside the formal GSD pipeline (no `gsd:verify-work` run). All evidence exists; the document is missing.

**Structure to follow:** Match the format of `07-VERIFICATION.md` (Phase 7's verified example):
- YAML frontmatter: `phase`, `verified`, `status`, `score`, `re_verification: false`
- Goal Achievement section with Observable Truths table
- Required Artifacts table
- Key Link Verification table
- Requirements Coverage table
- Anti-Patterns Found section
- Gaps Summary

**Evidence sources to cross-reference:**
```
06-01-SUMMARY.md frontmatter:
  requirements-completed: [PLUG-03, PLUG-04]
  key-decisions: ["$CLAUDE_PLUGIN_ROOT DOES expand...", "version=0.1.0 included..."]

06-02-SUMMARY.md frontmatter:
  requirements-completed: [PATH-01, PATH-02, PATH-03]
  key-decisions: ["preflight error message path reference removed entirely", "End-to-end verification PASSED"]

06-UAT.md results (all 5 PASS):
  1. Plugin manifest identity (PLUG-03, PLUG-04)
  2. Slash command available via --plugin-dir (PATH-01)
  3. Preflight passes and protocol executes (PATH-01, PATH-02)
  4. Zero old hardcoded paths remain (PATH-03)
  5. Preflight error message is plugin-appropriate (PATH-02)

Commit evidence:
  fc425ca — feat(06-01): create plugin manifest and restructure directory
  418a330 — feat(06-02): migrate all 24 path references and update preflight message
```

### Pattern 4: ROADMAP.md Progress Table Update

**What:** Update two stale entries in ROADMAP.md to reflect Phase 6's actual execution status.

**Changes needed:**

1. Phase 6 bullet in milestones section:
   - FROM: `- [ ] **Phase 6: Plugin Scaffold and Path Migration** - Plugin manifest created...`
   - TO: `- [x] **Phase 6: Plugin Scaffold and Path Migration** - Plugin manifest created... (completed 2026-03-01)`

2. Phase 6 plan checkboxes in Phase Details section:
   - FROM: `- [ ] 06-01-PLAN.md — Create plugin manifest...`
   - TO: `- [x] 06-01-PLAN.md — Create plugin manifest...`
   - FROM: `- [ ] 06-02-PLAN.md — Migrate all 24 path references...`
   - TO: `- [x] 06-02-PLAN.md — Migrate all 24 path references...`

3. Progress table row for Phase 6:
   - FROM: `| 6. Plugin Scaffold and Path Migration | v1.1 | 2/2 | Unverified | - |`
   - TO: `| 6. Plugin Scaffold and Path Migration | v1.1 | 2/2 | Complete | 2026-03-01 |`

### Anti-Patterns to Avoid

- **Re-running UAT for VERIFICATION.md:** The UAT already ran and all 5 tests passed. Re-running would be wasted effort and introduces risk of environment differences. The VERIFICATION.md should cite existing UAT evidence.
- **Using `git rm` without `--cached` on index-only files:** Files don't exist on disk. `git rm` (without `--cached`) would fail with "pathspec did not match any files." Always use `--cached` for this operation.
- **Using `git submodule add` to fix the gitlink:** `submodule add` checks for existing entries in `.gitmodules` and will fail or produce a duplicate entry. Use `git update-index --cacheinfo` instead.
- **Forgetting to remove the gitlink separately from regular files:** `git rm --cached -r ".claude/skills/socrates/"` treats the gitlink entry differently on some git versions. Removing the gitlink via `git rm --cached ".claude/skills/socrates/dialectics"` first (Pattern 1) then doing `-r` on the rest is safer.
- **Not verifying the SHA before registering the gitlink:** The SHA `10528fb0206418c6fa204d0e9bf0f652acf23e5f` is the correct one currently, but should be verified immediately before the `update-index` command by inspecting `git ls-files --stage | grep 160000`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Registering gitlink in index | Manual binary index editing | `git update-index --cacheinfo` | git manages index format; direct edit would corrupt |
| Verifying VERIFICATION.md format | New template | Copy Phase 7's VERIFICATION.md structure | Phase 7's VERIFICATION.md is the established pattern in this repo |

**Key insight:** Everything in this phase is surgical git index manipulation and documentation synthesis. No new code, no new dependencies.

## Common Pitfalls

### Pitfall 1: `git rm -r .claude/skills/socrates/` Leaves Behind the Gitlink

**What goes wrong:** Running `git rm --cached -r ".claude/skills/socrates/"` may fail on the gitlink entry (`.claude/skills/socrates/dialectics`) because git treats gitlink entries differently from regular files in recursive removal.

**Why it happens:** git rm -r descends into "directories" in the index but gitlinks (mode 160000) are treated as opaque object references, not directories.

**How to avoid:** Remove the gitlink entry explicitly first with `git rm --cached ".claude/skills/socrates/dialectics"`, then run `git rm --cached -r ".claude/skills/socrates/"` on the remaining 17 regular files. Verify with `git ls-files ".claude/skills/socrates" | wc -l` returns 0.

**Warning signs:** `git rm --cached -r ".claude/skills/socrates/"` exits 0 but `git ls-files ".claude" | wc -l` still returns 1.

### Pitfall 2: Submodule Worktree State is Broken Locally (But That's OK)

**What goes wrong:** After fixing the git index, `git submodule status` may show errors or warnings about the local worktree state. The `.git` file inside `socrates/dialectics/` references `../../../../.git/modules/.claude/skills/socrates/dialectics` — a path that doesn't exist (4 levels up from `socrates/dialectics/` is `/Users/javier`, not the project root).

**Why it happens:** The submodule worktree was physically moved from `.claude/skills/socrates/dialectics` to `socrates/dialectics` but the `.git` file inside it was not updated. The `.git/modules/` entry is also still named `.claude/skills/socrates/dialectics`.

**How to avoid:** This local machine state is a known limitation. The committed fix (gitlink at right path in HEAD) is what matters for downstream consumers. The local machine will function for commits and regular git operations — only `git submodule` commands may show warnings. Document this as a known local state issue in the VERIFICATION.md's Gaps Summary.

**Warning signs:** `git submodule status` returns an error about path or hash mismatch. This is expected on this machine and is NOT a blocker.

### Pitfall 3: VERIFICATION.md Phase 6 Truths Don't Match the Actual UAT

**What goes wrong:** The Observable Truths in the VERIFICATION.md are copied from the Phase 6 Success Criteria (from ROADMAP.md) but the UAT tested slightly different things.

**Why it happens:** The UAT was designed around the implementation, which had some deviations from the original plan (e.g., 23 path refs not 24, error message strategy changed).

**How to avoid:** Map each Observable Truth to its UAT result, not just to the Success Criteria. Key deviations to document:
  - Success Criterion 4 says "~18 protocol file Read references" but actual count is 23 (confirmed in UAT test 4)
  - The preflight error message strategy changed from "migrate path" to "remove path entirely" (documented in 06-02 key decisions)

### Pitfall 4: ROADMAP.md Update Misses the Phase 6 Plans Checkbox Section

**What goes wrong:** The ROADMAP progress table is updated (row 6: "Unverified" → "Complete") but the plan checkboxes in the Phase Details section remain `[ ]`.

**Why it happens:** There are TWO places in ROADMAP.md that reflect Phase 6 status — the top-level bullet, the plans list in Phase Details, and the progress table row. Easy to miss one.

**How to avoid:** After editing, verify with grep: `grep -n "06-0" .planning/ROADMAP.md` should show all three locations with `[x]` checkboxes.

## Code Examples

Verified patterns from this repository's git state:

### Verify Current Gitlink State
```bash
git ls-files --stage | grep 160000
# Current output: 160000 10528fb0206418c6fa204d0e9bf0f652acf23e5f 0	.claude/skills/socrates/dialectics
# After fix:      160000 10528fb0206418c6fa204d0e9bf0f652acf23e5f 0	socrates/dialectics
```

### Fix Gitlink Registration (INTEG-01)
```bash
# Remove old gitlink
git rm --cached ".claude/skills/socrates/dialectics"

# Register at correct path (use actual SHA from ls-files --stage output)
git update-index --add --cacheinfo 160000,10528fb0206418c6fa204d0e9bf0f652acf23e5f,socrates/dialectics

# Verify
git ls-files --stage socrates/dialectics
# Expected: 160000 10528fb0206418c6fa204d0e9bf0f652acf23e5f 0	socrates/dialectics
```

### Remove 17 Remaining Old Tracked Files (INTEG-02)
```bash
# After gitlink is removed from above, remove remaining 17 regular files
git rm --cached -r ".claude/skills/socrates/"

# Verify count
git ls-files ".claude/skills/socrates" | wc -l
# Expected: 0

# Verify git status is clean
git status
# Expected: no unstaged deletes under .claude/skills/socrates/
```

### Confirm gitlink Works for Submodule Init (Success Criterion 1)
```bash
# After committing, verify the gitlink looks right:
git ls-files --stage socrates/dialectics
# Expected: 160000 <sha> 0	socrates/dialectics

# This is what a fresh clone would see. git submodule update --init
# reads .gitmodules (finds socrates/dialectics URL), finds the gitlink,
# and clones into .git/modules/socrates/dialectics.
```

### VERIFICATION.md Frontmatter Template (Phase 6)
```yaml
---
phase: 06-plugin-scaffold-and-path-migration
verified: 2026-03-01T<time>Z
status: passed
score: 5/5 must-haves verified
re_verification: false
---
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Run `git submodule move` (doesn't exist) | `git rm --cached` old + `git update-index` new | Always | git has no built-in "move submodule" command |
| Phase 6 plans marked `[ ]` in ROADMAP | After this phase: `[x]` | Phase 10 | Audit showed discrepancy between execution and ROADMAP state |
| No VERIFICATION.md for Phase 6 | After this phase: VERIFICATION.md exists | Phase 10 | Closes the 5 partial requirements to satisfied |

## Open Questions

1. **Should we fix the local .git/modules naming and socrates/dialectics/.git file?**
   - What we know: The `.git` file inside `socrates/dialectics/` has an incorrect relative path (`../../../../` instead of `../../`). The `.git/modules/` directory is named `.claude/skills/socrates/dialectics` not `socrates/dialectics`. These are local-machine-only issues.
   - What's unclear: Whether `git submodule status` warnings will cause confusion or problems in Phase 8/9 development. Also whether CI (if added later) would fail on this.
   - Recommendation: Fix the local state as part of this phase if it's a 2-command fix. The `.git` file inside `socrates/dialectics/` needs one line changed (`../../../../` → `../../`). The `.git/config` needs the submodule name updated from `.claude/skills/socrates/dialectics` to `socrates/dialectics`. These are NOT committed changes — they fix local machine state only.

2. **Does VERIFICATION.md need a Human Verification section?**
   - What we know: Phase 7's VERIFICATION.md has "Human Verification Required: None" because all checks were mechanical.
   - What's unclear: For Phase 6, the empirical UAT involved human observation (`--plugin-dir` test in Claude Code). This is already captured in UAT.md.
   - Recommendation: Note that UAT provided the human verification and reference `06-UAT.md` directly. No new human verification required.

## Validation Architecture

> `nyquist_validation` is not present in `.planning/config.json` (only `research`, `plan_check`, `verifier` are set). Skipping Validation Architecture section.

## Sources

### Primary (HIGH confidence)

- Git documentation (git ls-files, git rm, git update-index) — verified against actual repository state in this session
- `/Users/javier/projects/socrates/.planning/v1.1-MILESTONE-AUDIT.md` — definitive source for INTEG-01, INTEG-02 gap descriptions and evidence
- `/Users/javier/projects/socrates/.planning/phases/07-pre-built-protocol-files/07-VERIFICATION.md` — canonical VERIFICATION.md format example
- `/Users/javier/projects/socrates/.planning/phases/06-plugin-scaffold-and-path-migration/06-UAT.md` — all 5 UAT tests passed, evidence for VERIFICATION.md
- `/Users/javier/projects/socrates/.planning/phases/06-plugin-scaffold-and-path-migration/06-01-SUMMARY.md` — PLUG-03, PLUG-04 evidence
- `/Users/javier/projects/socrates/.planning/phases/06-plugin-scaffold-and-path-migration/06-02-SUMMARY.md` — PATH-01, PATH-02, PATH-03 evidence

### Secondary (MEDIUM confidence)

- git manual page for `update-index --cacheinfo` — standard git plumbing documented in git-scm.com

### Tertiary (LOW confidence)

- None

## Metadata

**Confidence breakdown:**
- Git operations (INTEG-01, INTEG-02): HIGH — directly verified against actual repository index state; exact SHA confirmed; exact file counts confirmed (18 tracked paths, 1 gitlink)
- VERIFICATION.md synthesis: HIGH — all source documents read and cross-referenced; Phase 7 template inspected
- ROADMAP.md updates: HIGH — exact current text confirmed via grep; required changes are specific line edits
- Local machine state (broken .git file, .git/modules naming): HIGH — confirmed broken, fix is straightforward but not critical to phase success criteria

**Research date:** 2026-03-01
**Valid until:** Indefinite — git plumbing operations are stable, no external API dependencies

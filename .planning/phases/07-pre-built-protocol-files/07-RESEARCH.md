# Phase 7: Pre-Built Protocol Files - Research

**Researched:** 2026-03-01
**Domain:** Git file tracking, Makefile build targets, generated-but-tracked file patterns
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

None — user deferred all implementation decisions.

### Claude's Discretion

User deferred all implementation decisions — this is a straightforward infrastructure phase. Claude has full flexibility on:

- **Staleness protection** — Whether/how to detect when committed `.opt.cue` files are outdated vs the submodule (hash check, make target, or developer discipline)
- **Build verification** — What `make build` validates after regeneration (file count, diff report, size budget)
- **Developer workflow** — How to document the submodule-update-then-rebuild flow
- **Git hygiene** — How to handle generated-but-tracked files (comments, .gitignore adjustments, or keep simple)

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| BLDG-01 | User can install the plugin without running `git submodule update --init` or any build step | Files must be committed to git so they are present post-clone without any submodule init or build |
| BLDG-02 | All 15 pre-built `.opt.cue` files (13 protocols + dialectics + routing) are committed to git and present in the repo | Core task: `git add socrates/protocols/**/*.opt.cue socrates/protocols/*.opt.cue` then commit |
| BLDG-03 | Developer can run a build command (Makefile) to regenerate `.opt.cue` files from the dialectics submodule | Makefile `build` target already exists and works — needs verification and optional staleness detection |
</phase_requirements>

## Summary

Phase 7 is the simplest phase in the v1.1 milestone: commit 15 already-generated `.opt.cue` files that currently exist on disk but are untracked by git. After Phase 6, the plugin structure lives under `socrates/` and SKILL.md references protocols via `$CLAUDE_PLUGIN_ROOT/socrates/protocols/`. The protocol files are present at `socrates/protocols/` (plus subdirs `adversarial/`, `evaluative/`, `exploratory/`) but git tracks none of them — `git ls-files socrates/protocols/ | wc -l` returns 0.

The core work is a single `git add` covering all 15 files, followed by a commit. The Makefile `build` target (runs `scripts/strip_cue.py`) already works and regenerates all 15 files correctly with a clean exit code. No new tooling is needed. The `clean` target already deletes all `.opt.cue` files from `socrates/protocols/`.

The discretionary decisions (staleness protection, build verification output, developer workflow docs) can be handled lightly: a `make check` or `make status` target that diffs the current tracked files against a fresh regeneration is the most developer-friendly staleness signal, but even a simple comment in the Makefile is sufficient. Given the project's out-of-scope decision that "CI/release pipeline for builds" is not needed, the bar is low: committed files present, `make build` works, `make clean` followed by `make build` restores all 15 files.

**Primary recommendation:** `git add` all 15 `.opt.cue` files in `socrates/protocols/` and commit; verify `git ls-files socrates/protocols/ | wc -l` returns 15; optionally add a `make check` Makefile target for staleness detection.

## Standard Stack

### Core

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| git | system | Track generated files as first-class repo assets | Standard for committed build artifacts |
| GNU Make | system | `build`, `clean`, `check` targets | Already in use; `Makefile` exists and works |
| Python 3 | system | `scripts/strip_cue.py` — reads dialectics submodule, writes `.opt.cue` | Already in use; fully functional |

### Supporting

| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| `git diff --exit-code` | system | Staleness detection — exits non-zero if tracked files differ from freshly generated | Use in `make check` target |
| `git ls-files` | system | File count verification — confirms 15 files tracked | Use in post-commit verification |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Committed generated files | `.gitignore` + consumer runs `make build` | Breaks BLDG-01 — consumers must not need a build step |
| `make check` diff target | Pre-commit hook | Hooks not in project scope; `make check` is opt-in and non-blocking |
| Python `strip_cue.py` | Shell script | Python already chosen; no reason to change |

**Installation:**

No new packages — all tooling is already present in the repo.

## Architecture Patterns

### Recommended Project Structure

After Phase 7, the tracked file tree for protocols:

```
socrates/
├── protocols/
│   ├── dialectics.opt.cue       # tracked
│   ├── routing.opt.cue          # tracked
│   ├── adversarial/
│   │   ├── atp.opt.cue          # tracked
│   │   ├── cbp.opt.cue          # tracked
│   │   ├── cdp.opt.cue          # tracked
│   │   ├── cffp.opt.cue         # tracked
│   │   ├── emp.opt.cue          # tracked
│   │   └── hep.opt.cue          # tracked
│   ├── evaluative/
│   │   ├── aap.opt.cue          # tracked
│   │   ├── cgp.opt.cue          # tracked
│   │   ├── ifa.opt.cue          # tracked
│   │   ├── ovp.opt.cue          # tracked
│   │   ├── ptp.opt.cue          # tracked
│   │   └── rcp.opt.cue          # tracked
│   └── exploratory/
│       └── adp.opt.cue          # tracked
```

Total: 15 `.opt.cue` files.

### Pattern 1: Committed Generated Files (Generated-but-Tracked)

**What:** Generated files that are committed to git so consumers get them without running any build step. The generator (strip_cue.py / Makefile) remains the authoritative source for _updates_, but the generated output is a first-class repo citizen.

**When to use:** When consumers should not need any toolchain — just `git clone` / `git pull` (or plugin install) and the files are present.

**Example:**

```bash
# One-time: add all generated protocol files
git add socrates/protocols/dialectics.opt.cue
git add socrates/protocols/routing.opt.cue
git add socrates/protocols/adversarial/
git add socrates/protocols/evaluative/
git add socrates/protocols/exploratory/
git commit -m "feat(07): commit pre-built protocol files for zero-setup install"

# Verify count
git ls-files socrates/protocols/ | wc -l
# → 15
```

**Developer regeneration workflow:**

```bash
git submodule update --remote socrates/dialectics  # pull latest dialectics
make build                                          # regenerate all 15 .opt.cue files
git add socrates/protocols/
git commit -m "chore: regenerate protocol files from dialectics vX.Y.Z"
```

### Pattern 2: Makefile `check` Target for Staleness Detection

**What:** A `make check` target regenerates files to a temp location (or in-place and diffs), reports whether committed files are current.

**When to use:** When developers need to verify committed files match the current submodule state before releasing.

**Example (in-place diff approach):**

```makefile
check:
	python3 scripts/strip_cue.py
	git diff --exit-code socrates/protocols/ || (echo "Protocol files are stale — run 'make build' and commit"; exit 1)
	echo "Protocol files are up to date."
```

Note: This modifies files in place and uses `git diff` to detect changes. If the submodule hasn't changed, `strip_cue.py` is deterministic (idempotent), so `git diff` will show no changes. If the submodule has been updated, changes appear and the developer is prompted to commit.

### Anti-Patterns to Avoid

- **`.gitignore` on `.opt.cue` files:** Would break BLDG-01 entirely — never add a `.gitignore` pattern for `*.opt.cue` under `socrates/protocols/`.
- **Submodule `--recurse-submodules` required for consumers:** The whole point of this phase is that consumers never need the submodule. Committed protocol files must be self-sufficient.
- **Regenerating in CI on every push:** Out-of-scope per REQUIREMENTS.md ("CI/release pipeline for builds" is listed as out of scope). Developer runs `make build` manually after submodule updates.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Staleness detection | Custom hash comparison script | `git diff --exit-code` after `make build` | Git already knows what's changed; diff is deterministic |
| File count verification | Custom counting script | `git ls-files socrates/protocols/ \| wc -l` | Standard git plumbing; unambiguous |
| Build orchestration | New build system | Existing `Makefile` + `strip_cue.py` | Already working and tested — no new tooling needed |

**Key insight:** Everything needed for this phase already exists. The work is purely git operations (add + commit) plus optional Makefile target additions.

## Common Pitfalls

### Pitfall 1: Forgetting Subdirectory Files

**What goes wrong:** Running `git add socrates/protocols/*.opt.cue` only catches the two top-level files (`dialectics.opt.cue`, `routing.opt.cue`) — the 13 files in subdirectories are missed.

**Why it happens:** Shell glob `*.opt.cue` does not recurse into subdirectories without `**` globbing, and `**` requires shell support (`zsh` supports it, but `bash` requires `globstar`).

**How to avoid:** Use one of these safe forms:
```bash
git add socrates/protocols/
# or
git add $(git ls-files --others --exclude-standard socrates/protocols/)
# or add each subdir explicitly
git add socrates/protocols/adversarial/ socrates/protocols/evaluative/ socrates/protocols/exploratory/
```

**Warning signs:** After `git add`, running `git status` shows fewer than 15 staged files.

### Pitfall 2: Accidentally Tracking Makefile or scripts/strip_cue.py Twice

**What goes wrong:** The untracked file list includes `Makefile` and `scripts/strip_cue.py` — staging `socrates/protocols/` is safe, but a broad `git add .` or `git add scripts/` would double-track files that are already planned for tracking.

**Why it happens:** `git status --short` shows `Makefile` and `scripts/strip_cue.py` as untracked (they've never been committed in the `socrates/` new structure — they live at repo root, not inside `socrates/`). These are NOT part of Phase 7's scope.

**How to avoid:** Stage only `socrates/protocols/` paths. Verify with `git status` before committing.

**Warning signs:** `git status` shows `Makefile` or `scripts/` as staged when they shouldn't be.

### Pitfall 3: Stale Files from a Prior `make build` Run

**What goes wrong:** The 15 `.opt.cue` files on disk may have been generated during an earlier session. If the dialectics submodule has been updated since then, the committed files would be stale from day one.

**Why it happens:** `git ls-files --others` shows the files exist and are generated, but doesn't tell you _when_ they were generated relative to the submodule state.

**How to avoid:** Run `make build` immediately before `git add` to ensure the files on disk are freshly generated from the current submodule state. The script is idempotent and fast (< 1s), so there's no cost to re-running it.

**Warning signs:** `git log --oneline socrates/dialectics` shows commits more recent than the file mtimes on `socrates/protocols/*.opt.cue`.

### Pitfall 4: .gitignore Pattern Conflict

**What goes wrong:** There is currently no `.gitignore` in the repo. If one is created later (by another phase or contributor) and accidentally includes `*.cue` or `*.opt.cue`, the committed protocol files would become invisible to git.

**Why it happens:** `.opt.cue` is an unusual extension — someone might generalize a `.cue` ignore pattern.

**How to avoid:** If a `.gitignore` is ever added, explicitly include a negation:
```gitignore
# Never ignore pre-built protocol files
!socrates/protocols/**/*.opt.cue
!socrates/protocols/*.opt.cue
```

For Phase 7, no `.gitignore` exists, so this is not an immediate concern — just a future hygiene note.

## Code Examples

Verified patterns from current repo state:

### Verify Current State Before Starting

```bash
# Confirm all 15 files exist on disk but are untracked
git ls-files --others --exclude-standard socrates/protocols/
# Should output 15 lines

# Confirm none are currently tracked
git ls-files socrates/protocols/ | wc -l
# Should output 0
```

### Run Fresh Build Before Tracking

```bash
# Regenerate from current submodule state (idempotent, ~1 second)
make build
# Output: "Done. 15 files generated. All under 16,000 chars."
```

### Stage and Commit All 15 Files

```bash
# Stage all protocol files (safe — only adds the untracked .opt.cue files)
git add socrates/protocols/

# Verify: should show exactly 15 staged new files
git status

# Confirm the count
git diff --cached --name-only | wc -l
# → 15

# Commit
git commit -m "feat(07): commit pre-built protocol files for zero-setup install"
```

### Post-Commit Verification

```bash
# Requirement BLDG-02: must return 15
git ls-files socrates/protocols/ | wc -l
# → 15

# List them to confirm correct paths
git ls-files socrates/protocols/
```

### Makefile `check` Target (Optional Staleness Detection)

```makefile
.PHONY: build clean check

build:
	python3 scripts/strip_cue.py

clean:
	find socrates/protocols -name '*.opt.cue' -delete

check:
	python3 scripts/strip_cue.py
	git diff --exit-code socrates/protocols/ || (echo "Protocol files are stale — run 'make build && git add socrates/protocols/ && git commit'"; exit 1)
	@echo "Protocol files are up to date."
```

### Clean-and-Rebuild Test (Verifies BLDG-03)

```bash
# Simulate a developer regeneration cycle
make clean
ls socrates/protocols/  # should show empty dirs (no .opt.cue)
make build
ls socrates/protocols/adversarial/  # should show 6 .opt.cue files
git ls-files socrates/protocols/ | wc -l  # should still show 15 (git still tracks them)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Protocol files in `.claude/skills/socrates/protocols/` (untracked) | Protocol files in `socrates/protocols/` (to be tracked) | Phase 6 path migration, committed in Phase 7 | Consumers get all files post-install without any build step |
| Submodule required at install time | Submodule optional at install time | Phase 7 | BLDG-01 satisfied |

**Current state (pre-Phase 7):**
- 15 `.opt.cue` files exist at `socrates/protocols/` — on disk but untracked
- `git ls-files socrates/protocols/ | wc -l` → 0
- Consumer who installs plugin gets no protocol files

**Target state (post-Phase 7):**
- 15 `.opt.cue` files committed at `socrates/protocols/`
- `git ls-files socrates/protocols/ | wc -l` → 15
- Consumer who installs plugin gets all 15 protocol files without any build step

## Open Questions

1. **Should `make check` be included in Phase 7 or deferred?**
   - What we know: All three BLDG requirements can be satisfied without a `make check` target
   - What's unclear: Whether the planner will want a single-plan phase (just git add + commit) or a two-task plan (git add + commit, then Makefile update)
   - Recommendation: Include `make check` as a second task within Phase 7 — it's trivial (4 lines of Makefile) and directly supports the developer workflow described in BLDG-03

2. **Should `Makefile` and `scripts/strip_cue.py` be tracked in this phase?**
   - What we know: Both files are currently untracked (shown in `git status`). They live at the repo root, not inside `socrates/`.
   - What's unclear: Were they intentionally left untracked? Are they part of a different phase's scope?
   - Recommendation: Track them in this phase — they are the build system for the protocol files (BLDG-03), and leaving them untracked is an oversight. A consumer who wants to run `make build` needs both files.

## Sources

### Primary (HIGH confidence)

- Direct `git status` inspection of `/Users/javier/projects/socrates` — confirmed 15 `.opt.cue` files untracked
- Direct `git ls-files` inspection — confirmed 0 files currently tracked under `socrates/protocols/`
- `scripts/strip_cue.py` execution — confirmed `make build` works, all 15 files generated under 16K chars
- `Makefile` inspection — confirmed `build` and `clean` targets exist and are functional
- `.planning/phases/06-plugin-scaffold-and-path-migration/06-01-SUMMARY.md` — confirmed plugin structure, $CLAUDE_PLUGIN_ROOT path resolution, and Phase 6 completion status
- `.planning/REQUIREMENTS.md` — confirmed BLDG-01, BLDG-02, BLDG-03 requirements and out-of-scope list (CI/release pipeline)

### Secondary (MEDIUM confidence)

- Standard git "committed generated files" pattern — common in projects shipping pre-built artifacts for zero-setup install (e.g., bundled JS in npm packages)

### Tertiary (LOW confidence)

None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — tools are already in the repo and working; no new dependencies
- Architecture: HIGH — current file state directly inspected; exact commands verified
- Pitfalls: HIGH — derived from direct inspection of current git state and repo structure

**Research date:** 2026-03-01
**Valid until:** 2026-04-01 (stable — no fast-moving dependencies; all tooling is local)

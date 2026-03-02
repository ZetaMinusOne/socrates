#!/usr/bin/env python3
"""
strip_cue.py — Strip documentation comments from CUE protocol files.

Produces .opt.cue files in the protocols/ directory tree from raw .cue files
in the dialectics/ submodule. Deterministic and idempotent.

Rules:
  - Strip block comment sections: 3+ consecutive //-only lines (design docs, rationale)
  - Strip divider lines: lines matching // ─, // ===, // ---
  - Collapse multiple blank lines to one blank line
  - Preserve: inline comments (// on same line as CUE code),
              1-2 line comment groups before CUE definitions (semantic descriptions),
              all CUE structure (types, fields, constraints, enums)
"""

import os
import re
import sys

# Script lives at scripts/strip_cue.py
# Base is socrates/ (sibling directory)
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
BASE_DIR = os.path.join(os.path.dirname(SCRIPT_DIR), 'socrates')

FILE_MAP = [
    ("dialectics/dialectics.cue",                          "protocols/dialectics.opt.cue"),
    ("dialectics/governance/routing.cue",                  "protocols/routing.opt.cue"),
    ("dialectics/governance/recording.cue",                "governance/recording.opt.cue"),
    ("dialectics/protocols/adversarial/atp.cue",           "protocols/adversarial/atp.opt.cue"),
    ("dialectics/protocols/adversarial/cbp.cue",           "protocols/adversarial/cbp.opt.cue"),
    ("dialectics/protocols/adversarial/cdp.cue",           "protocols/adversarial/cdp.opt.cue"),
    ("dialectics/protocols/adversarial/cffp.cue",          "protocols/adversarial/cffp.opt.cue"),
    ("dialectics/protocols/adversarial/emp.cue",           "protocols/adversarial/emp.opt.cue"),
    ("dialectics/protocols/adversarial/hep.cue",           "protocols/adversarial/hep.opt.cue"),
    ("dialectics/protocols/evaluative/aap.cue",            "protocols/evaluative/aap.opt.cue"),
    ("dialectics/protocols/evaluative/cgp.cue",            "protocols/evaluative/cgp.opt.cue"),
    ("dialectics/protocols/evaluative/ifa.cue",            "protocols/evaluative/ifa.opt.cue"),
    ("dialectics/protocols/evaluative/ovp.cue",            "protocols/evaluative/ovp.opt.cue"),
    ("dialectics/protocols/evaluative/ptp.cue",            "protocols/evaluative/ptp.opt.cue"),
    ("dialectics/protocols/evaluative/rcp.cue",            "protocols/evaluative/rcp.opt.cue"),
    ("dialectics/protocols/exploratory/adp.cue",           "protocols/exploratory/adp.opt.cue"),
]

DIVIDER_PATTERN = re.compile(r'^\s*//\s*(─|===|---)')
COMMENT_ONLY_PATTERN = re.compile(r'^\s*//')
BLANK_PATTERN = re.compile(r'^\s*$')
MAX_CHARS = 16000


def is_comment_only(line):
    """True if line is a comment-only line (starts with //, no CUE code)."""
    stripped = line.strip()
    return stripped.startswith('//') or stripped == ''


def is_divider(line):
    """True if line is a visual divider comment."""
    return bool(DIVIDER_PATTERN.match(line))


def strip_content(raw_text):
    """
    Apply stripping rules to raw CUE file content.

    Algorithm:
    1. Scan lines and identify runs of comment-only lines.
    2. A run of 3+ consecutive comment-only lines is a block comment section.
       Block comment sections are stripped entirely.
    3. Divider lines are stripped even when isolated.
    4. Short comment groups (1-2 lines) are preserved.
    5. Multiple consecutive blank lines are collapsed to one.
    """
    lines = raw_text.splitlines(keepends=True)
    n = len(lines)

    # First pass: mark lines for removal
    # We work with line content (strip trailing newline for analysis)
    stripped_lines = [l.rstrip('\n') for l in lines]

    # Identify contiguous blocks of comment-only (or blank) lines
    # We need to find runs of 3+ pure-comment lines and strip them
    # Also strip dividers anywhere

    # Build groups of consecutive comment-only lines (ignoring blanks between)
    # Strategy: find maximal spans where every non-blank line is comment-only
    # and the span has 3+ comment-only lines → strip all of them

    remove = [False] * n

    i = 0
    while i < n:
        line = stripped_lines[i]

        # Always strip divider lines
        if is_divider(line):
            remove[i] = True
            i += 1
            continue

        # Detect runs of comment-only lines (skip blanks within the run)
        if COMMENT_ONLY_PATTERN.match(line) and not is_divider(line):
            # Find the extent of this comment run
            # A run ends when we hit a line that has CUE code (non-comment, non-blank)
            j = i
            comment_count = 0
            run_end = i

            while j < n:
                l = stripped_lines[j]
                if BLANK_PATTERN.match(l):
                    # Blank line: might be within the run or ending it
                    # Look ahead: if next non-blank is a comment, continue run
                    # If next non-blank is CUE code, end run here
                    k = j + 1
                    while k < n and BLANK_PATTERN.match(stripped_lines[k]):
                        k += 1
                    if k < n and COMMENT_ONLY_PATTERN.match(stripped_lines[k]) and not is_divider(stripped_lines[k]):
                        # Next non-blank is also a comment: include blanks in run
                        j = k
                        continue
                    else:
                        # Next non-blank is CUE code or EOF: run ends before this blank
                        break
                elif COMMENT_ONLY_PATTERN.match(l):
                    comment_count += 1
                    run_end = j
                    j += 1
                else:
                    # CUE code line: run ends
                    break

            if comment_count >= 3:
                # Block comment: strip all lines from i to run_end (inclusive)
                for k in range(i, run_end + 1):
                    remove[k] = True
                i = run_end + 1
            else:
                # Short comment group (1-2 lines): preserve
                i += 1
        else:
            i += 1

    # Second pass: build output, collapsing multiple blank lines
    result_lines = []
    prev_blank = False

    for i, line in enumerate(stripped_lines):
        if remove[i]:
            continue

        is_blank = BLANK_PATTERN.match(line)

        if is_blank:
            if not prev_blank:
                result_lines.append('')
            prev_blank = True
        else:
            result_lines.append(line)
            prev_blank = False

    # Strip leading/trailing blank lines
    while result_lines and result_lines[0] == '':
        result_lines.pop(0)
    while result_lines and result_lines[-1] == '':
        result_lines.pop()

    return '\n'.join(result_lines) + '\n'


def process_file(src_rel, dst_rel):
    """Process one file: read, strip, write, report."""
    src_path = os.path.join(BASE_DIR, src_rel)
    dst_path = os.path.join(BASE_DIR, dst_rel)

    if not os.path.exists(src_path):
        print(f"  ERROR: source not found: {src_path}")
        return False

    with open(src_path, 'r', encoding='utf-8') as f:
        raw = f.read()

    stripped = strip_content(raw)

    raw_size = len(raw)
    stripped_size = len(stripped)
    reduction_pct = (1 - stripped_size / raw_size) * 100 if raw_size > 0 else 0

    # Create output directory
    os.makedirs(os.path.dirname(dst_path), exist_ok=True)

    with open(dst_path, 'w', encoding='utf-8') as f:
        f.write(stripped)

    # Warnings
    warn = ''
    if stripped_size > MAX_CHARS:
        warn = ' [WARNING: EXCEEDS 16K]'
    if reduction_pct < 15:
        warn += ' [WARNING: low reduction — may be too conservative]'
    if reduction_pct > 80:
        warn += ' [WARNING: high reduction — may be too aggressive]'

    fname = os.path.basename(dst_rel)
    print(f"  {fname:<30} {raw_size:>6} → {stripped_size:>6} chars  ({reduction_pct:.0f}% reduction){warn}")
    return stripped_size <= MAX_CHARS


def main():
    print("strip_cue.py — generating optimized protocol files")
    print(f"Base: {BASE_DIR}")
    print()

    all_ok = True
    for src_rel, dst_rel in FILE_MAP:
        ok = process_file(src_rel, dst_rel)
        if not ok:
            all_ok = False

    print()
    if all_ok:
        print(f"Done. {len(FILE_MAP)} files generated. All under {MAX_CHARS:,} chars.")
    else:
        print(f"Done with WARNINGS. Some files exceed {MAX_CHARS:,} chars — review required.")
        sys.exit(1)


if __name__ == '__main__':
    main()

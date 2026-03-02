---
phase: quick-1
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - .claude-plugin/marketplace.json
  - socrates/.claude-plugin/plugin.json
autonomous: true
requirements: []
must_haves:
  truths:
    - "Plugin is referenced as socrates-cc@socrates in install commands"
    - "Marketplace name is 'socrates' (not 'socrates-marketplace')"
    - "Plugin name is 'socrates-cc' (not 'socrates-skill')"
    - "Plugin and marketplace names remain distinct (avoids EXDEV bug #24389)"
  artifacts:
    - path: ".claude-plugin/marketplace.json"
      provides: "Marketplace catalog with renamed identifiers"
      contains: "\"name\": \"socrates\""
    - path: "socrates/.claude-plugin/plugin.json"
      provides: "Plugin manifest with renamed identifier"
      contains: "\"name\": \"socrates-cc\""
  key_links:
    - from: ".claude-plugin/marketplace.json"
      to: "socrates/.claude-plugin/plugin.json"
      via: "plugins[0].name must match plugin.json name"
      pattern: "\"name\": \"socrates-cc\""
---

<objective>
Rename the plugin from `socrates-skill` to `socrates-cc` and the marketplace from `socrates-marketplace` to `socrates` so the install command becomes `/plugin install socrates-cc@socrates`.

Purpose: Cleaner naming — `socrates-cc` communicates "Socrates for Claude Code" and `socrates` is the natural marketplace name for the repo.
Output: Updated marketplace.json and plugin.json with new names.
</objective>

<execution_context>
@/Users/javier/.claude/get-shit-done/workflows/execute-plan.md
@/Users/javier/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.claude-plugin/marketplace.json
@socrates/.claude-plugin/plugin.json
</context>

<tasks>

<task type="auto">
  <name>Task 1: Rename marketplace and plugin identifiers in JSON configs</name>
  <files>.claude-plugin/marketplace.json, socrates/.claude-plugin/plugin.json</files>
  <action>
Update `.claude-plugin/marketplace.json`:
- Change `"name": "socrates-marketplace"` to `"name": "socrates"`
- Change `plugins[0].name` from `"socrates-skill"` to `"socrates-cc"`
- All other fields remain unchanged (owner, source, description, version, homepage, repository, tags)

Update `socrates/.claude-plugin/plugin.json`:
- Change `"name": "socrates-skill"` to `"name": "socrates-cc"`
- All other fields remain unchanged (description, author, homepage, repository, license)

Do NOT change:
- The `socrates/` directory name (it is the plugin content root, not the plugin identifier)
- The SKILL.md `name: socrates` frontmatter (that is the skill name within the plugin, which controls the `/socrates` slash command)
- The `source: "./socrates"` path in marketplace.json (still correct)
- Any hook files, scripts, or Makefile paths
  </action>
  <verify>
    <automated>cat .claude-plugin/marketplace.json | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['name']=='socrates', f'marketplace name={d[\"name\"]}'; assert d['plugins'][0]['name']=='socrates-cc', f'plugin name={d[\"plugins\"][0][\"name\"]}'; assert d['plugins'][0]['source']=='./socrates', 'source path changed'; print('marketplace.json: OK')" && cat socrates/.claude-plugin/plugin.json | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['name']=='socrates-cc', f'plugin name={d[\"name\"]}'; print('plugin.json: OK')"</automated>
  </verify>
  <done>
- marketplace.json has name "socrates" and plugins[0].name "socrates-cc"
- plugin.json has name "socrates-cc"
- Names are distinct (socrates-cc != socrates) so EXDEV bug is avoided
- Install command is now `/plugin install socrates-cc@socrates`
  </done>
</task>

</tasks>

<verification>
1. `cat .claude-plugin/marketplace.json` shows `"name": "socrates"` at top level and `"name": "socrates-cc"` in plugins array
2. `cat socrates/.claude-plugin/plugin.json` shows `"name": "socrates-cc"`
3. `python3 -c "import json; m=json.load(open('.claude-plugin/marketplace.json')); p=json.load(open('socrates/.claude-plugin/plugin.json')); assert m['name'] != m['plugins'][0]['name'], 'EXDEV: names must differ'; assert m['plugins'][0]['name'] == p['name'], 'name mismatch'; print('All checks pass')"` exits 0
</verification>

<success_criteria>
- Plugin installs as `socrates-cc@socrates` (marketplace name: socrates, plugin name: socrates-cc)
- Both names are distinct (EXDEV bug avoidance confirmed)
- No other files affected — hooks, SKILL.md, Makefile, scripts all unchanged
</success_criteria>

<output>
After completion, create `.planning/quick/1-rename-the-plugin-to-socrates-cc-and-the/1-SUMMARY.md`
</output>

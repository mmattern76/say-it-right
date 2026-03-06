---
description: Wrap up the current story. Tests, lint, commit, push, create PR, move to Ready for QA.
argument-hint: [optional story-id, defaults to current story]
---

## Resolve which story to complete

If $ARGUMENTS is provided, use that as the story ID.
Otherwise, read the current story:
```bash
cat .claude/current-story.json
```
Extract story_id and issue_number. If the file doesn't exist, ask which story.

## Run checks

1. Determine what needs testing:

   **If Swift code was changed:**
   ```bash
   swift build 2>&1 | tail -30
   ```

   **If scripts were changed:**
   ```bash
   shellcheck scripts/*.sh 2>/dev/null || true
   ```

2. If builds/tests fail, fix and re-run (up to 3 attempts).

## Commit and push

3. Stage and commit:
   ```bash
   git add -A
   git commit -m "feat(<story_id>): <one-line summary>"
   ```
4. Push:
   ```bash
   git push origin HEAD:feat/<issue_number>-<slug>
   ```

## Create pull request

5. Build a detailed PR description from the session work. Include:
   - What was built (specific files and functions)
   - Key design decisions
   - Acceptance criteria checklist
   - Anything noteworthy

6. Create the PR:
   ```bash
   gh pr create \
     --base main \
     --head feat/<issue_number>-<slug> \
     --title "feat(<story_id>): <concise summary>" \
     --body "## Summary
   <description>

   ## Changes
   <bullet list>

   ## Acceptance Criteria
   <checklist>

   ## Design Decisions
   <reasoning>

   Closes #<issue_number>"
   ```

**Do NOT merge.** It stays open until QA passes.

## Move issue to "Ready for QA"

```bash
./scripts/gh-move-issue.sh <issue_number> ready-for-qa
```

## Update MEMORY.md

Append to `.claude/MEMORY.md`:

```markdown
## SIR-NNN: <title> (completed)

**Files created/modified:** <list>
**Patterns established:**
- <pattern>

**Gotchas:**
- <surprises>

**Key decisions:**
- <decision and reasoning>
```

## Clean up

```bash
rm -f .claude/current-story.json
```

## Suggest QA review

Print:
```
PR created -> issue moved to Ready for QA.
When ready:
  claude
  /rename sir-qa-SIR-NNN
  /qa:review-story SIR-NNN
```

## Session reset (conditional)

- If `.claude/sprint-state.json` does NOT exist -> reset with `/compact`
- If it exists -> called from implement-all or implement-epic, do NOT reset (the caller manages session lifecycle)

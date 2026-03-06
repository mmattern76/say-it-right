---
description: Autonomous epic runner. Implements all stories for one or more epics in dependency order, regardless of board status.
argument-hint: <epic-ids, e.g. E1 or E1 E2 E3>
---

This command implements every story belonging to the specified epic(s), regardless
of whether they are in Todo, Backlog, or any other board column. Only skips stories
that are already Done or have a merged PR.

Does NOT reset session between stories. Re-reads MEMORY.md after each.
Sprint progress persisted to `.claude/sprint-state.json` for resume.

## Phase 1: Build the work queue (or resume)

### Resuming a previous run

If `.claude/sprint-state.json` exists:
1. Read sprint state — this is the **sole source of truth** for progress
2. Re-read `.claude/MEMORY.md`
3. Skip stories with status `completed`, `failed`, or `skipped`
4. If a story has status `in_progress`, it was interrupted mid-work:
   - Check if a branch and PR already exist for it
   - If PR exists and is merged: mark `completed`, continue
   - If PR exists but not merged: resume from QA step
   - If no PR: clean up partial branch (`git checkout main`), retry from scratch
5. Continue from next `pending` story

### Starting fresh

1. Parse $ARGUMENTS as a space-separated list of epic IDs (e.g. "E1 E2 E3").

2. Fetch ALL stories for the specified epics (any board status except Done):
   ```bash
   REPO_OWNER=$(gh repo view --json owner -q '.owner.login')
   REPO_NAME=$(gh repo view --json name -q '.name')
   PROJECT_ID=$(gh api graphql -f query='
     query($owner: String!, $repo: String!) {
       repository(owner: $owner, name: $repo) {
         projectsV2(first: 10) {
           nodes { id title closed }
         }
       }
     }' -f owner="$REPO_OWNER" -f repo="$REPO_NAME" \
     --jq '[.data.repository.projectsV2.nodes[] | select(.closed == false)] | first | .id')

   gh api graphql -f query='
     query($projectId: ID!) {
       node(id: $projectId) {
         ... on ProjectV2 {
           items(first: 100) {
             nodes {
               fieldValueByName(name: "Status") {
                 ... on ProjectV2ItemFieldSingleSelectValue { name }
               }
               content {
                 ... on Issue {
                   number title body state
                   milestone { title }
                   labels(first:10) { nodes { name } }
                 }
               }
             }
           }
         }
       }
     }' -f projectId="$PROJECT_ID" \
     --jq '[.data.node.items.nodes[]
       | select(.fieldValueByName.name != "Done")
       | select(.content.state == "OPEN")
       | select(.content.labels.nodes | map(.name) | any(. == "story"))
       | select(.content.labels.nodes | map(.name) | any(test("epic:e[0-9]+")))
       | .content
     ]'
   ```
   Filter to stories whose `epic:eN` label matches any of the requested epics.

   If the project board is not set up yet, fall back to label-based query:
   ```bash
   # For each epic ID (e.g. E1, E2, E3):
   gh issue list --label "story,epic:e${N}" --state open --json number,title,body,labels --jq '.'
   ```

3. Parse dependencies: `Depends on:\s*(SIR-\d+(?:\s*,\s*SIR-\d+)*)`

4. Topological sort across all requested epics. Circular dependency = stop.

5. Write `.claude/sprint-state.json` with the full queue and start:
   ```json
   {
     "command": "implement-epic",
     "epics": ["E1", "E2"],
     "started_at": "<ISO 8601>",
     "queue": [
       {
         "story_id": "SIR-001",
         "issue_number": 5,
         "epic": "E1",
         "depends_on": [],
         "status": "pending",
         "pr": null
       }
     ],
     "current_index": 0,
     "prs_created": []
   }
   ```
   Valid `status` values: `pending`, `in_progress`, `completed`, `failed`, `skipped`.

## Phase 2: Execute stories

For each story in order:

### Pre-flight
1. Re-read `.claude/MEMORY.md` (source of cross-story knowledge)
2. Re-read `.claude/sprint-state.json` (source of truth for queue progress — critical after session compaction)
3. Check dependencies (skip if blocked by failed story; set status to `skipped` and write sprint-state)
4. `git checkout main && git pull`
5. Set current story's `status` to `in_progress` in sprint-state.json and write to disk
6. Move issue to "In Progress":
   ```bash
   ./scripts/gh-move-issue.sh <issue_number> in-progress
   ```

### Step A: Implement
- Create branch: `git checkout -b feat/<issue_number>-<slug>`
- Read `docs/product-spec.md` and relevant epic file
- Read `prompts/barbara-system-prompt.md` if touching intelligence layer
- Implement based on acceptance criteria
- Follow conventions from CLAUDE.md and patterns from MEMORY.md
- Validate: `swift build 2>&1 | tail -30` (3 fix attempts)
- Commit, push, create PR with `Closes #<issue_number>`

### Step B: QA (inline)
- Acceptance criteria audit
- Structural pedagogy check (Barbara evaluates structure not content, hidden metadata, modular prompt)
- Build verification
- Fix small/medium issues directly
- Blocking issues -> file bug, set status to `failed` in sprint-state.json, write to disk, continue

### Step C: Merge
- Squash-merge PR, close issue
- Move issue to Done:
  ```bash
  ./scripts/gh-move-issue.sh <issue_number> done
  ```
- Append learnings to `.claude/MEMORY.md` using this format:
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
- Update `.claude/sprint-state.json`:
  - Set current story's `status` to `completed` and `pr` to the PR number
  - Add PR number to `prs_created` array
  - Increment `current_index`
  - **Write the file to disk immediately** — this is the crash-recovery checkpoint

## Phase 3: Sprint report

```
===========================================
  Epic Sprint Complete: <E1 E2 E3>
===========================================
  Completed: N/M
  Failed:    N/M
  Skipped:   N/M

  PRs merged: ...
  Failed stories: ...
  Blocked stories: ...
===========================================
```

## Phase 4: Clean up

After printing the report:
- Set `completed_at` in sprint-state.json
- Delete `.claude/sprint-state.json` only if ALL stories completed successfully
- If any failed/skipped: leave sprint-state.json on disk for potential resume

## Stopping rules

Only stop for: circular dependency, git conflict, infrastructure failure, all remaining blocked.
Do NOT stop for: single story failure (skip dependents), board move failure, PR creation failure (retry once).

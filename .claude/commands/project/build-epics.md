---
description: "Full lifecycle: analyze -> refine -> implement for one or more epics. Pauses for human input when concerns arise."
argument-hint: <epic-ids, e.g. "E1" or "E2 E3 E4">
---

This command runs the full epic lifecycle — from raw epic doc to merged code —
for one or more epics. It runs each phase across ALL epics before moving to the
next phase, pausing for human input only once per phase if concerns were found.

## Parse arguments

$ARGUMENTS contains one or more epic IDs separated by spaces (e.g. "E1 E2 E3").

## Execution order

Phases run across all epics before advancing:

```
Phase 1: Create stories for E1, E2, E3 -> pause if concerns
Phase 2: Refine stories for E1, E2, E3 -> pause if concerns
Phase 3: Implement E1 fully, then E2 fully, then E3 fully
```

Phase 3 is sequential per epic (all stories merged before starting next epic)
because later epics may depend on earlier epics' code.

---

## Phase 1: Create stories for ALL epics (`/analyst:analyze-epic` logic)

**Model: Use Opus for this phase.** Dispatch via `Agent` tool with `model: "opus"`.

Adopt the **Analyst persona**. You are NOT a builder — you think like a product
analyst. Your output is GitHub Issues.

### Load context (once)

1. Read `CLAUDE.md` and `.claude/MEMORY.md`
2. Read `docs/PROJECT_SPEC.md`

### For each epic in $ARGUMENTS

1. Read the epic file from `docs/epics/`.

2. Check what stories already exist:
   ```bash
   gh issue list --label "epic:E${N}" --state all --json number,title,state \
     --jq '.[] | "\(.state)\t#\(.number)\t\(.title)"'
   ```

3. If stories already exist for this epic, note it and skip creation.

4. If no stories exist, create them following the full `/analyst:analyze-epic` procedure.

5. Collect **concerns** for this epic (don't pause yet).

### After ALL epics have been analyzed — decision point

If there are ANY concerns across any epic, present them once and wait for user input.
If no concerns, proceed automatically.

---

## Phase 2: Refine stories for ALL epics (`/analyst:refine-epic` logic)

**Model: Use Opus for this phase.** Dispatch via `Agent` tool with `model: "opus"`.

Still in Analyst persona. Review and update each story's acceptance criteria,
dependencies, and scope. Collect concerns, present once, wait if needed.

After resolving concerns, move all stories to **Todo**:
```bash
for issue_number in <list>; do
  ./scripts/gh-move-issue.sh $issue_number Todo
done
```

---

## Phase 3: Implement epics sequentially (`/project:implement-all` logic)

**Model: Use Sonnet for this phase.** Dispatch via `Agent` tool with `model: "sonnet"`.

Switch to **Builder persona**. Process epics **one at a time** (E1 fully merged
before E2 starts).

For each epic, follow the full `/project:implement-all` procedure filtered to
that epic's label.

---

## After all epics are processed

Print a final combined summary:

```
===========================================
  Build Complete — Epics: E<X>, E<Y>, E<Z>
===========================================

  Epic E<X>: <title>
    Stories: N created, N refined, N implemented
    PRs merged: #AA, #BB, #CC
    Failed: <list or "none">

  ...

  Total: XX stories across YY epics
===========================================
```

## Key rules

- **Batch phases, sequential implementation.** Phases 1 and 2 run across all
  epics before pausing. Phase 3 runs one epic at a time (code dependencies).

- **Two pause points maximum.** Once after all creation, once after all
  refinement. Only if concerns exist. No pausing during implementation.

- **Persona switching is explicit.** Phases 1-2 are Analyst (no code). Phase 3
  is Builder (code). Don't mix them.

- **Resume support.** If interrupted mid-epic, the sprint state file tracks
  implementation progress.

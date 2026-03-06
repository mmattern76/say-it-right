---
description: Fully autonomous story lifecycle. Loads a story, implements it, tests, and completes with PR. No confirmations.
argument-hint: <story-id or next>
---

This command runs the full story lifecycle end-to-end without pausing.
Session resets at the end (via complete-story) since there is no sprint-state.json.

## Phase 1: Start

Run `/project:start-story $ARGUMENTS` — this will:
- Read `.claude/MEMORY.md` for context from previous stories
- Resolve the story (by ID or "next" from Todo)
- Write `.claude/current-story.json`
- Move issue to "In Progress"
- Load context from product-spec, relevant epic, and issue body
- Begin implementation immediately

## Phase 2: Implement

Implement the story based on acceptance criteria. Follow these rules:

- Work through each acceptance criterion systematically
- Write tests alongside implementation (at minimum for intelligence layer)
- Follow conventions from CLAUDE.md
- Follow patterns from MEMORY.md
- SwiftUI previews for every view
- Structured concurrency (async/await, no Combine)
- API key in Keychain — never in code or UserDefaults
- For intelligence layer: validate system prompt assembly, structural evaluation, response parsing
- For presentation: ensure platform-adaptive behavior (voice-first iPhone, visual iPad, keyboard Mac)

## Phase 3: Validate

Run checks:

```bash
swift build 2>&1 | tail -30
```

Fix loop up to 3 attempts. If still failing, stop and report.

## Phase 4: Complete

Once checks pass, run `/project:complete-story` — this will:
- Commit with descriptive message
- Push to `feat/<issue_number>-<slug>` branch
- Create detailed PR
- Move issue to "Ready for QA"
- Append learnings to `.claude/MEMORY.md`
- Clean up and reset session

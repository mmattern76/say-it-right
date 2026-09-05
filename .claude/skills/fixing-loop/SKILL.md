---
name: fixing-loop
description: Autonomous QA→fix loop for Say it right!. Runs Geppetto smoke + manual UI testing, files bugs as GitHub issues, optionally uses /codex for root-cause analysis, dispatches builder subagents to fix each issue, then repeats until a clean pass or the user stops it.
---

# /fixing-loop — Autonomous QA Fix Loop (Say it right!)

Continuous loop: build → install → drive UI via Geppetto → file bug issues for findings →
analyze with Codex (optional) → fix each issue in an isolated worktree → repeat. Stops on
a clean pass, user interrupt, or the safety limit.

This is the **project-scoped** version of the fixing-loop skill. It assumes the
Say it right! repo layout, the Anthropic-API-backed Barbara, and the
`SIR_TTS_DISABLED=1` launch-environment override added in SIR-076 so
audio playback never interferes with automation.

## Prerequisites

- Geppetto MCP tools available (`screenshot`, `tap`, `tap_element`, `swipe`,
  `launch_app`, `terminate_app`, `set_project`, `list_devices`)
- `gh` CLI authenticated (`gh auth status` succeeds)
- App builds (`xcodebuild` works against `app/SayItRight/SayItRight.xcodeproj`)
- `xcodegen` on PATH (sources are regenerated before each build)
- Optional: `codex` binary on PATH for root-cause analysis. The loop runs without it.
- Optional: a valid Anthropic API key bundled in `Config.plist` or supplied via
  `ANTHROPIC_API_KEY_OVERRIDE` env var — without it, Barbara can't respond and
  any session-flow test will fail at the chat step.

## App constants

| Setting | Value |
|---|---|
| Scheme (iOS) | `SayItRight_iOS` |
| Scheme (macOS) | `SayItRight_macOS` |
| Project | `app/SayItRight/SayItRight.xcodeproj` |
| Bundle ID | `io.mattern.say-it-right` |
| Default simulator | `iPhone 17 Pro` |
| iPad simulator | `iPad Pro 13-inch (M4)` |
| Test case canon | `docs/testing/02-test-cases.md` |
| Screen map | `docs/testing/01-screen-map.md` |
| Accessibility ids | `docs/testing/03-test-automation.md` |

## Loop structure

Each iteration runs the steps below in order. State is persisted to
`fixing-loop-state.json` at the repo root after every step.

### Step 1: Build and install

```bash
# Make sure the Xcode project picks up any new sources / config
(cd app/SayItRight && xcodegen generate)

# Resolve the Geppetto device UDID (created on first run if missing).
DEVICE_NAME="Geppetto (say-it-right)"
DEVICE_ID=$(xcrun simctl list devices --json \
  | jq -r --arg n "$DEVICE_NAME" '.devices | to_entries[].value[] | select(.name == $n) | .udid' \
  | head -1)

# Fallback to the standard iPhone 17 Pro simulator if Geppetto's device isn't set up
if [ -z "$DEVICE_ID" ]; then
  DEVICE_ID=$(xcrun simctl list devices --json \
    | jq -r '.devices | to_entries[].value[] | select(.name == "iPhone 17 Pro") | .udid' \
    | head -1)
fi

xcrun simctl boot "$DEVICE_ID" 2>/dev/null || true

xcodebuild \
  -project app/SayItRight/SayItRight.xcodeproj \
  -scheme SayItRight_iOS \
  -configuration Debug \
  -destination "id=$DEVICE_ID" \
  build 2>&1 | tail -40

# Locate the freshly built .app and install it
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/SayItRight-*/Build/Products/Debug-iphonesimulator \
  -maxdepth 1 -name "SayItRight.app" -print -quit)
xcrun simctl install "$DEVICE_ID" "$APP_PATH"
```

If the build fails: diagnose the error, fix it directly in code (not as a bug
issue), and retry. Three consecutive build failures abort the loop with status
`build_failed`.

### Step 2: Launch with the testing-friendly environment

Always launch with the silent-mode + text-only overrides and a clean state
hint for the first iteration. `simctl launch` doesn't accept `--setenv`; pass
env vars via the `SIMCTL_CHILD_<VAR>` prefix on the shell that invokes it:

```bash
SIMCTL_CHILD_SIR_TTS_DISABLED=1 \
SIMCTL_CHILD_SIR_FORCE_TEXT_INPUT=1 \
SIMCTL_CHILD_ANTHROPIC_API_KEY_OVERRIDE="$TEST_ANTHROPIC_API_KEY" \
  xcrun simctl launch "$DEVICE_ID" io.mattern.say-it-right
```

- `SIR_TTS_DISABLED=1` — silent mode (SIR-076). Barbara never speaks.
- `SIR_FORCE_TEXT_INPUT=1` — text-only mode. The iPhone-compact voice
  variants of session views are bypassed in favour of the regular text-input
  views. STT (microphone) is not invoked.

Then `set_project` via Geppetto so subsequent MCP calls target this device.

### Step 3: Geppetto QA pass

Walk the canonical test cases in `docs/testing/02-test-cases.md`. For the
smoke tier (used by default in the loop), exercise:

1. **G1 — First launch & onboarding**
   - Fresh state: API key entry → language picker → onboarding (avatar + name)
   - Landing on `SessionPickerView`
2. **G2 — Main hub**
   - All session cards visible (8 cards: Sag's klar, Finde den Punkt,
     30 Sekunden, Räum das auf, Finde die Lücke, Bau die Pyramide,
     Entschlüsseln, Analysiere meinen Text)
   - Toolbar buttons exist (`settingsButton`, `progressButton`)
3. **G3 — Build mode: Say It Clearly**
   - Tap card → topic appears → type a response → send → Barbara responds
   - Hidden `BARBARA_META` comment is parsed (not visible in UI)
   - End Session returns to hub
4. **G4 — Break mode: Find the Point**
   - Practice text is displayed (not empty) → submit governing thought →
     Barbara evaluates against answer key
5. **G6 — Parent Settings**
   - Tap settings → unlock with PIN if set → verify the **Silent mode toggle
     (`settings.silentMode.toggle`)** is present and reflects the env override
     when set
   - Model picker, API key override, level override, debug toggle all render
6. **G7 — Progress dashboard**
   - Tap progress button → dashboard or empty state renders
7. **G11 — Localization**
   - Re-launch with German language → verify Sag's klar UI text appears

For the **full tier** (`--tier full`), additionally walk G5 (Pyramid builder
on iPad), G8 (chat cross-cutting), G9 (error handling), G10 (platform
adaptation), G12 (persistence). On iPhone-only runs, mark iPad/Mac groups as
N/A rather than failing them.

Take a `screenshot` at each major step. Use `accessibility_tree` /
`find_element` to verify identifiers from
`docs/testing/03-test-automation.md` are present.

For any unexpected state (crash, blank screen, missing element, wrong
language, Barbara silent when she shouldn't be, etc.) record:
- The expected test case ID (`T-NNN` if any)
- The screen ID (`SNN` from `01-screen-map.md`)
- A short repro path (the tap sequence to reach it)
- The screenshot path

### Step 4: Triage findings

For each new issue:

```bash
# Search existing bug issues to avoid duplicates
gh issue list --label bug --state open --json number,title \
  --jq '.[] | select(.title | test("<keyword>"; "i"))'
```

If no match exists, create a new bug issue:

```bash
gh issue create \
  --title "BUG: <one-line summary> (T-NNN, S<screen-id>)" \
  --label "bug,epic:e<N>" \
  --body "$(cat <<EOF
## Severity
<critical|high|medium|low>

## Test case
T-NNN — <case title from 02-test-cases.md>

## Screen
S<NN> — <screen name from 01-screen-map.md>

## Steps to reproduce
1. ...
2. ...

## Expected
<from test case>

## Actual
<observed>

## Evidence
- Screenshot: <path or attached>
- Geppetto session: iteration <N> of /fixing-loop
EOF
)"
```

Add the new issue number to `fixing-loop-state.json` → `issues_found`.

Also add the issue to the project board (the gh-move-issue.sh helper paginates
only the first 100 items, so newly created issues sometimes land on a later
page — add via GraphQL if the helper fails):

```bash
./scripts/gh-move-issue.sh <issue_number> todo 2>/dev/null \
  || echo "Issue $issue_number created but not yet on project board"
```

If **zero new issues** are found in this iteration → print `CLEAN PASS`, set
state.status to `complete`, and stop the loop.

### Step 5: Root-cause analysis (optional, when Codex is available)

If `command -v codex` succeeds, send a structured prompt:

```bash
codex exec "Analyze these bugs in the Say it right! repo. For each, give:
file path, line numbers, root cause, and the minimal fix.

Bugs:
$(for i in $ISSUE_NUMBERS; do gh issue view $i --json title,body; done)

Repo conventions: Swift 6, SwiftUI, 4-layer architecture (Presentation,
Intelligence, State, Content). All Barbara responses include a hidden
BARBARA_META JSON postscript. TTS is disabled at runtime when
SIR_TTS_DISABLED=1 or AppSettings.isTTSDisabled is true." \
  -C "$(pwd)" -s read-only \
  -c 'model_reasoning_effort="high"' --enable web_search_cached
```

Append Codex's analysis to each issue as a comment (`gh issue comment $N -F -`).

If Codex is unavailable, the builder subagent in Step 6 does its own
investigation — slower but functional.

### Step 6: Dispatch fixer subagents

For each open bug, run one Agent (`subagent_type: general-purpose`,
`isolation: worktree`) per issue **sequentially** — parallel agents cause
merge conflicts in `project.pbxproj`, `SessionManager.swift`,
`SessionType.swift`, and other shared files (see `.claude/MEMORY.md`).

Prompt template for each fixer agent:

```
You are fixing GitHub issue #<N> in the Say it right! repo. Read the issue
body first. <Optional: paste Codex's RCA.>

Repo conventions (already in CLAUDE.md — re-read it):
- Branch name: feat/<N>-<short-slug>
- Conventional commits
- scripts/lint.sh must not regress vs main (run before completing)
- Update docs/testing/02-test-cases.md if behavior changed
- Update docs/testing/03-test-automation.md if accessibility ids changed
- Open the PR via `gh pr create` and link the issue with "Closes #<N>"

When done, return the PR URL.
```

Wait for each fixer agent to finish, then merge its PR if CI passes:

```bash
gh pr merge <PR> --squash --auto
```

After all merges, pull `main` and re-run from Step 1.

### Step 7: Update state, repeat

After each iteration, update `fixing-loop-state.json`:

```json
{
  "iteration": <N>,
  "started_at": "<ISO 8601 of loop start>",
  "issues_found": [<all bug issue numbers across iterations>],
  "issues_fixed": [<resolved>],
  "prs_merged": [<PR numbers>],
  "status": "<testing|fixing|complete|build_failed|interrupted>",
  "qa_summary": {
    "verified_working": [...],
    "remaining_issues": [...]
  }
}
```

Commit this file at the end of every iteration so progress survives if the
loop is interrupted. Add `fixing-loop-state.json` to `.gitignore` if the user
prefers to keep it untracked — by default it is committed for visibility.

## Stop conditions

- User interrupts (Ctrl+C / explicit "stop the loop" message)
- Clean Geppetto pass (Step 3 finds zero new issues) → `status = "complete"`
- 10 consecutive iterations → `status = "safety_limit"`
- 3 consecutive build failures in Step 1 → `status = "build_failed"`
- Anthropic API rate-limit or auth error that persists across iterations
  (Barbara needs the API for session-flow tests) → `status = "api_blocked"`

## Output

Each iteration prints a one-line status to the user, e.g.:

```
[iter 3] built; QA found 2 new bugs (#178, #179); codex analyzed; fixers running…
[iter 3] merged #180, #181; loop continues.
[iter 4] CLEAN PASS — stopping.
```

When the loop ends, print the final summary table from
`fixing-loop-state.json`.

## Notes

- Geppetto can't reliably observe audio; SIR-076's silent mode override is
  not optional in this loop — keep `SIR_TTS_DISABLED=1` in the launch
  environment for every iteration
- Do **not** use this loop to drive content/curriculum stories — those need
  human judgement on Barbara's pedagogy. Restrict to UI, navigation, and
  state-shape bugs
- If the loop runs against a branch (rather than `main`), preserve that
  branch as the base for fixer worktrees — don't switch to `main` mid-loop

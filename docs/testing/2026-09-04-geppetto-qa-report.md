# Geppetto QA findings — feat/174-silent-mode-toggle (iPhone 17 Pro, SIR_TTS_DISABLED=1)

## Status after the fix pass (2026-09-04)

| ID | Finding | Status |
|----|---------|--------|
| F10 | Pyramid/fix-this-mess exercise JSON never decodes | **Fixed** — `PyramidAnswerKey` decodes `redHerringBlockIDs` with `decodeIfPresent`; both libraries now log + assert instead of returning an empty library silently. Verified on device: "Bau die Pyramide" loads an exercise, iPad "Fix this mess (visual)" loads. |
| F1 | Raw `**markdown**` in chat bubbles | **Fixed** — `String.barbaraMarkdown` (inline-only, whitespace-preserving) used by `MessageBubbleView` and `FormattedFeedbackText`. Verified on device. |
| F2 | `BARBARA_META` visible while streaming | **Fixed** — `ResponseParser.visibleTextWhileStreaming(_:)` strips closed blocks and hides a partial opener; wired into both streaming paths. Unit tests cover every prefix of the block. |
| F9 | Elevator Pitch timer never starts when muted | **Fixed** — the countdown now starts when the opening message finishes streaming whenever Barbara will not speak; the TTS-finished path still drives it when audio is on. Verified on device (timer bar counted down in silent mode). |
| F5 | State layer unwired | **Fixed** — new `LearnerState` owns `LearnerProfileStore` + `SessionHistoryStore`, hands them to `SessionManager`, and republishes progress; `endSession()` writes a `SessionSummary`. Verified end to end: dashboard shows level, streak 1, 1 session, dimension bars and the session row; `learner-profile.json` + `session-history.json` on disk; survives relaunch. |
| F4 | 100% CPU SwiftUI update loop | **Not reproducible on the current build** — 9 attempts across the exact failing steps came back clean. Two contributing paths were removed (streaming scrolls no longer animate and are coalesced to 10/s; `streamBarbaraResponse` clears any lingering `isStreaming` flag on exit) and `sessionState` transitions are now logged so a recurrence is diagnosable in one command. See the entry below. |
| F6, F7, F8, F11, F12 | Toggle tap target, level names, duplicated text, localization, copy nits | Not addressed in this pass. |

Also fixed in passing: `AudioSessionManagerTests` read the device's real Silent Mode setting and failed
whenever it was on; `AudioSessionManager` now takes an injectable `isSilent` provider and the tests pin it.

Known pre-existing test failures on this branch, unrelated to these changes: `PyramidBlockTests`
(expects 3 `BlockType` cases, there are 4 since red herrings) and `SystemPromptAssemblerTests`
(prompt block resources not found from the test host).


## F1 — Raw markdown `**bold**` rendered literally in chat bubbles
- Screen: S07 VoiceSayItClearlyView (and any ChatView; Barbara's opening topic)
- Evidence: "Here's your topic: **Should there be a minimum age of 16 for social media?**"
- Cause: `MessageBubbleView.swift:57` `Text(message.text)` — String overload does not parse markdown.
  `FeedbackBubbleView.FormattedFeedbackText` also only handles quotes, not markdown.
- Severity: high (visible on every session's first screen)

## F2 — Hidden metadata `<!-- BARBARA_META: {...} -->` is visible while streaming
- Screen: every chat screen (C01), every Barbara turn
- Evidence: screenshot at 00:10 — raw JSON scrolls into the bubble mid-stream, then disappears
  once the stream finishes and ResponseParser strips it.
- Violates T-023 and the "hidden metadata" design rule.
- Cause: the metadata comment is only stripped after the full stream completes
  (SessionManager.streamBarbaraResponse: parse happens post-loop); during streaming
  `messages[i].text = fullText` includes the raw comment.
- Severity: high

## F3 — (not a bug) revision preload
- After Barbara asks for a revision, the composer is pre-filled with the learner's previous
  answer (ChatViewModel.preloadRevisionTextIfNeeded). Intentional. UX note: no affordance
  explains why the text reappeared.

## F4 — REPRODUCED: 100% CPU SwiftUI update loop in the iPhone voice-drill views
- Repro: iPhone, "Sag's klar" (voice variant), silent mode on. Open the session and wait for
  Barbara's opening message to finish streaming → the app pins a core at 100% and stays there
  indefinitely. Reproduced three times, including across a fresh install.
- `sample` puts the main thread in a continuous
  `UIUpdateSequence → GraphHost.flushTransactions → ScrollViewLayoutComputer / LazyStack.place`
  cycle; `TypingIndicatorView` appears in the stack.
- Narrowed by bisection:
  - plain `ChatView` sessions ("Analysiere meinen Text") stay at **0%** through the same flow,
    including a full scored evaluation → the chat view itself is not the cause
  - long text sitting in the composer with the keyboard up: **0%**
  - the loop starts when a Barbara message *completes*, in the voice-variant views only
- Side effect: XCUITest cannot reach quiescence, so all accessibility-driven automation dies
  until the app is killed — the bug hides itself from UI tests.
- Two mitigations already applied (they did not stop it): streaming scrolls no longer animate
  (`ChatView.scrollToBottom(proxy:animated:)`), and `streamBarbaraResponse` now clears any
  lingering `isStreaming` flag on exit so a stale typing indicator cannot animate forever.
### Follow-up pass (2026-09-04 08:30–08:55)

Nine reproduction attempts on the current build, all clean (CPU 0% throughout):

| Attempt | Flow | Result |
|---|---|---|
| 1 | Voice "Sag's klar", opening message only, nothing touched | 0% |
| 2 | + switch to Type | 0% |
| 3 | + keyboard up | 0% |
| 4 | + long text typed, not sent | 0% |
| 5 | send (~170 chars), full evaluation | 0% |
| 6 | send immediately after the opening completed (race attempt) | 0% |
| 7 | second send / revision round | 0% |
| 8 | voice "Finde den Punkt" (reading text + chat) | 0% |
| 9 | long send (~310 chars) in a voice view | 0% |

State instrumentation added to `SessionManager` (`sessionState` transitions, `os.Logger`,
`.debug` level) confirmed clean `loading → active` transitions with no stuck `isLoading`
or `isStreaming` flag in any attempt. A single accessibility snapshot on a long chat also
does not raise CPU.

Changes made during this pass:
- `ChatView` coalesces streaming scrolls to at most one per 100 ms (they were firing on
  every streamed chunk, dozens per second, each forcing a full list layout)
- `sessionState` transitions are logged, so a recurrence can be diagnosed with
  `xcrun simctl spawn <device> log stream --level debug --predicate 'subsystem == "io.mattern.say-it-right"'`

Not closed: the three original occurrences were real and all happened on builds without the
scroll and `isStreaming` fixes, or on the build where the scroll fix had only just landed.
Without a reproduction the causal chain is unproven. If it returns, the log above will show
whether the app is stuck in `.loading` — the first thing to check.
- Severity: high if it returns; currently unreproducible.

## F5 — CRITICAL: the whole State layer (profile + history) is never wired into the app
Observed: completed a full Say-it-clearly session (topic → answer → scored feedback →
revision → feedback → End Session). Progress dashboard still shows "No sessions completed yet".
App container has no Documents dir — nothing was written.

Code evidence:
- `App/SayItRightApp.swift:84` — `profile` is a *computed property* that builds a fresh
  `LearnerProfile.createDefault(...)` on every access. Nothing is loaded or saved.
- `LearnerProfileStore` is never instantiated outside `Tests/` (grep: no production caller).
- `SessionManager.profileStore` is therefore always nil, so `endSession()` skips
  `profileUpdater.applySessionResults(...)` → `sessionCount` never increments.
- `SessionHistoryStore` is never instantiated outside `Tests/`.
- `ProgressDashboardView(recentSessions:)` is never passed anything (defaults to []).

Consequences (all currently impossible in the shipped app):
- Progress dashboard永远 empty (T-140 passes only because nothing is ever recorded;
  T-141..T-147 unreachable)
- Session history screen unreachable / always empty (T-193)
- No streaks, no level-up (LevelTransitionEngine needs sessionCount + score history)
- Adaptive difficulty always behaves as "session 0"
- Learner profile block in the system prompt is always the default one → Barbara cannot
  adapt to strengths/weaknesses across sessions
Severity: critical

## F6 — Silent-mode toggle only responds to taps on the switch, not the row
- `ParentSettingsView:237` Toggle inside a custom card; tapping the label/row does nothing.
- Severity: low (a11y/usability)

## F7 — Level names are German in the English UI
- `ParentSettingsView:324-327` hardcodes "Level 1 — Klartext", "Level 2 — Ordnung", … regardless
  of `language`. English names exist elsewhere (`LevelTransitionEngine:82-85`,
  `ProgressDashboardView:254-257`: Plain Talk / Order / Architecture / Mastery).
- Severity: medium (localization)

## F8 — Break-mode: the practice text is shown twice
- Screen: S12 Find the point (voice variant)
- The full reading text appears in the READING TEXT card AND is repeated verbatim inside
  Barbara's chat bubble, complete with `---` rules and `**bold**` markers rendered literally.
- Severity: medium (UX + F1 markdown)

## F9 — HIGH: Elevator Pitch timer never starts when Barbara's voice is off
- Screen: S09 VoiceElevatorPitchView (iPhone)
- Repro: silent mode on (or the TTS toggle off) → open "The elevator pitch" → Barbara says
  "You have 30 seconds starting… now" → **no timer bar appears, no countdown, no auto-submit.**
- Cause: `VoiceElevatorPitchView.speakLatestBarbaraMessage()` starts the timer only inside the
  TTS `.finished` callback (line ~289), and that method early-returns on `guard ttsEnabled`.
  `NoOpTTSService.speak` (silent mode) never emits any event, so the callback never fires.
- Fix direction: start the timer when the opening Barbara message finishes streaming
  (`onChange(of: messages.last?.isStreaming)`), and keep the TTS path only as an additional
  trigger when audio is on.
- Severity: high — the exercise is defined by its time pressure; T-031/T-032/T-033 all fail.

## F10 — CRITICAL: "Build the pyramid" is always empty — the exercise JSON never decodes
- Observed: "Build the pyramid" → "No exercises available. There are no matching exercises for
  your current level." (at Level 2 override, English; the library has 3 matching English exercises)
- Root cause: `PyramidAnswerKey.redHerringBlockIDs` is `var redHerringBlockIDs: Set<String> = []`
  (`Intelligence/StructuralEvaluator/MECEValidationEngine.swift:17`). A default value does NOT make
  a key optional for a synthesized `Codable` — the key is still required at decode time.
  `pyramid-exercises.json` omits it for pe-001-en / pe-002-en / pe-001-de, so
  `JSONDecoder().decode([PyramidExercise].self, …)` throws, `PyramidExerciseLibrary.loadFromBundle()`
  swallows the error via `try?` and returns an EMPTY library. Every level and both languages are affected.
- Verified by decoding the bundled JSON with an equivalent struct:
  `DecodingError.keyNotFound: Key 'redHerringBlockIDs' not found … Path: [0].answerKey`
- Same trap hits `fix-this-mess-exercises.json` (all 3 exercises omit the key) →
  `FixThisMessExerciseLibrary` is empty too (iPad "Fix this mess" visual variant).
- Fix: make it `var redHerringBlockIDs: Set<String>? ` + accessor, or add an explicit
  `init(from:)` using `decodeIfPresent`, or add the key to every JSON exercise.
  Also: `loadFromBundle()` uses `try?` and silently returns an empty library — it should log/assert.
- Severity: critical (E6 "Pyramid Builder" epic is non-functional in the shipped app)

## F11 — Localization gaps in Settings / Parent Settings (German)
- `SettingsView`: navigation title "Settings", section headers "Display Name" and "About"
  stay English when the language is German (`SettingsView.swift:16` hardcodes the title).
- `ParentSettingsView`: **entirely English** — 27 hardcoded `Text("…")` literals and
  **zero** `language == "de"` branches. In German mode it still reads
  "Parent Settings" / "Parent Access Required" / "Set Up Parent Access" / "Silent mode (no voice)" …
- Related: F7 (level names hardcoded German in the English UI).
- Severity: medium (this is a German-family app; the parent-facing screen is the one a parent reads)

## F12 — Minor UI / copy nits
- iPhone hub (DE): "Finde die Lücke" description truncates with "…" at 2 lines; English fits.
- "Bau die Pyramide": "Barbara prüft ob sie MECE ist." — missing comma ("prüft, ob").
- Voice views (DE): the input-mode toggle still reads "Type" (English) instead of "Tippen".
- Break-mode loading state shows a bare spinner with no "Barbara bereitet die Übung vor…" copy (T-150).
- iPad onboarding/hub is the iPhone layout centred in a max-width column; large empty areas.
  Not broken, but not "designed for iPad" as the spec describes.

## Verified working
- G1 onboarding: language picker → welcome → avatar → pep talk → hub (no name-entry step;
  the avatar name becomes the display name — docs T-006 say otherwise)
- Relaunch skips onboarding (T-009); language + display name persist (T-190, T-195)
- Hub: 8 cards, progress + settings toolbar buttons (T-010..T-014)
- Say it clearly (iPhone voice variant): topic → answer → scored feedback → revision round →
  "Show scores" scorecard; quoted-text italic emphasis renders correctly
- Voice ↔ text input toggle (T-027); send button enable/disable (T-151/T-152); typing indicator (T-155)
- End Session returns to the hub from every session type (T-024, T-035, T-054, T-064)
- Find the point / Fix this mess / Spot the gap / Analyse my text all load content and respond
- Spot the gap correctly gated to L2+ and unlocked by the level override (T-071, T-130)
- Decode and rebuild correctly gated (T-080) — but see F5: it can never unlock
- Parent gate: set-up state, PIN sheet, Save disabled < 4 digits, re-locks on leaving (T-110/112/120)
- Silent mode (SIR-076): toggle persists, disables the Voice Engine picker, correct footer text,
  per-session TTS toggle disabled with "Stumm (Einstellungen)" (T-135..T-139)
- SIR_TTS_DISABLED=1 launch override silences Barbara while the saved toggle stays OFF (T-139a)
- German: hub, session content and Barbara's replies are natively German with correct umlauts
  (T-180, T-182, T-185)
- iPad: split layout for break-mode sessions (text left, chat right) (T-173)
- No crashes in ~50 minutes of driving the app.

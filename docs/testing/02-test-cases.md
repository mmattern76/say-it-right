# Test Cases — Say it right!

Structured test cases covering all screens, transitions, and key interactions.
Each test has a unique ID for traceability in test runs.

## Prerequisites

| ID | Prerequisite | How to Set Up |
|----|-------------|---------------|
| PRE-01 | Valid Anthropic API key | Enter in FirstLaunchSetupView or Parent Settings |
| PRE-02 | Backend URL + key in Config.plist | Bundled at build time |
| PRE-03 | Level override = 2+ | Parent Settings → Testing → Learner Level |
| PRE-04 | 6+ completed sessions | Complete 3 Build + 3 Break sessions (or mock via profile) |
| PRE-05 | Parent PIN set | Parent Settings → Set Parent PIN |
| PRE-06 | Debug mode enabled | Parent Settings → Diagnostics → Debug Mode ON |
| PRE-07 | German language | Settings → Sprache → Deutsch |
| PRE-08 | English language | Settings → Language → English |
| PRE-09 | Device with Face ID / Touch ID | Physical device or simulator with enrolled biometrics |
| PRE-10 | Microphone permission | Grant on first voice session launch |

---

## Group 1: First Launch & Onboarding

| ID | Screen(s) | Test Case | Prerequisites | Expected Result |
|----|-----------|-----------|---------------|-----------------|
| T-001 | S01→S02 | Fresh install shows FirstLaunchSetupView | Clean install (no UserDefaults) | API key entry screen appears |
| T-002 | S02 | Enter valid API key and proceed | PRE-01 | Advances to language selection step |
| T-003 | S02 | Enter empty API key, tap Continue | None | Continue button disabled or error shown |
| T-004 | S02→S03 | Select language (English), proceed to onboarding | PRE-01 | OnboardingView appears with English text |
| T-005 | S02→S03 | Select language (Deutsch), proceed to onboarding | PRE-01 | OnboardingView appears with German text |
| T-006 | S03 | Complete onboarding: welcome → pick avatar → enter name → pep talk | PRE-01 | Avatar and name saved. Main screen (S04) appears |
| T-007 | S03 | Pick "Maxi" avatar | PRE-01 | Maxi avatar displayed |
| T-008 | S03 | Pick "Alex" avatar | PRE-01 | Alex avatar displayed |
| T-009 | S01→S04 | Re-launch app after completed onboarding | Onboarding completed | Goes directly to ContentView, skips onboarding |

## Group 2: Main Hub (SessionPickerView)

| ID | Screen(s) | Test Case | Prerequisites | Expected Result |
|----|-----------|-----------|---------------|-----------------|
| T-010 | S04/S05 | Session picker shows all 8 session type cards | PRE-01 | All cards visible: Sag's klar, Finde den Punkt, 30 Sekunden, Räum das auf, Finde die Lücke, Bau die Pyramide, Entschlüsseln, Analysiere meinen Text (German) or English equivalents |
| T-011 | S04 | Progress toolbar button visible | PRE-01 | Chart icon in toolbar |
| T-012 | S04 | Settings toolbar button visible | PRE-01 | Gear icon in toolbar |
| T-013 | S04 | Tap progress button | PRE-01 | Navigates to ProgressDashboardView (S20) |
| T-014 | S04 | Tap settings button | PRE-01 | SettingsView appears as modal sheet (S17) |

## Group 3: Build Mode Sessions

### Say It Clearly

| ID | Screen(s) | Test Case | Prerequisites | Expected Result |
|----|-----------|-----------|---------------|-----------------|
| T-020 | S04→S06 | Tap "Say it clearly" on iPad/Mac | PRE-01, PRE-08 | SayItClearlyView opens. Topic presented. ChatView ready for input |
| T-021 | S04→S07 | Tap "Sag's klar" on iPhone | PRE-01, PRE-07, PRE-10 | VoiceSayItClearlyView opens with voice input mode |
| T-022 | S06 | Type response and send | PRE-01 | Barbara responds with structural feedback. Message appears in chat |
| T-023 | S06 | Barbara response contains hidden metadata | PRE-01 | `<!-- BARBARA_META: {...} -->` present in raw response (parsed and hidden from UI) |
| T-023a | S06/S07 | Metadata stays hidden *while streaming* | PRE-01 | The comment never appears in the bubble at any point during streaming, not even partially |
| T-023b | S06/S07 | Revision diff appears after a second attempt | PRE-01, 2+ attempts | "What changed?" / "Was hat sich geändert?" toolbar button opens the attempt comparison; hidden with fewer than 2 attempts |
| T-023c | S07 | Barbara starts speaking before the reply is complete | PRE-01, Silent OFF, TTS on | First sentence is spoken while later sentences still stream; debug log records `streaming_tts_latency` |
| T-024 | S06 | "End Session" button works | PRE-01 | Returns to SessionPickerView (S04) |
| T-025 | S06 | "No topics available" does NOT appear | PRE-01 | Topic selected and displayed; error view hidden |
| T-026 | S07 | Voice input: tap mic, speak, submit transcription | PRE-01, PRE-10 | Transcribed text sent as message. Barbara responds |
| T-027 | S07 | Toggle voice ↔ text input | PRE-01 | Input mode switches. Partial transcription preserved when switching to text |
| T-028 | S07 | TTS toggle button works | PRE-01 | Barbara's responses read aloud when ON, silent when OFF |

### Elevator Pitch

| ID | Screen(s) | Test Case | Prerequisites | Expected Result |
|----|-----------|-----------|---------------|-----------------|
| T-030 | S04→S08 | Tap "Elevator Pitch" / "30 Sekunden" on iPad/Mac | PRE-01 | ElevatorPitchView opens. Timer visible |
| T-031 | S04→S09 | Tap "30 Sekunden" on iPhone | PRE-01, PRE-10 | VoiceElevatorPitchView opens with timer + voice |
| T-032 | S08 | Timer counts down from 60s | PRE-01 | Timer displays countdown, color changes green→orange→red |
| T-033 | S08 | Timer expiry auto-submits | PRE-01 | Input submitted automatically when timer reaches 0 |
| T-033a | S09 | Timer starts with Barbara muted | PRE-01, Silent ON (or TTS toggle off) | Timer bar appears and counts down as soon as the opening message finishes streaming |
| T-034 | S08 | Early submit before timer expiry | PRE-01 | Manual submit works. Timer stops |
| T-035 | S08 | "End Session" returns to hub | PRE-01 | Returns to S04 |

### Analyse My Text

| ID | Screen(s) | Test Case | Prerequisites | Expected Result |
|----|-----------|-----------|---------------|-----------------|
| T-040 | S04→S10 | Tap "Analyse my text" | PRE-01 | AnalyseMyTextView opens. ChatView ready. Barbara prompts for text |
| T-041 | S10 | Paste multi-paragraph text, send | PRE-01 | Barbara analyses structural quality |
| T-042 | S10 | "End Session" returns to hub | PRE-01 | Returns to S04 |

## Group 4: Break Mode Sessions

### Find The Point

| ID | Screen(s) | Test Case | Prerequisites | Expected Result |
|----|-----------|-----------|---------------|-----------------|
| T-050 | S04→S11 | Tap "Find the point" on iPad/Mac | PRE-01 | FindThePointView opens. Practice text visible on left. ChatView on right |
| T-051 | S04→S12 | Tap "Finde den Punkt" on iPhone | PRE-01, PRE-10 | VoiceFindThePointView opens. Scrollable text on top. Voice chat below |
| T-052 | S11 | Practice text is displayed (not empty) | PRE-01 | Text card shows title + body content |
| T-053 | S11 | Submit answer identifying governing thought | PRE-01 | Barbara evaluates against answer key |
| T-054 | S11 | "End Session" returns to hub | PRE-01 | Returns to S04 |

### Fix This Mess

| ID | Screen(s) | Test Case | Prerequisites | Expected Result |
|----|-----------|-----------|---------------|-----------------|
| T-060 | S04→S13 | Tap "Fix this mess" on iPhone | PRE-01 | FixThisMessView opens. Practice text context loaded. ChatView ready |
| T-061 | S04→S14 | Tap "Räum das auf" on iPad | PRE-01 | FixThisMessVisualView opens. Pyramid canvas with broken arrangement |
| T-062 | S13 | Poorly-structured text is presented (not empty) | PRE-01 | Rambling or buried-lead text displayed |
| T-063 | S14 | Drag blocks to reorganize pyramid | PRE-01 | Blocks snap to drop zones. Lines update |
| T-064 | S13/S14 | "End Session" returns to hub | PRE-01 | Returns to S04 |

### Spot The Gap (Level-Gated)

| ID | Screen(s) | Test Case | Prerequisites | Expected Result |
|----|-----------|-----------|---------------|-----------------|
| T-070 | S04→S15 | Tap "Spot the gap" at Level 1 | PRE-01 | "No matching texts available" + level requirement message |
| T-071 | S04→S15 | Tap "Spot the gap" at Level 2+ | PRE-01, PRE-03 | SpotTheGapView opens with practice text + ChatView |
| T-072 | S15 | Well-structured text with hidden weakness presented | PRE-01, PRE-03 | Text displayed, learner can identify the gap |
| T-073 | S15 | "End Session" / "Go Back" returns to hub | PRE-01 | Returns to S04 |

### Decode and Rebuild (Double-Gated)

| ID | Screen(s) | Test Case | Prerequisites | Expected Result |
|----|-----------|-----------|---------------|-----------------|
| T-080 | S04→S16 | Tap "Decode and rebuild" at Level 1 | PRE-01 | Locked view: "Complete 3 Break + 3 Build sessions" |
| T-081 | S04→S16 | Tap "Decode and rebuild" at Level 2+ with enough sessions | PRE-01, PRE-03, PRE-04 | DecodeAndRebuildView opens with phase indicator + text + ChatView |
| T-082 | S16 | Phase indicator shows "1. Extract Structure" initially | PRE-01, PRE-03, PRE-04 | Phase 1 label visible |
| T-083 | S16 | "End Session" / "Go Back" returns to hub | PRE-01 | Returns to S04 |

## Group 5: Visual Pyramid Builder

| ID | Screen(s) | Test Case | Prerequisites | Expected Result |
|----|-----------|-----------|---------------|-----------------|
| T-090 | S04→S25 | Tap "Build the pyramid" | PRE-01 | BuildThePyramidView opens. Pyramid canvas + ChatView sidebar |
| T-091 | S25 | Exercise loaded (governing thought visible, unplaced blocks in pool) | PRE-01 | Exercise content displayed, not "No exercises available" |
| T-091a | S25 | Exercise library loads at every level and language | PRE-01 | L1 and L2, EN and DE all present an exercise (regression: an answer key without `redHerringBlockIDs` used to empty the whole library) |
| T-092 | S25 | Drag block from pool to drop zone | PRE-01 | Block snaps to position. Connection line appears |
| T-093 | S25 | Tap "Check" button | PRE-01 | Validation feedback shown (correct/incorrect indicators) |
| T-094 | S25 | Discard zone visible for red herring exercises | PRE-01 | Discard area shown when exercise contains distractors |
| T-095 | S25 | Pinch-to-zoom on canvas | PRE-01 | Canvas zooms in/out |
| T-096 | S25 | "End Session" returns to hub | PRE-01 | Returns to S04 |

## Group 6: Settings

| ID | Screen(s) | Test Case | Prerequisites | Expected Result |
|----|-----------|-----------|---------------|-----------------|
| T-100 | S17 | Language picker: switch English → Deutsch | PRE-01, PRE-08 | UI updates to German. Setting persists across relaunch |
| T-101 | S17 | Language picker: switch Deutsch → English | PRE-01, PRE-07 | UI updates to English |
| T-102 | S17 | Change display name | PRE-01 | Name updated. Reflected in learner profile |
| T-103 | S17 | "Replay Onboarding" button | PRE-01 | Dismisses settings. App shows FirstLaunchSetupView on next appearance |
| T-104 | S17→S18 | Tap "Parent Settings" | PRE-01 | ParentSettingsView appears (locked state) |

### Parent Gate

| ID | Screen(s) | Test Case | Prerequisites | Expected Result |
|----|-----------|-----------|---------------|-----------------|
| T-110 | S18 | First visit: "Set Up Parent Access" shown | No PIN set | Tapping unlocks and shows Set PIN sheet |
| T-111 | S18→S18a | Set 4-digit PIN | None | PIN saved. Settings content visible |
| T-112 | S18a | PIN < 4 digits: Save disabled | None | Save button disabled |
| T-113 | S18a | PINs don't match: error shown | None | "PINs don't match" message appears |
| T-114 | S18 | Return visit: locked state shows "Enter PIN" | PRE-05 | PIN entry prompt visible |
| T-115 | S18→S19 | Enter correct PIN | PRE-05 | Settings unlocked. Form content visible |
| T-116 | S19 | Enter wrong PIN | PRE-05 | "Incorrect PIN" error. Stays on PIN entry |
| T-117 | S18 | Face ID unlock (if biometric enabled) | PRE-05, PRE-09 | Biometric prompt. Success → unlocked |
| T-118 | S18 | Face ID fails → falls back to PIN | PRE-05, PRE-09 | PIN entry sheet appears |
| T-119 | S18→S18b | Remove PIN confirmation | PRE-05 | Confirmation dialog. "Remove" clears PIN |
| T-120 | S18 | Navigate away and return → re-locks | PRE-05 | Gate locks on disappear. Must re-authenticate |

### Parent Settings Content (Unlocked)

| ID | Screen(s) | Test Case | Prerequisites | Expected Result |
|----|-----------|-----------|---------------|-----------------|
| T-125 | S18 | Model picker shows models from catalog | PRE-01, PRE-05 | Picker populated with Claude models |
| T-126 | S18 | "Refresh Model List" button | PRE-01, PRE-05 | Loading indicator. Models refreshed |
| T-127 | S18 | Enter API key override | PRE-05 | Key saved to Keychain. Status shows "Using override key" |
| T-128 | S18 | Remove API key override | PRE-05 | Reverts to bundled key. Status shows "Using bundled key" |
| T-129 | S18 | Toggle show/hide API key | PRE-05 | Switches between TextField and SecureField |
| T-130 | S18 | Level override picker | PRE-05 | Change level to 2. SpotTheGap now accessible |
| T-131 | S18 | Debug mode toggle ON | PRE-05 | "View Debug Log" NavigationLink appears |
| T-132 | S18→S21 | Tap "View Debug Log" | PRE-05, PRE-06 | DebugLogView opens |
| T-133 | S21 | Debug log shows entries (or empty state) | PRE-06 | List of debug entries or "No debug data" |
| T-134 | S21 | Clear debug log | PRE-06 | Confirmation dialog. Log cleared |
| T-135 | S18 | Silent mode toggle persists | PRE-05 | Toggle ON, close & reopen Settings — toggle still ON |
| T-136 | S18 | Silent mode disables Voice Engine controls | PRE-05 | With Silent ON: Voice Engine picker and ElevenLabs fields are non-interactive |
| T-137 | S18 | Silent mode footer text | PRE-05 | Footer reads: "Silent mode is on — Barbara will not speak. STT (your voice input) still works." |
| T-138 | C01 | Silent mode mutes Barbara | PRE-05, Silent ON | Send a message; chat updates with text but no TTS audio plays |
| T-139 | C01 | Per-session TTSToggleButton disabled when Silent ON | PRE-05, Silent ON, voice session | Toolbar speaker button is greyed out and non-interactive |
| T-139a | – | `SIR_TTS_DISABLED=1` launch env forces silent | Set env var, Silent OFF in saved settings | Barbara never speaks; saved Silent toggle still shows OFF in Settings |

## Group 7: Progress Dashboard

| ID | Screen(s) | Test Case | Prerequisites | Expected Result |
|----|-----------|-----------|---------------|-----------------|
| T-140 | S20 | Empty state (no sessions completed) | PRE-01, no sessions | "No sessions yet" or equivalent message |
| T-141 | S20 | Dashboard with completed sessions | PRE-01, ≥1 session | Level card, streak, dimension chart, recent sessions list |
| T-148 | S20→S26 | Level-up celebration fires once | 10 sessions, 4 dimensions ≥75% | Celebration sheet shows the new level and Barbara's quote; profile records the transition; it does not fire again on relaunch |
| T-141a | S20 | A completed session is counted immediately | PRE-01 | Finish a scored session, tap Progress: session count, streak and dimension bars reflect it without relaunching |
| T-142 | S20 | Recent sessions show ≤5 entries | PRE-01, ≥1 session | Last 5 sessions displayed as rows |
| T-143 | S20 | "View all" link (if >5 sessions) | PRE-01, >5 sessions | Navigates to SessionHistoryView (S22) |
| T-144 | S20→S23 | Tap a recent session row | PRE-01, ≥1 session | SessionDetailView opens with full details |
| T-145 | S22 | Session history grouped by date | PRE-01, ≥1 session | Sections: Today / This Week / Earlier |
| T-146 | S22→S23 | Tap history row | PRE-01, ≥1 session | SessionDetailView opens |
| T-147 | S23 | Session detail shows scores, summary, dimensions | PRE-01, ≥1 session | Barbara's summary, dimension bar chart, metadata |

## Group 8: Chat Interactions (Cross-Cutting)

| ID | Screen(s) | Test Case | Prerequisites | Expected Result |
|----|-----------|-----------|---------------|-----------------|
| T-150 | C01 | Empty state shows loading indicator | PRE-01 | ProgressView + "Barbara bereitet die Übung vor..." (or English) |
| T-151 | C01 | Send button disabled when input empty | PRE-01 | Button greyed out |
| T-152 | C01 | Send button enabled when input has text | PRE-01 | Button colored, tappable |
| T-153 | C01 | Message appears in chat after sending | PRE-01 | User message bubble visible |
| T-154 | C01 | Barbara's response streams in | PRE-01 | Text appears incrementally |
| T-155 | C01 | Typing indicator while waiting for response | PRE-01 | Animated dots visible before first token |
| T-156 | C01 | Auto-scroll to latest message | PRE-01 | Chat scrolls to bottom on new message |
| T-157 | C01 | Barbara avatar shows mood | PRE-01 | Avatar mood matches response metadata |

## Group 9: Error Handling

| ID | Screen(s) | Test Case | Prerequisites | Expected Result |
|----|-----------|-----------|---------------|-----------------|
| T-160 | C01/C04 | Network error → error banner shown | No internet | ErrorBannerView appears with retry option |
| T-161 | C04 | Tap "Retry" on error banner | After error | Request retried |
| T-162 | C04 | Rate limit error shows countdown | API rate limited | Countdown timer in error banner |
| T-163 | C04 | "Open Settings" link in error banner | API key error | Navigates to settings |
| T-164 | C04 | Dismiss error banner | After error | Banner disappears |

## Group 10: Platform Adaptation

| ID | Screen(s) | Test Case | Prerequisites | Expected Result |
|----|-----------|-----------|---------------|-----------------|
| T-170 | S04 | iPhone compact: voice variants selected for sessions | iPhone | SayItClearly→Voice, FindThePoint→Voice, ElevatorPitch→Voice |
| T-171 | S04 | iPad regular: text variants selected for sessions | iPad | SayItClearly→Text, FindThePoint→Text, ElevatorPitch→Text |
| T-172 | S04 | iPad regular: FixThisMess→Visual variant | iPad | FixThisMessVisualView with pyramid canvas |
| T-173 | S11 | iPad: split layout (text left, chat right) | iPad | Side-by-side layout |
| T-174 | S06 | Mac: Enter key sends message | Mac | MacChatInputView handles Enter to send |
| T-175 | S04 | Mac: menu bar commands (New Session) | Mac | Cmd+N triggers new session |

## Group 11: Localization

| ID | Screen(s) | Test Case | Prerequisites | Expected Result |
|----|-----------|-----------|---------------|-----------------|
| T-180 | S05 | Session card titles in German | PRE-07 | "Sag's klar", "Finde den Punkt", "30 Sekunden", etc. |
| T-181 | S05 | Session card titles in English | PRE-08 | "Say it clearly", "Find the point", "Elevator Pitch", etc. |
| T-182 | C01 | Barbara responds in German | PRE-07 | German language response |
| T-183 | C01 | Barbara responds in English | PRE-08 | English language response |
| T-184 | S20 | Dashboard labels in German | PRE-07 | "Fortschritt", "Verlauf", etc. |
| T-185 | * | German texts contain proper umlauts (ä,ö,ü,ß) | PRE-07 | No "ae", "oe", "ue" ASCII substitutions |

## Group 12: Persistence & State

| ID | Screen(s) | Test Case | Prerequisites | Expected Result |
|----|-----------|-----------|---------------|-----------------|
| T-190 | S17 | Language setting persists across app relaunch | PRE-07 or PRE-08 | Same language on relaunch |
| T-191 | S18 | API key override persists (Keychain) | PRE-01 | Key available after relaunch |
| T-192 | S18 | Model selection persists | PRE-01 | Same model selected after relaunch |
| T-193 | S20 | Session history persists across relaunch | ≥1 session | Past sessions visible after relaunch |
| T-194 | S18 | Level override persists | PRE-03 | Override active after relaunch |
| T-195 | S17 | Display name persists | PRE-01 | Name shown after relaunch |

---

## Test Case Count Summary

| Group | Area | Count |
|-------|------|-------|
| G1 | First Launch & Onboarding | 9 |
| G2 | Main Hub | 5 |
| G3 | Build Mode Sessions | 19 |
| G4 | Break Mode Sessions | 14 |
| G5 | Visual Pyramid Builder | 7 |
| G6 | Settings & Parent Gate | 18 |
| G7 | Progress Dashboard | 8 |
| G8 | Chat Interactions | 8 |
| G9 | Error Handling | 5 |
| G10 | Platform Adaptation | 6 |
| G11 | Localization | 6 |
| G12 | Persistence & State | 6 |
| **Total** | | **111** |

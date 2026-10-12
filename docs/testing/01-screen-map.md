# Screen Map & Navigation Reference

All screens in Say it right! with transitions, platform variants, and story references.

## Legend

- **→ nav** = `.navigationDestination(isPresented:)` (push)
- **→ sheet** = `.sheet(isPresented:)` (modal)
- **→ link** = `NavigationLink` (push within existing stack)
- **→ dialog** = `.confirmationDialog` (alert-style)
- **[iPhone]** = compact horizontal size class only
- **[iPad/Mac]** = regular horizontal size class only

---

## 1. App Entry (SayItRightApp)

| # | Screen | File | Stories | Transitions Out |
|---|--------|------|---------|-----------------|
| S01 | **SayItRightApp** (entry point) | `App/SayItRightApp.swift` | SIR-014 | → S02 if `needsFirstLaunchSetup`, else → S04 |
| S02 | **FirstLaunchSetupView** | `Presentation/Session/FirstLaunchSetupView.swift` | SIR-035 | Steps: API Key → Language → → S03 |
| S03 | **OnboardingView** | `Presentation/Session/OnboardingView.swift` | SIR-035 | Phases: welcome → pickAvatar → pepTalk → S04 |

## 2. Main Hub

| # | Screen | File | Stories | Transitions Out |
|---|--------|------|---------|-----------------|
| S04 | **ContentView** | `App/SayItRightApp.swift:46` | SIR-014, SIR-030 | Shows S05. Toolbar: → S20 (nav, progress), → S17 (sheet, settings). Session cards → S06–S16 |
| S05 | **SessionPickerView** | `Presentation/Session/SessionPickerView.swift` | SIR-030 | Card tap triggers S04 handler → session views |

## 3. Session Views — Build Mode

| # | Screen | File | Stories | Platform | Transitions Out |
|---|--------|------|---------|----------|-----------------|
| S06 | **SayItClearlyView** | `Presentation/Session/SayItClearlyView.swift` | SIR-049, SIR-050, SIR-052 | iPad/Mac | Contains ChatView. "End Session" → dismiss → S04 |
| S07 | **VoiceSayItClearlyView** | `Presentation/VoiceDrill/VoiceSayItClearlyView.swift` | SIR-064+ (E5) | iPhone | Contains ChatView+voice. "End Session" → dismiss → S04 |
| S08 | **ElevatorPitchView** | `Presentation/Session/ElevatorPitchView.swift` | SIR-055, SIR-056 | iPad/Mac | Contains ChatView+timer. "End Session" → dismiss → S04 |
| S09 | **VoiceElevatorPitchView** | `Presentation/VoiceDrill/VoiceElevatorPitchView.swift` | E5 | iPhone | Contains ChatView+voice+timer. "End Session" → dismiss → S04 |
| S10 | **AnalyseMyTextView** | `Presentation/Session/AnalyseMyTextView.swift` | SIR-060 | All | Contains ChatView. "End Session" → dismiss → S04 |

## 4. Session Views — Break Mode

| # | Screen | File | Stories | Platform | Transitions Out |
|---|--------|------|---------|----------|-----------------|
| S11 | **FindThePointView** | `Presentation/Session/FindThePointView.swift` | SIR-064, SIR-065 | iPad/Mac | PracticeTextView + ChatView. "End Session" → dismiss → S04 |
| S12 | **VoiceFindThePointView** | `Presentation/VoiceDrill/VoiceFindThePointView.swift` | E5 | iPhone | PracticeTextView + ChatView+voice. "End Session" → dismiss → S04 |
| S13 | **FixThisMessView** | `Presentation/Session/FixThisMessView.swift` | SIR-067, SIR-068 | iPhone | ChatView with text context. "End Session" → dismiss → S04 |
| S14 | **FixThisMessVisualView** | `Presentation/Session/FixThisMessVisualView.swift` | E6 | iPad/Mac | Pyramid canvas + ChatView sidebar. "End Session" → dismiss → S04 |
| S15 | **SpotTheGapView** | `Presentation/Session/SpotTheGapView.swift` | SIR-069, SIR-070 | All | Level-gated (L2+). PracticeTextView + ChatView. "End Session" → dismiss → S04 |
| S16 | **DecodeAndRebuildView** | `Presentation/Session/DecodeAndRebuildView.swift` | SIR-073, SIR-074 | All | Gated (L2+ & 3 Break + 3 Build). Phase indicator + ChatView. "End Session" → dismiss → S04 |

## 5. Session Views — Visual/Pyramid

| # | Screen | File | Stories | Platform | Transitions Out |
|---|--------|------|---------|----------|-----------------|
| S25 | **BuildThePyramidView** | `Presentation/Session/BuildThePyramidView.swift` | E6 | iPad/Mac (all) | Pyramid canvas + ChatView sidebar. "End Session" → dismiss → S04 |

## 6. Settings Flow

| # | Screen | File | Stories | Transitions Out |
|---|--------|------|---------|-----------------|
| S26 | **LevelUpCelebrationView** | `Presentation/Session/LevelUpCelebrationView.swift` | E7 | Sheet from S04 when a completed session earns a promotion. "Los geht's!" → dismiss → S04 |
| S27 | **RevisionDiffView** | `Presentation/Session/RevisionDiffView.swift` | E7 | Sheet from S06/S07 once a session has 2+ attempts. "Fertig" → dismiss → session |

| S17 | **SettingsView** | `Presentation/Session/SettingsView.swift` | SIR-024, SIR-035 | → S18 (link, Parent Settings). "Replay Onboarding" resets → S02. Sheet dismiss → S04 |
| S18 | **ParentSettingsView** | `Presentation/Session/ParentSettingsView.swift` | SIR-036 | If locked: → S19 (sheet, PIN entry). If unlocked: → S21 (link, Debug Log). PIN dialogs: → S18a (sheet, Set PIN), → S18b (dialog, Remove PIN) |
| S18a | **Set PIN Sheet** (inline in ParentSettingsView) | `ParentSettingsView.swift:276` | SIR-036 | Cancel/Save → dismiss → S18 |
| S18b | **Remove PIN Confirmation** (dialog) | `ParentSettingsView.swift:242` | SIR-036 | Remove/Cancel → S18 |
| S19 | **PINEntryView** | `Presentation/Session/PINEntryView.swift` | SIR-036 | 4-digit entry → unlock → S18. Cancel → S18 |
| S21 | **DebugLogView** | `Presentation/Session/DebugLogView.swift` | SIR-039 | Clear → dialog. ShareLink → system share sheet. Back → S18 |

## 7. Dashboard Flow

| # | Screen | File | Stories | Transitions Out |
|---|--------|------|---------|-----------------|
| S20 | **ProgressDashboardView** | `Presentation/Dashboard/ProgressDashboardView.swift` | SIR-057 | → S22 (link, "View all" history). Recent session row → S23 (link). Back → S04 |
| S22 | **SessionHistoryView** | `Presentation/Dashboard/SessionHistoryView.swift` | SIR-058 | Each row → S23 (link). Back → S20 |
| S23 | **SessionDetailView** | `Presentation/Dashboard/SessionDetailView.swift` | SIR-058 | Dead-end (read-only). Back → S22 or S20 |

## 8. Shared Components (embedded, not navigated to directly)

| # | Component | File | Used In |
|---|-----------|------|---------|
| C01 | **ChatView** | `Presentation/Chat/ChatView.swift` | S06–S16, S25 |
| C02 | **MessageBubbleView** | `Presentation/Chat/MessageBubbleView.swift` | C01 |
| C03 | **BarbaraAvatarView** | `Presentation/Chat/BarbaraAvatarView.swift` | C01, S05, S03 |
| C04 | **ErrorBannerView** | `Presentation/Chat/ErrorBannerView.swift` | C01 |
| C05 | **VoiceInputView** | `Presentation/VoiceDrill/VoiceInputView.swift` | C01 (when voice enabled) |
| C06 | **PracticeTextView** | `Presentation/Session/PracticeTextView.swift` | S11, S12, S13, S14, S15, S16 |
| C07 | **ZoomablePyramidCanvas** | `Presentation/PyramidBuilder/ZoomablePyramidCanvas.swift` | S25, S14 |
| C08 | **DraggableBlockView** | `Presentation/PyramidBuilder/DraggableBlockView.swift` | C07 |
| C09 | **MacChatInputView** | `Presentation/Chat/MacChatInputView.swift` | C01 (macOS) |
| C10 | **TTSToggleButton** | `Presentation/VoiceDrill/TTSToggleButton.swift` | S07, S09, S12 |
| C11 | **DimensionBarChartView** | `Presentation/Dashboard/DimensionBarChartView.swift` | S20, S23 |

---

## Navigation Graph (simplified)

```
SayItRightApp
  ├─[no setup]──→ FirstLaunchSetupView → OnboardingView → ContentView
  └─[setup done]─→ ContentView (SessionPickerView)
                     ├─ toolbar ──→ ProgressDashboardView
                     │                ├──→ SessionHistoryView
                     │                │      └──→ SessionDetailView
                     │                └──→ SessionDetailView
                     ├─ toolbar ──→ SettingsView (sheet)
                     │                └──→ ParentSettingsView
                     │                       ├──→ PINEntryView (sheet)
                     │                       ├──→ Set PIN Sheet
                     │                       └──→ DebugLogView
                     ├─ sayItClearly ──→ SayItClearlyView [iPad/Mac]
                     │                  → VoiceSayItClearlyView [iPhone]
                     ├─ findThePoint ──→ FindThePointView [iPad/Mac]
                     │                  → VoiceFindThePointView [iPhone]
                     ├─ elevatorPitch ─→ ElevatorPitchView [iPad/Mac]
                     │                  → VoiceElevatorPitchView [iPhone]
                     ├─ analyseMyText ─→ AnalyseMyTextView
                     ├─ fixThisMess ───→ FixThisMessView [iPhone]
                     │                  → FixThisMessVisualView [iPad/Mac]
                     ├─ spotTheGap ────→ SpotTheGapView (L2+ gate)
                     ├─ decodeRebuild ─→ DecodeAndRebuildView (L2+ & session gate)
                     └─ buildPyramid ──→ BuildThePyramidView
```

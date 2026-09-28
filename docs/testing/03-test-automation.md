# Test Automation Approach

Strategy for automated execution of the test cases defined in `02-test-cases.md`.

---

## Architecture Overview

```
┌─────────────────────────────────────────────┐
│  XCUITest Suite (SayItRightUITests)         │
│                                             │
│  ├─ TestGroups/                             │
│  │   ├─ G1_OnboardingTests.swift            │
│  │   ├─ G2_MainHubTests.swift               │
│  │   ├─ G3_BuildModeTests.swift             │
│  │   ├─ G4_BreakModeTests.swift             │
│  │   ├─ G5_PyramidBuilderTests.swift        │
│  │   ├─ G6_SettingsTests.swift              │
│  │   ├─ G7_DashboardTests.swift             │
│  │   ├─ G8_ChatTests.swift                  │
│  │   ├─ G9_ErrorHandlingTests.swift         │
│  │   ├─ G10_PlatformTests.swift             │
│  │   ├─ G11_LocalizationTests.swift         │
│  │   └─ G12_PersistenceTests.swift          │
│  ├─ Support/                                │
│  │   ├─ TestConfig.swift                    │
│  │   ├─ ScreenRobot.swift                   │
│  │   └─ TestReporter.swift                  │
│  └─ Results/                                │
│      └─ (JSON test run reports)             │
│                                             │
├─ scripts/                                   │
│   ├─ run-ui-tests.sh                        │
│   └─ generate-report.py                     │
└─────────────────────────────────────────────┘
```

## Tool: XCUITest (Apple's UI Testing Framework)

**Why XCUITest over alternatives:**
- Native to Xcode — no third-party dependencies (per project convention)
- Supports iOS, iPadOS, and macOS targets from one test suite
- Access to accessibility identifiers already in the codebase
- Integrates with `xcodebuild test` for CI/headless runs
- Captures screenshots on failure automatically

**Not XCTest unit tests** — these are UI-level integration tests that exercise
the full app binary through simulated user interactions.

---

## Prerequisites & Environment Setup

### 1. API Key Injection

Tests must NOT hardcode API keys. Use environment variables via the Xcode scheme:

```swift
// TestConfig.swift
enum TestConfig {
    static var anthropicAPIKey: String {
        ProcessInfo.processInfo.environment["TEST_ANTHROPIC_API_KEY"] ?? ""
    }
}
```

**For CI / command-line:**
```bash
TEST_ANTHROPIC_API_KEY="sk-ant-..." xcodebuild test \
    -project app/SayItRight/SayItRight.xcodeproj \
    -scheme SayItRight_iOS \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
    -testPlan SayItRightUITests
```

### 2. Test Launch Arguments

Use launch arguments to control app state per test:

```swift
// In test setUp():
let app = XCUIApplication()
app.launchArguments += ["-resetForTesting"]        // Clean UserDefaults
app.launchArguments += ["-skipOnboarding"]          // Jump to main hub
app.launchArguments += ["-language", "de"]          // Force German
app.launchArguments += ["-levelOverride", "2"]      // Set level
app.launchEnvironment["ANTHROPIC_API_KEY_OVERRIDE"] = TestConfig.anthropicAPIKey
app.launchEnvironment["SIR_TTS_DISABLED"] = "1"     // Mute Barbara during automation
app.launch()
```

**`SIR_TTS_DISABLED`** is the global silent-mode override (SIR-076). When set
to `1`, `true`, or `yes`, ``TTSServiceFactory`` returns ``NoOpTTSService``
regardless of the saved Settings value — so audio playback never fights with
test timing on the simulator. STT (microphone) is unaffected. The
**Geppetto** UI test automation tool (`../geppetto`) should always pass this
env var on launch.

**App-side handling** (add to AppSettings.init or app entry):
```swift
// Check for test arguments
if CommandLine.arguments.contains("-resetForTesting") {
    UserDefaults.standard.removePersistentDomain(
        forName: Bundle.main.bundleIdentifier!
    )
}
if CommandLine.arguments.contains("-skipOnboarding") {
    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
}
if let langIndex = CommandLine.arguments.firstIndex(of: "-language"),
   langIndex + 1 < CommandLine.arguments.count {
    UserDefaults.standard.set(
        CommandLine.arguments[langIndex + 1],
        forKey: "appLanguage"
    )
}
if let levelIndex = CommandLine.arguments.firstIndex(of: "-levelOverride"),
   levelIndex + 1 < CommandLine.arguments.count {
    UserDefaults.standard.set(
        Int(CommandLine.arguments[levelIndex + 1]) ?? 0,
        forKey: "levelOverride"
    )
}
```

### 3. Simulator Requirements

| Test Group | Simulator | Why |
|-----------|-----------|-----|
| G1-G4, G6-G9, G11-G12 | iPhone 17 Pro (iOS 26) | Compact size class, voice variant routing |
| G5, G10 (iPad) | iPad Pro 13-inch (iOS 26) | Regular size class, split layouts, pyramid builder |
| G10 (Mac) | macOS 15+ (native) | Mac Catalyst or native macOS target |
| G10 (voice) | Physical iPhone | Real microphone access (simulator STT is limited) |

### 4. Network

- Tests in G1-G8 require a live Anthropic API connection for Barbara responses
- G9 (Error Handling) needs a way to simulate network failure:
  - Option A: Use a mock server URL via launch argument
  - Option B: Use Network Link Conditioner (macOS utility)
  - Option C: Add a `--simulateNetworkError` flag that AnthropicService checks

---

## Screen Robot Pattern

Use the Robot pattern (Page Object variant) for readable, maintainable tests:

```swift
// ScreenRobot.swift — base protocol
protocol ScreenRobot {
    var app: XCUIApplication { get }
}

extension ScreenRobot {
    func waitForElement(_ identifier: String, timeout: TimeInterval = 10) -> XCUIElement {
        let element = app.descendants(matching: .any)[identifier]
        XCTAssertTrue(element.waitForExistence(timeout: timeout),
                      "Element '\(identifier)' not found within \(timeout)s")
        return element
    }
}

// Example: SessionPickerRobot
struct SessionPickerRobot: ScreenRobot {
    let app: XCUIApplication

    func tapSayItClearly() {
        app.buttons["sayItClearlyCard"].tap()
    }

    func tapSettings() {
        waitForElement("settingsButton").tap()
    }

    func tapProgress() {
        waitForElement("progressButton").tap()
    }

    func assertAllCardsVisible() {
        XCTAssertTrue(app.buttons["sayItClearlyCard"].exists)
        XCTAssertTrue(app.buttons["findThePointCard"].exists)
        // ... all 8 cards
    }
}

// Example: ChatRobot
struct ChatRobot: ScreenRobot {
    let app: XCUIApplication

    func typeMessage(_ text: String) {
        waitForElement("chatInputField").tap()
        waitForElement("chatInputField").typeText(text)
    }

    func tapSend() {
        waitForElement("sendButton").tap()
    }

    func waitForBarbaraResponse(timeout: TimeInterval = 30) {
        // Barbara responses take time (LLM streaming)
        let predicate = NSPredicate(format: "count > 1")
        let messageList = app.scrollViews.firstMatch
        expectation(for: predicate, evaluatedWith: messageList.buttons)
    }

    func assertLoadingIndicatorShown() {
        XCTAssertTrue(app.activityIndicators.firstMatch.exists)
    }
}
```

### Required Accessibility Identifiers

These already exist or need to be added to views:

| View | Identifier | Status |
|------|-----------|--------|
| SessionPickerView cards | `sayItClearlyCard`, `findThePointCard`, etc. | Needs adding |
| Settings toolbar button | `settingsButton` | Exists |
| Progress toolbar button | `progressButton` | Exists |
| Chat input field | `chatInputField` | Exists |
| Send button | `sendButton` | Exists |
| Input mode toggle | `inputModeToggle` | Exists |
| End Session button | `endSessionButton` | Needs adding |
| Parent Settings link | `parentSettingsLink` | Needs adding |
| PIN entry field | `pinEntryField` | Needs adding |
| Level override picker | `levelOverridePicker` | Needs adding |
| Debug mode toggle | `debugModeToggle` | Needs adding |
| Silent mode toggle (Parent Settings) | `settings.silentMode.toggle` | Exists (SIR-076) |
| Revision diff button (Say it clearly) | `revisionDiffButton` | Exists |

---

## Test Execution

### Command-Line Runner Script

```bash
#!/bin/bash
# scripts/run-ui-tests.sh
#
# Usage:
#   ./scripts/run-ui-tests.sh                    # Run all tests on iPhone
#   ./scripts/run-ui-tests.sh --group G3         # Run only Build Mode tests
#   ./scripts/run-ui-tests.sh --ipad             # Run on iPad simulator
#   ./scripts/run-ui-tests.sh --report           # Generate HTML report

set -euo pipefail

PROJECT="app/SayItRight/SayItRight.xcodeproj"
SCHEME="SayItRight_iOS"
DESTINATION="platform=iOS Simulator,name=iPhone 17 Pro"
RESULTS_DIR="docs/testing/results"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULT_BUNDLE="${RESULTS_DIR}/run-${TIMESTAMP}.xcresult"

# Parse arguments
GROUP_FILTER=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --group) GROUP_FILTER="-only-testing:SayItRightUITests/$2"; shift 2 ;;
        --ipad) DESTINATION="platform=iOS Simulator,name=iPad Pro 13-inch (M4)"; shift ;;
        --mac) SCHEME="SayItRight_macOS"; DESTINATION="platform=macOS"; shift ;;
        --report) GENERATE_REPORT=true; shift ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

mkdir -p "$RESULTS_DIR"

# Regenerate Xcode project
cd app/SayItRight && xcodegen generate && cd ../..

# Run tests
xcodebuild test \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -resultBundlePath "$RESULT_BUNDLE" \
    ${GROUP_FILTER} \
    2>&1 | xcpretty

echo "Results saved to: $RESULT_BUNDLE"

# Extract test results to JSON
if [[ "${GENERATE_REPORT:-}" == "true" ]]; then
    xcrun xcresulttool get --format json \
        --path "$RESULT_BUNDLE" \
        > "${RESULTS_DIR}/run-${TIMESTAMP}.json"
    echo "JSON report: ${RESULTS_DIR}/run-${TIMESTAMP}.json"
fi
```

### Test Result Format

Each test run produces a structured result:

```json
{
  "run_id": "20260308-143022",
  "device": "iPhone 17 Pro (iOS 26.2)",
  "language": "de",
  "timestamp": "2026-03-08T14:30:22Z",
  "duration_seconds": 342,
  "summary": {
    "total": 111,
    "passed": 98,
    "failed": 8,
    "skipped": 5
  },
  "results": [
    {
      "id": "T-001",
      "group": "G1",
      "name": "Fresh install shows FirstLaunchSetupView",
      "status": "passed",
      "duration_ms": 2340,
      "screenshot": null
    },
    {
      "id": "T-070",
      "group": "G4",
      "name": "Spot the gap at Level 1 shows gate",
      "status": "failed",
      "duration_ms": 5120,
      "screenshot": "T-070-failure.png",
      "failure_message": "Element 'levelGateMessage' not found within 10s"
    },
    {
      "id": "T-117",
      "group": "G6",
      "name": "Face ID unlock",
      "status": "skipped",
      "skip_reason": "Requires physical device with biometrics"
    }
  ]
}
```

---

## Test Tiers

Not all 111 tests need to run every time. Organize into tiers:

### Tier 1: Smoke (run before every TestFlight upload) — ~20 tests

Critical path through the app. Should complete in <5 minutes.

| Tests | Coverage |
|-------|----------|
| T-009 | App launches to main hub (skip onboarding) |
| T-010 | All 8 session cards visible |
| T-020 | Say It Clearly opens (text variant) |
| T-025 | No "no topics" error |
| T-022 | Send message, Barbara responds |
| T-024 | End session returns to hub |
| T-050 | Find The Point opens with text |
| T-060 | Fix This Mess opens with text |
| T-090 | Build The Pyramid opens with exercise |
| T-030 | Elevator Pitch opens with timer |
| T-040 | Analyse My Text opens |
| T-014 | Settings sheet opens |
| T-100 | Language switch works |
| T-013 | Progress dashboard opens |
| T-150 | Chat loading state correct |
| T-185 | German umlauts correct |

### Tier 2: Full Functional (weekly or pre-release) — all 111 tests

Complete coverage including edge cases, error handling, persistence.

### Tier 3: Platform Matrix (before major releases)

Run Tier 2 on all three platforms:
- iPhone 17 Pro (compact)
- iPad Pro 13-inch (regular)
- macOS 15 (native)

---

## Implementation Plan

### Phase 1: Foundation (do first)

1. **Add missing accessibility identifiers** to views (see table above)
2. **Add launch argument handling** in AppSettings.init
3. **Create XCUITest target** in project.yml:
   ```yaml
   SayItRightUITests:
     type: bundle.ui-testing
     platform: [iOS, macOS]
     sources:
       - path: SayItRightUITests
     dependencies:
       - target: SayItRight_${platform}
     settings:
       TEST_HOST: ""
       BUNDLE_LOADER: ""
   ```
4. **Create ScreenRobot protocols** and base helpers
5. **Create TestConfig** for environment-based API key

### Phase 2: Tier 1 Smoke Tests

Implement the ~20 smoke tests. These give immediate value and catch
the bugs we've been hitting (empty topics, missing resources, broken
navigation).

### Phase 3: Remaining Groups

Implement G1-G12 test classes one at a time, matching the test case IDs
from `02-test-cases.md`.

### Phase 4: CI Integration

- Add `run-ui-tests.sh` to the pre-TestFlight-upload workflow
- Store result bundles as artifacts
- Fail the upload if any Tier 1 test fails

---

## Known Limitations

1. **LLM response timing**: Barbara's responses take 3-30 seconds. Tests must
   use generous timeouts (30s+) and not assert on response content (it varies).
   Assert on structure: message count, metadata presence, UI state changes.

2. **Voice tests on simulator**: SFSpeechRecognizer returns limited results on
   simulator. Voice input tests (T-026, T-027, T-028) should be marked as
   requiring a physical device or tested with pre-recorded audio injection.

3. **Biometric tests**: Face ID simulation works in Simulator
   (`biometricAuthentication` in Features menu), but XCUITest cannot
   programmatically trigger it. These tests (T-117, T-118) need manual
   intervention or the `Simulator.app` `enrollBiometrics` / `matchBiometrics`
   CLI commands.

4. **Network error simulation**: T-160–T-164 need either a mock server or
   network conditioning. Consider adding a `MockAnthropicService` that the
   test target injects via launch arguments.

5. **Drag-and-drop testing**: XCUITest supports drag gestures
   (`press(forDuration:thenDragTo:)`) but pyramid builder tests (T-092, T-093)
   need careful coordinate calculation. May need accessibility-based drop targets.

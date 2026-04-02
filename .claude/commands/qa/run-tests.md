---
description: Run UI tests on simulator. Failed tests are filed as bug issues on the GitHub board.
argument-hint: [--group G3] [--ipad] [--tier smoke] [--language de] [--dry-run]
---

# Run UI Tests and File Bugs for Failures

Execute the XCUITest suite, parse results, and create GitHub issues for failures.

## Parse arguments

Defaults:
- **device**: iPhone simulator (compact size class)
- **tier**: full (all test groups)
- **language**: en
- **dry-run**: false (when true, report failures but don't create issues)

Parse `$ARGUMENTS` for overrides:
- `--group G3` → run only that test group (maps to test class, see table below)
- `--ipad` → use iPad simulator (regular size class)
- `--mac` → use macOS native target
- `--tier smoke` → run only Tier 1 smoke tests
- `--language de` → run with German language
- `--dry-run` → report only, don't file issues

Group-to-class mapping:
| Group | XCUITest Class |
|-------|---------------|
| G1 | FirstLaunchUITests, OnboardingUITests |
| G2 | SessionPickerUITests |
| G3 | SessionFlowUITests (Build mode subset) |
| G4 | SessionFlowUITests (Break mode subset) |
| G5 | SessionFlowUITests (Pyramid subset) |
| G6 | SettingsUITests |
| G7 | DashboardUITests |
| G8 | ChatUITests |
| G9 | ErrorHandlingUITests |
| G10 | PlatformUITests |
| G11 | LocalizationUITests |
| G12 | PersistenceUITests |

## Phase 1: Pre-flight

1. Verify Xcode project is up to date:
   ```bash
   cd app/SayItRight && xcodegen generate 2>&1 && cd ../..
   ```

2. Determine simulator destination:
   ```bash
   # iPhone (default)
   DESTINATION="platform=iOS Simulator,name=iPhone 17 Pro"
   SCHEME="SayItRight_iOS"

   # --ipad
   DESTINATION="platform=iOS Simulator,name=iPad Pro 13-inch (M4)"
   SCHEME="SayItRight_iOS"

   # --mac
   DESTINATION="platform=macOS"
   SCHEME="SayItRight_macOS"
   ```

3. Boot simulator if needed:
   ```bash
   xcrun simctl boot "iPhone 17 Pro" 2>/dev/null || true
   ```

## Phase 2: Run tests

Build and run the XCUITest suite:

```bash
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULT_BUNDLE="/tmp/say-it-right-tests/run-${TIMESTAMP}.xcresult"

xcodebuild test \
    -project app/SayItRight/SayItRight.xcodeproj \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -resultBundlePath "$RESULT_BUNDLE" \
    -only-testing:"SayItRightUITests" \
    2>&1 | tail -80
```

If filtering by group, add the appropriate `-only-testing:SayItRightUITests/<ClassName>` flag.

If the build fails before tests run, diagnose the build error and fix it (up to 3 attempts).
Do NOT file build failures as test bugs — fix them directly.

## Phase 3: Parse results

Extract test results from the xcresult bundle:

```bash
xcrun xcresulttool get --format json --path "$RESULT_BUNDLE" 2>/dev/null
```

If `xcresulttool` output is too complex, fall back to parsing xcodebuild stdout for:
- Lines matching `Test Case .* passed` → passed
- Lines matching `Test Case .* failed` → failed
- Lines matching `Executed .* tests, with .* failures` → summary

Build a results table:
| Test | Class | Method | Status | Failure Reason |
|------|-------|--------|--------|----------------|

Map each test method to the test case ID from `docs/testing/02-test-cases.md` where possible.

## Phase 4: File bugs for failures

For each **failed** test:

1. Check if a bug already exists for this failure:
   ```bash
   gh issue list --label "bug,ui-test" --state open --json number,title \
       --jq '.[] | select(.title | test("T-NNN|<testMethodName>"))'
   ```

2. If no existing issue, create one:
   ```bash
   gh issue create \
       --title "bug: UI test failure — <TestClass>.<testMethod> (<test-case-id>)" \
       --label "bug,ui-test" \
       --body "$(cat <<'EOF'
   ## Failed UI Test

   **Test Case ID:** <T-NNN> (from docs/testing/02-test-cases.md)
   **Test Class:** <ClassName>
   **Test Method:** <methodName>
   **Device:** <iPhone 17 Pro / iPad Pro / macOS>
   **Language:** <en/de>
   **Run timestamp:** <TIMESTAMP>

   ## Failure Details

   ```
   <failure message and relevant xcodebuild output>
   ```

   ## Expected Behavior

   <from test case description in 02-test-cases.md>

   ## Steps to Reproduce

   1. Launch app with test configuration
   2. <navigation steps implied by test>
   3. <assertion that failed>

   ## Screenshot

   <attach if available from xcresult bundle>

   ---
   *Filed automatically by `/qa:run-tests`*
   EOF
   )"
   ```

3. Add the issue to the project board in "Todo":
   ```bash
   ./scripts/gh-move-issue.sh <issue_number> todo
   ```

If `--dry-run` was specified, skip issue creation but still print what would be filed.

## Phase 5: Report

Print a summary:

```
===========================================
  UI Test Run: <TIMESTAMP>
===========================================
  Device:    <iPhone 17 Pro / iPad / macOS>
  Language:  <en/de>
  Tier:      <smoke / full>
  Duration:  <Xs>

  Results:
    Passed:  NN
    Failed:  NN
    Skipped: NN

  Failed Tests:
    - <TestClass.testMethod> (T-NNN): <reason>
      → Issue #<number> created
    - <TestClass.testMethod> (T-NNN): <reason>
      → Issue #<number> already exists

  Bugs Filed: NN new issues
  Result Bundle: <path>
===========================================
```

## Notes

- Tests that fail due to **missing accessibility identifiers** should be fixed
  directly in the source code (add the identifier), not filed as bugs.
- Tests that fail due to **simulator issues** (boot failure, timeout on CI)
  should be retried once before filing.
- If ALL tests fail, it's likely a build or configuration issue — diagnose
  and fix rather than filing dozens of identical bugs.
- The xcresult bundle at `$RESULT_BUNDLE` contains screenshots for failures.
  Mention the path in filed issues so they can be extracted:
  ```bash
  xcrun xcresulttool export --path "$RESULT_BUNDLE" --type file --output-path /tmp/screenshots/
  ```

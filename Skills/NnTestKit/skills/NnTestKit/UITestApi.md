# UI Test API

Base class and helpers for UI testing — element waiting, button interaction, text input, date pickers, assertions, test data generation, and UI test seeding with typed configuration.

Libraries: `NnUITestHelpers`, `NnTestVariables`

## Import Guide

| Type / Symbol | Import |
|---------------|--------|
| `BaseUITestCase` and all extensions | `import NnUITestHelpers` |
| `runStep(_:block:)` | `import NnUITestHelpers` |
| `XCUIElement.isFullyVisible(in:)` | `import NnUITestHelpers` |
| `UITestSeedContext`, `UITestSeedKey`, `UITestSeedDefaults` | `import NnTestVariables` |

---

## Class: BaseUITestCase

Open base class for UI tests with pre-configured `XCUIApplication` and environment setup.

```swift
@MainActor
open class BaseUITestCase: XCTestCase {
    public let app = XCUIApplication()
    open override func setUpWithError() throws
}
```

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `app` | `XCUIApplication` | Pre-configured application instance |
| `mainUserEmail` | `String` | The generated test user email; valid after `launchSeeded` or `setSeedConfig` |

### Behavioral Notes

- `setUpWithError()` sets `continueAfterFailure = false` and injects `IS_UI_TESTING = IS_TRUE` into `app.launchEnvironment`.
- Does **not** call `app.launch()` — subclasses must call it themselves (or use `launchSeeded`).
- All methods below are `public` extensions on `BaseUITestCase`.

### Usage Example

```swift
final class LoginUITests: BaseUITestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        addKeyToENV("SKIP_ONBOARDING")
        app.launch()
    }

    func test_loginFlow() {
        typeInField(fieldId: "emailField", text: "test@example.com")
        typeInField(fieldId: "passwordField", isSecure: true, text: "password123")
        tapButton("Login")
        elementAppeared(app.staticTexts, named: "Welcome")
    }
}
```

---

## Timeout Defaults

All UI helper `timeout:` parameters are `TimeInterval?` and default to `nil`. When `nil`, they fall back to `UITestSeedDefaults.timeout` (default **10 seconds**).

```swift
public enum UITestSeedDefaults {
    public static let password: String                 // "uitest-password"
    public static var timeout: TimeInterval = 10       // global fallback
}
```

Override the global default once in your test class's `setUpWithError` to adjust all helpers simultaneously:

```swift
override func setUpWithError() throws {
    try super.setUpWithError()
    UITestSeedDefaults.timeout = 15  // slow CI environment
}
```

Pass an explicit value per call to override for just that call.

---

### Setup

| Method | Returns | Description |
|--------|---------|-------------|
| `addKeyToENV(_ key: String, value: String = IS_TRUE)` | `Void` | Adds a key-value pair to `app.launchEnvironment` |

Must be called **before** `app.launch()` to take effect.

---

### Seeding

Helpers for seeding UI tests with a typed configuration and a unique per-run test user. The app under test is expected to read the environment variables (via `UITestSeedContext.fromEnvironment(_:)`) and run a seeder before rendering UI.

| Method / Property | Returns | Description |
|-------------------|---------|-------------|
| `launchSeeded<Config: Codable>(config:envKeys:file:line:)` | `Void` | Encodes the config, generates a unique `runId` and test user email, sets environment, and calls `app.launch()` |
| `setSeedConfig<Config: Codable>(_:envKeys:)` | `Void` | Same environment setup as `launchSeeded`, but does NOT launch. Use when another flow (e.g. `signUpWithEmail`) owns the launch |
| `mainUserEmail` | `String` | Reads the generated test user email from `app.launchEnvironment`. Returns empty string if seeding has not run |
| `seedEmail(for userName: String) -> String` | `String` | Generates the expected email for an additional seeded user, matching the app-side seeder's format |
| `makeUniqueName(_ base: String) -> String` | `String` | Appends two random digits (0-9) to a base string for collision-free names across runs |
| `dismissPasswordPromptIfNeeded(timeout: TimeInterval?)` | `Void` | Dismisses the iOS "Save Password?" system prompt by tapping "Not Now" if it appears |

### Parameters: launchSeeded

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `config` | `Config: Codable` | required | The app-specific seed configuration; encoded to JSON and placed in `UITEST_SEED_CONFIG` |
| `envKeys` | `[String]` | `[]` | Additional env keys to set to `IS_TRUE` (e.g. feature flags) |

### Behavioral Notes — Seeding

- **Unique runId**: `setSeedConfig` generates an 8-character lowercase UUID prefix per call, ensuring parallel test runs don't collide.
- **Email format**: The main test user email is `"tester+\(runId)@uitest.local"`. `seedEmail(for:)` follows `"\(userName.lowercased())+\(runId)@uitest.local"` — the app-side seeder must use the same format.
- **Environment variables set**: `UITEST_RUN_ID`, `UITEST_USER_EMAIL`, `UITEST_SEED_CONFIG` (JSON-encoded `Config`), plus any `envKeys`.
- **Config encoding failure is silent**: If `JSONEncoder().encode(config)` throws, `UITEST_SEED_CONFIG` is simply not set. The app's `fromEnvironment(_:)` will then return `nil`.
- **`dismissPasswordPromptIfNeeded`**: Looks for `app.buttons["Not Now"]` and taps it if it appears within `timeout`. If the prompt does not appear, the helper returns silently — safe to call unconditionally after any login flow.
- **`makeUniqueName`**: Calls `getRandomNumber()` twice — produces names like `"MyHouse47"`. Does NOT incorporate `runId`, so not guaranteed unique across parallel runs — use only for intra-run uniqueness.

### Usage Example — Seeding

```swift
struct AppSeedConfig: Codable, Sendable {
    let startingBalance: Int
    let enableBetaFeatures: Bool
}

final class DashboardUITests: BaseUITestCase {
    func test_dashboardShowsSeededBalance() {
        launchSeeded(config: AppSeedConfig(startingBalance: 500, enableBetaFeatures: true))

        elementAppeared(app.staticTexts, named: "$500.00")
        XCTAssertEqual(mainUserEmail.hasSuffix("@uitest.local"), true)
    }

    func test_loginFromSignupFlow() {
        setSeedConfig(AppSeedConfig(startingBalance: 0, enableBetaFeatures: false))
        // Another helper owns the launch step
        signUpWithEmail(mainUserEmail)
        dismissPasswordPromptIfNeeded()
    }
}
```

---

## Type: UITestSeedContext

App-side helper for decoding the seed context out of the process environment. Declared in `NnTestVariables` so production targets can import it without pulling in XCTest.

```swift
public struct UITestSeedContext<Config: Codable & Sendable>: Sendable {
    public let runId: String
    public let config: Config
    public let userEmail: String
    public let userPassword: String

    public init(runId: String, config: Config, userEmail: String, userPassword: String)
}

public extension UITestSeedContext {
    static func fromEnvironment(_ configType: Config.Type) -> UITestSeedContext?
}
```

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `runId` | `String` | Unique identifier for this UI test run (8-char UUID prefix) |
| `config` | `Config` | App-specific seed configuration decoded from `UITEST_SEED_CONFIG` |
| `userEmail` | `String` | Primary test user email |
| `userPassword` | `String` | Shared test password — `UITestSeedDefaults.password` |

### Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `static fromEnvironment(_:)` | `UITestSeedContext?` | Reads `UITEST_RUN_ID`, `UITEST_USER_EMAIL`, and `UITEST_SEED_CONFIG` from `ProcessInfo.processInfo.environment`. Returns `nil` if any variable is missing or if JSON decoding fails |

### Usage Example — App Side

```swift
// In the app under test, at launch:
import NnTestVariables

struct AppSeedConfig: Codable, Sendable { /* ... */ }

if ProcessInfo.isUITesting,
   let seed = UITestSeedContext<AppSeedConfig>.fromEnvironment(AppSeedConfig.self) {
    await DatabaseSeeder.run(
        runId: seed.runId,
        email: seed.userEmail,
        password: seed.userPassword,
        config: seed.config
    )
}
```

### Behavioral Notes

- **Returns nil on any missing piece**: `runId`, `userEmail`, and `seedConfig` are all required. If `seedConfig` is present but JSON decoding fails, the entire call returns `nil` (not a partial context).
- **Password source**: `userPassword` is always `UITestSeedDefaults.password` — the test-side `setSeedConfig` never sets a password in the environment.
- **Import location**: `NnTestVariables` is a lightweight library with no XCTest dependency. It is safe to import in production/app targets.

---

## Type: UITestSeedKey

Canonical environment variable names shared between test and app targets.

```swift
public enum UITestSeedKey: String {
    case runId      = "UITEST_RUN_ID"
    case userEmail  = "UITEST_USER_EMAIL"
    case seedConfig = "UITEST_SEED_CONFIG"
}
```

Use `UITestSeedKey.runId.rawValue` instead of hardcoding `"UITEST_RUN_ID"` when both sides of the seeding contract need to agree on a key.

---

## Type: UITestSeedDefaults

Namespace for UI test defaults.

```swift
public enum UITestSeedDefaults {
    public static let password: String = "uitest-password"
    public static var timeout: TimeInterval = 10
}
```

| Member | Type | Description |
|--------|------|-------------|
| `password` | `String` (let) | Shared test user password. Match this in your app-side seeder |
| `timeout` | `TimeInterval` (var) | Global fallback for every UI helper's `timeout:` parameter. Override in `setUpWithError` to adjust all helpers simultaneously |

---

### Element Waiting

| Method | Returns | Description |
|--------|---------|-------------|
| `waitForElement(_ query: XCUIElementQuery, id: String, timeout: TimeInterval? = nil, _ message: String? = nil, ...)` | `XCUIElement` | Waits for an element to appear and returns it |
| `elementAppeared(_ query: XCUIElementQuery, named: String, timeout: TimeInterval? = nil, _ message: String? = nil, ...)` | `Void` | Asserts an element appears within timeout |
| `elementNotAppeared(_ query: XCUIElementQuery, named: String, timeout: TimeInterval? = nil, _ message: String? = nil, ...)` | `Void` | Asserts an element does not appear within timeout |

All three use `XCTNSPredicateExpectation` with `NSPredicate(format: "exists == TRUE/FALSE")`. When `timeout` is `nil`, each call reads `UITestSeedDefaults.timeout` at invocation time — so a later mutation to the global default takes effect immediately.

---

### Element Retrieval

| Method | Returns | Description |
|--------|---------|-------------|
| `getRowContainingText(parentViewId: String, text: String, maxScrollAttempts: Int = 3, isRequiredToExist: Bool = false, timeout: TimeInterval? = nil, ...)` | `XCUIElement` | Finds a row by scrolling within a collection view identified by ID |
| `getRowContainingText(parentView: XCUIElement? = nil, text: String, maxScrollAttempts: Int = 3, isRequiredToExist: Bool = false, ...)` | `XCUIElement` | Finds a row by scrolling within a given parent view |
| `getRowIndex(_ text: String, parentView: XCUIElement? = nil)` | `Int?` | Returns the index of a row containing text (no scrolling) |
| `getField(fieldId: String, query: XCUIElementQuery? = nil, isSecure: Bool, _ message: String? = nil, timeout: TimeInterval? = nil, ...)` | `XCUIElement` | Retrieves a text field or secure text field |

### Parameters: getRowContainingText (by parentViewId)

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `parentViewId` | `String` | required | Accessibility identifier of the scrollable parent view |
| `text` | `String` | required | Text to find within a row |
| `maxScrollAttempts` | `Int` | `3` | Maximum swipe-up attempts to find the row |
| `isRequiredToExist` | `Bool` | `false` | If `true`, fails test when row is not found |
| `timeout` | `TimeInterval?` | `nil` | Falls back to `UITestSeedDefaults.timeout` |

### Behavioral Notes — Element Retrieval

- `getRowContainingText(parentViewId:)` always uses `app.collectionViews` to find the parent.
- The scroll-search loop swipes up to `maxScrollAttempts` times. The failure message always says "3" regardless of the actual `maxScrollAttempts` value (bug).
- `getRowIndex` uses `allElementsBoundByIndex.firstIndex(where:)` — no scrolling, checks only visible cells.
- `getField` branches on `isSecure`: uses `app.secureTextFields` or `app.textFields`. The optional `message` is forwarded to the internal `waitForElement` as its assertion failure message.

---

### Element Interaction

| Method | Returns | Description |
|--------|---------|-------------|
| `tapCenter(of element: XCUIElement, dx: CGFloat = 0.8, dy: CGFloat = 0.5)` | `Void` | Taps at a normalized coordinate within the element |

**Note**: Default `dx: 0.8` taps at 80% from the left edge — biased right, not geometric center.

---

### Buttons

| Method | Returns | Description |
|--------|---------|-------------|
| `tapAlertSheetButton(_ id: String, timeout: TimeInterval? = nil, ...)` | `Void` | Taps a button in a scroll view alert sheet |
| `tapButton(_ name: String, query: XCUIElementQuery? = nil, timeout: TimeInterval? = nil, ...)` | `Void` | Waits for and taps a button |
| `tapAlertButton(buttonId: String = "Okay", timeout: TimeInterval? = nil, ...)` | `Void` | Taps a button in an alert dialog |
| `tapFirstButton(_ name: String, query: XCUIElementQuery? = nil, timeout: TimeInterval? = nil, ...)` | `Void` | Taps the first matching button when iOS produces duplicate accessibility elements |

### Behavioral Notes — Buttons

- `tapAlertSheetButton` uses hardcoded query: `app.scrollViews.otherElements.buttons`.
- `tapAlertButton` uses hardcoded query: `app.alerts.buttons`. Default button is `"Okay"`.
- `tapButton` uses `app.buttons` when no query is provided.
- `tapFirstButton` resolves `(query ?? app.buttons)[name].firstMatch` and taps after a `waitForExistence` check. Use this specifically for iOS 26+ alert buttons that appear as duplicate elements in the accessibility tree — `tapButton` will fail in that scenario because `XCUIElementQuery[id]` requires a unique match.

### Decision Guide — tapButton vs. tapFirstButton

| Situation | Use |
|-----------|-----|
| Ordinary button in the app | `tapButton` |
| Alert button on iOS 26+ (duplicate elements) | `tapFirstButton` |
| Any case where the accessibility tree reports multiple elements with the same identifier | `tapFirstButton` |

---

### Controls

| Method | Returns | Description |
|--------|---------|-------------|
| `tapToggle(_ id: String, timeout: TimeInterval? = nil, ...)` | `Void` | Taps a toggle switch |
| `tapSegmentedControl(pickerId: String, query: XCUIElementQuery? = nil, buttonId: String, timeout: TimeInterval? = nil, ...)` | `Void` | Taps a segment in a segmented control |
| `adjustStepper(id: String, isIncrementing: Bool, count: Int = 1, timeout: TimeInterval? = nil, ...)` | `Void` | Increments or decrements a stepper |

### Behavioral Notes — Controls

- `tapToggle` delegates to `tapCenter(of:)` — inherits the `dx: 0.8` right-biased tap.
- `adjustStepper` constructs button IDs as `"\(id)-Increment"` or `"\(id)-Decrement"`. The app must use this exact format.
- `adjustStepper` taps `count` times in a loop with no delay between taps.

---

### Text Input

| Method | Returns | Description |
|--------|---------|-------------|
| `typeInField(fieldId: String, isSecure: Bool = false, text: String, clearField: Bool = false, tapFieldBeforeTyping: Bool = true, tapSubmitButton: Bool = false, submitButtonText: String = "Done", timeout: TimeInterval? = nil, ...)` | `Void` | Types text into a field identified by ID |
| `typeInAlertField(fieldIndex: Int = 0, text: String, clearField: Bool = false, ...)` | `Void` | Types text into an alert's text field |
| `typeInField(field: XCUIElement, text: String, clearField: Bool = false, ...)` | `Void` | Types text into a pre-retrieved field element |

### Parameters: typeInField (by fieldId)

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `fieldId` | `String` | required | Accessibility identifier of the field |
| `isSecure` | `Bool` | `false` | If `true`, searches secure text fields instead |
| `text` | `String` | required | Text to type into the field |
| `clearField` | `Bool` | `false` | If `true`, clears existing text before typing |
| `tapFieldBeforeTyping` | `Bool` | `true` | Tap the field to focus before typing |
| `tapSubmitButton` | `Bool` | `false` | Tap submit/Done button after typing |
| `submitButtonText` | `String` | `"Done"` | Label of the submit button |
| `timeout` | `TimeInterval?` | `nil` | Falls back to `UITestSeedDefaults.timeout` |

### Behavioral Notes — Text Input

- `clearField` works by reading `field.value as? String` and typing that many `.delete` key presses. If the accessibility value differs from actual content length, the clear may be incomplete.
- `tapSubmitButton` taps from `app.keyboards.buttons`.
- `typeInAlertField` directly accesses `app.alerts.textFields.element(boundBy: fieldIndex)` — no existence check.
- The `(field: XCUIElement, ...)` overload has internal typos in its parameter labels (`tapFieldBeforeTypIng`, `tapSubmitButon`). Callers that rely on defaults are unaffected; callers passing these labels explicitly must use the misspelled forms.

---

### Date Picker

| Method | Returns | Description |
|--------|---------|-------------|
| `selectDate(picker: XCUIElement, dayNumberToSelect: Int)` | `Void` | Selects a day in a pre-retrieved date picker |
| `selectDate(pickerId: String, dayNumberToSelect: Int, _ message: String? = nil, timeout: TimeInterval? = nil, ...)` | `Void` | Finds picker by ID and selects a day |
| `selectDate(pickerId: String, currentMonth: String? = nil, currentYear: Int? = nil, newMonth: String? = nil, newDay: Int, timeout: TimeInterval? = nil, ...)` | `Void` | Selects a date with month navigation (UIKit only) |
| `selectTime(pickerId: String, hour: String, minute: String, period: String? = nil, timeout: TimeInterval? = nil, ...)` | `Void` | Adjusts a compact `.hourAndMinute` DatePicker via picker wheels (UIKit only) |

### Behavioral Notes — Date Picker

- Day selection looks for `app.datePickers.collectionViews.staticTexts["\(dayNumberToSelect)"]`.
- The UIKit-only overload navigates months via `pickerWheels`. All three month parameters (`currentMonth`, `currentYear`, `newMonth`) must be non-nil for month switching — any `nil` silently skips month adjustment.
- Year does not change — `currentYear` is passed to both the before and after month button lookups.
- `selectTime` taps the picker to open its inline overlay, adjusts wheels at indices 0 (hour), 1 (minute), and 2 (period) via `app.pickerWheels`, then taps the picker again to dismiss. Wheel values are **locale-dependent**: 12h locales expect 1–12 hour and an AM/PM `period`; 24h locales expect 0–23 hour and `period: nil`.

---

### Alerts

| Method | Returns | Description |
|--------|---------|-------------|
| `waitForThirdPartyAlert(decription: String, button: String, withAppTap: Bool = false)` | `Void` | Registers a UI interruption monitor for third-party alerts |

### Behavioral Notes — Alerts

- Parameter name `decription` is a typo (missing 's').
- **The `decription` parameter is ignored** — `addUIInterruptionMonitor(withDescription:)` receives `description` (the `XCTestCase.description` property) instead.
- If `withAppTap: true`, taps `app` after registering the monitor (required to trigger interruption monitors in XCTest).
- For the iOS "Save Password?" system prompt specifically, prefer `dismissPasswordPromptIfNeeded()` in the Seeding section — it's more targeted and does not rely on UI interruption monitors.

---

### Row Actions

| Method | Returns | Description |
|--------|---------|-------------|
| `deleteRow(row: XCUIElement, swipeButtonId: String = "Delete", withConfirmationAlert: Bool = false, alertSheetButtonId: String? = nil, timeout: TimeInterval? = nil, ...)` | `Void` | Swipes left on a row and taps the delete button |

### Parameters: deleteRow

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `row` | `XCUIElement` | required | The row element to delete |
| `swipeButtonId` | `String` | `"Delete"` | Label of the swipe action button |
| `withConfirmationAlert` | `Bool` | `false` | If `true`, taps confirmation alert after swipe |
| `alertSheetButtonId` | `String?` | `nil` | Label of alert confirmation button (falls back to `swipeButtonId`) |
| `timeout` | `TimeInterval?` | `nil` | Falls back to `UITestSeedDefaults.timeout` |

Sequence: `row.swipeLeft()` -> `tapButton(swipeButtonId)`. If `withConfirmationAlert`: also calls `tapAlertSheetButton(alertSheetButtonId ?? swipeButtonId)`.

---

### Assertions

| Method | Returns | Description |
|--------|---------|-------------|
| `assertElementIsNil(query: XCUIElementQuery, id: String, ...)` | `Void` | Asserts an element does not exist (no waiting) |
| `assertDateInPicker(_ datePicker: XCUIElement, date: Date, ...)` | `Void` | Asserts a date picker shows the expected date |
| `assertFieldText(field: XCUIElement, isEqualTo text: String, ...)` | `Void` | Asserts a text field's value matches expected text |
| `assertButton(id: String, query: XCUIElementQuery? = nil, isEnabled: Bool, timeout: TimeInterval? = nil, ...)` | `Void` | Waits for a button and asserts its enabled state |
| `assertRowIndex(rowText: String, parentView: XCUIElement?, currentSectionId: String, nextSectionId: String?, ...)` | `Void` | Asserts a row appears between two section headers |

### Behavioral Notes — Assertions

- `assertElementIsNil` does **not** wait — checks existence synchronously. Use `elementNotAppeared` for async disappearance.
- `assertDateInPicker` reads `datePicker.buttons.firstMatch.value as? String` and compares against `date.asDatePickerString()` (`"MMM d, yyyy"` format).
- `assertFieldText` reads `field.value as? String` — if the cast fails, reports a nil failure.
- `assertButton` waits for the button first (up to `timeout`), then checks `isEnabled` synchronously.

---

### Test Data

| Method | Returns | Description |
|--------|---------|-------------|
| `makeRandomEmail()` | `String` | Generates a random email like `"3tester74@gmail.com"` |
| `makeRandomUsername()` | `String` | Generates a random username like `"tester123"` |
| `getRandomNumber()` | `Int` | Returns a random integer 0-9 |

Prefer `mainUserEmail` / `seedEmail(for:)` for seeded flows — those are tied to the per-run `runId` and match the app-side seeder. `makeRandomEmail` is appropriate for tests that don't rely on a seeded backend.

---

## Extension: XCUIElement

```swift
public extension XCUIElement {
    func isFullyVisible(in parentView: XCUIElement) -> Bool
}
```

Frame-based check using `CGRect.contains(_:)`. Returns `true` only when the element's frame is **fully enclosed** within the parent's frame.

---

## Function: runStep

```swift
@MainActor
public func runStep(_ details: String, block: () -> Void)
```

Wraps a block in `XCTContext.runActivity(named:)` for structured test output. Use to label sections of a UI test.

### Usage Example

```swift
runStep("Navigate to settings") {
    tapButton("Settings")
    waitForElement(app.navigationBars, id: "Settings")
}

runStep("Toggle dark mode") {
    tapToggle("darkModeToggle")
}
```

---

## Best Practices

- **Prefer `launchSeeded` over manual `app.launch()` for seeded flows** — it handles unique `runId` generation, user email, and config encoding in one call.
- **Set `UITestSeedDefaults.timeout` once, not per call** — if your CI is slow, bump the global default in `setUpWithError` rather than passing `timeout:` to every helper.
- **Use `mainUserEmail`, not `makeRandomEmail`, for seeded tests** — the app-side seeder needs to know which email to provision.
- **Call `dismissPasswordPromptIfNeeded()` after any login flow** — it's safe to call unconditionally; it no-ops if the prompt doesn't appear.
- **Call `app.launch()` in your test subclass** — `BaseUITestCase.setUpWithError()` configures the environment but does not launch, unless you use `launchSeeded`.
- **Call `addKeyToENV` before `app.launch()`** — Environment variables are passed at launch time and cannot be changed after.
- **Use `waitForElement` before interacting** — Most interaction methods already wait internally, but direct `app.buttons[id].tap()` calls should be preceded by a wait.
- **`assertElementIsNil` is synchronous** — If you need to verify an element disappears after an action, use `elementNotAppeared` which waits up to `UITestSeedDefaults.timeout`.
- **`tapCenter` default is right-biased** — The `dx: 0.8` default taps at 80% from the left. Pass `dx: 0.5` for true center.
- **Stepper accessibility IDs must use `"-Increment"`/`"-Decrement"` suffix** — `adjustStepper` constructs these IDs from the stepper's base ID.
- **Use `tapFirstButton` for iOS 26+ alert buttons** — when `tapButton` fails because the accessibility tree reports multiple matches, `tapFirstButton` resolves via `.firstMatch`.
- **`waitForThirdPartyAlert` ignores its `decription` parameter** — The monitor description is always the test case's `description` property. The `button` parameter is what matters.
- **Use `runStep` for test organization** — Wraps actions in `XCTContext.runActivity` for readable test logs.

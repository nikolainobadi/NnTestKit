# UI Test Writing Reference

This document is the **canonical source of truth** for how Swift UI test cases must be written. It defines **rules**, not suggestions.

---

## 1. Test Naming

UI test methods use `snake_case` names that describe the behavior being tested, prefixed with `test_`.

### Format

```
test_<context>_<action_or_condition>_<expected_outcome>
```

The name should read as a sentence describing what the test verifies. Someone reading only the test name should understand the scenario without reading the test body.

### Good Names

```swift
func test_cannot_save_task_without_name()
func test_admin_can_update_task_details()
func test_guest_can_link_account_to_email()
func test_normal_user_accepts_invite_and_joins_house()
func test_pro_welcome_only_shows_during_initial_purchase()
```

### Bad Names

```swift
func testLogin()                    // Too vague
func test_1()                       // Not descriptive
func test_tapButton()               // Describes mechanics, not behavior
func testSettingsScreenLoads()       // camelCase, not snake_case
```

### Rules

- Always use `snake_case` (not camelCase like unit tests)
- Always prefix with `test_`
- Describe **observable behavior**, not UI mechanics
- Include the user role or context when it matters (e.g., `test_guest_`, `test_admin_`)
- Long names are acceptable when they improve clarity

---

## 2. Class Naming

Test class names follow: `<Feature><UserRole>UITests`

### Examples

```swift
NormalUserTasksUITests      // Tasks feature, normal user perspective
GuestRoomsUITests           // Rooms feature, guest user
ProUpgradeUITests           // Pro upgrade flow
LoginUITests                // Login flow (no role needed — it's the entry point)
```

The user role is included when the same feature behaves differently for different users. Omit it when there's only one relevant role.

---

## 3. Test Structure

Every UI test follows this four-phase pattern:

### Seed -> Launch -> Act -> Assert

```swift
func test_can_add_task_with_valid_name() {
    // Seed & Launch
    launchAndNavigateToTaskList()
    
    // Act
    tapButton(.taskListId(.addButton))
    typeInField(fieldId: .taskDetailId(.nameField), text: "New Task")
    tapButton(.taskDetailId(.saveButton))
    
    // Assert
    elementAppeared(app.staticTexts, named: "New Task")
}
```

### Rules

- Each test method must launch the app fresh (via `launchSeeded`, `launchApp`, or a helper that calls one of these)
- Never rely on state from a previous test — tests must be independent
- The assert phase should verify **visible UI state**, not internal app state
- Keep tests focused on one behavioral scenario

### When to Use runStep

For tests that cover a multi-phase flow, use `runStep` to create labeled sections in Xcode's test activity log:

```swift
func test_guest_upgrades_to_full_account() {
    runStep("Login as guest") {
        launchApp(tapGetStarted: true)
        tapButton("Login as Guest")
    }
    
    runStep("Navigate to profile and link email") {
        tapButton(.tabBarId(.settings))
        getRowContainingText(text: "Profile").tap()
        linkAccountToEmail()
    }
    
    runStep("Verify account is linked") {
        elementAppeared(app.staticTexts, named: "Email linked")
    }
}
```

Use `runStep` when:
- A test has 3+ distinct phases
- The test flow would be hard to debug without phase labels
- The same logical test covers setup, action, and verification across different screens

---

## 4. Using NnTestKit Helpers

Prefer NnTestKit helper methods over raw `XCUIApplication` calls. The helpers handle waiting, timeouts, and common interaction patterns consistently.

### Prefer This

```swift
tapButton(.settingsId(.logoutButton))
typeInField(fieldId: .loginId(.emailField), text: email)
elementAppeared(app.staticTexts, named: "Welcome")
getRowContainingText(text: "Kitchen").tap()
```

### Over This

```swift
app.buttons["logoutButton"].tap()                           // No wait
app.textFields["emailField"].tap(); app.typeText(email)     // Manual sequence
XCTAssert(app.staticTexts["Welcome"].waitForExistence(...)) // Raw predicate
app.cells.staticTexts["Kitchen"].tap()                      // Fragile query
```

The helpers integrate timeout management (via `UITestSeedDefaults.timeout`), provide better failure messages, and handle edge cases like scrolling to find rows.

---

## 5. Accessibility Identifier Usage (Required)

All button and control interactions **must** reference accessibility IDs via the type-safe enum pattern (Style A or Style B from `AccessibilityIdReference.md`). Text-based interaction queries are forbidden.

### Required

```swift
tapButton(.taskListId(.addButton))
tapButton(SettingsAccessibilityId.settingsSaveButton.rawValue)
waitForElement(app.switches, id: .taskDetailId(.reminderToggle))
```

### Forbidden

```swift
tapButton("Save")                                  // text-based — ambiguous
tapButton("addButton")                              // raw string — typo-prone
app.buttons["Save"].tap()                           // text-based — ambiguous
app.switches["Notifications"].tap()                 // text-based — fragile
```

### Why

Duplicate labels break text-based queries. A common case: a Settings sheet with a "Save" button presents an editor sheet that also has a "Save" button, which itself presents an item-editor with a third "Save". `tapButton("Save")` can no longer pick a single target — XCUITest taps the wrong one, or fails to resolve which to tap, depending on the active accessibility window. Type-safe IDs are the only reliable way to disambiguate.

Type-safe references also catch typos at compile time and make refactoring safe. See `AccessibilityIdReference.md` for the enum / extension pattern and the production-side requirement to give every interactive element its own ID.

### Scope of the Rule

This rule applies to **interactive** elements: `Button`, `Toggle`, `Picker`, `TextField`, and other tappable / editable controls.

Text-based assertions on **displayed content** remain acceptable, because they're verifying what the user sees rather than driving interaction:

```swift
elementAppeared(app.staticTexts, named: "Welcome")          // OK — verifying content
XCTAssertTrue(app.staticTexts["250 ml"].exists)             // OK — verifying chip label
```

If you find yourself wanting to *tap* a static text by its visible label, that element should be a `Button` with its own accessibility ID — not a `Text`.

---

## 6. Assertions

UI test assertions verify **visible state** — what the user sees on screen.

### Common Assertion Patterns

```swift
// Element appears (waits up to timeout)
elementAppeared(app.staticTexts, named: "Success")

// Element does not appear (waits up to timeout to confirm absence)
elementNotAppeared(app.buttons, named: "Delete")

// Element does not exist (synchronous, no waiting)
assertElementIsNil(query: app.buttons, id: "adminButton")

// Button enabled/disabled state
assertButton(id: .submitButton, isEnabled: false)

// Text field value
assertFieldText(field: emailField, isEqualTo: "test@example.com")
```

### Rules

- Assert **what the user sees**, not implementation details
- Use `elementAppeared` for things that should be visible (async, with timeout)
- Use `elementNotAppeared` for things that should NOT be visible (async, with timeout)
- Use `assertElementIsNil` only for synchronous checks where the element should never have existed
- One primary assertion per test (secondary assertions are acceptable when they verify the same behavioral outcome from different angles)

---

## 7. Comments

Do not add comments inside test methods. The test name carries the descriptive burden.

### Allowed

- `// MARK:` for grouping test methods by area
- `// MARK: - Helpers` for the private extension

### Not Allowed

- Inline comments explaining what a line does
- "Arrange / Act / Assert" section comments
- Comments restating the test name

---

## 8. Test Isolation

Each test must be fully independent. Running any single test in isolation must produce the same result as running the full suite.

### Rules

- Always launch the app fresh in each test (never skip `app.launch()` or `launchSeeded`)
- Never depend on execution order
- Never share mutable state between test methods
- Use unique names for created entities (`makeUniqueName`) to avoid collisions in parallel runs
- Disable features that interfere with test focus (ads, onboarding) via environment keys

---

## 9. Handling Flakiness

UI tests are inherently more flaky than unit tests due to timing, animations, and async loading. These patterns reduce flakiness:

- **Use NnTestKit helpers** — they wait for elements before interacting
- **Set appropriate timeouts** — bump `UITestSeedDefaults.timeout` for slow CI, don't hardcode per-call timeouts everywhere
- **Use `dismissPasswordPromptIfNeeded()`** after login flows — the iOS password save prompt is unpredictable
- **Disable irrelevant features** — ads, analytics prompts, onboarding tutorials should be disabled via environment keys unless specifically being tested
- **Use `runStep`** — when a test fails, labeled steps make it immediately clear which phase failed

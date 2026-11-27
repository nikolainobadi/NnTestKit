# UI Test Helper Patterns

This document describes reusable helper method patterns for UI tests. Helpers reduce duplication and make tests read as high-level behavioral descriptions rather than mechanical UI interactions.

---

## Navigation Helpers

Navigation helpers encapsulate the steps to reach a specific screen. They belong in the test class (as private helpers) when used by only that class, or in a base class when shared.

### Pattern: launchAndNavigateTo

Combines seeding, launching, and navigation into a single call:

```swift
private func launchAndNavigateToTaskList(config: SeedConfig = SeedConfig()) {
    launchSeeded(config: config)
    tapButton(.tabBarId(.tasks))
    getRowContainingText(text: "My Room").tap()
}
```

Tests then read cleanly:

```swift
func test_can_add_task() {
    launchAndNavigateToTaskList()
    // ... test body
}

func test_admin_can_add_task_beyond_limit() {
    launchAndNavigateToTaskList(config: SeedConfig(userRole: .admin, hasReachedLimit: true))
    // ... test body
}
```

### Pattern: navigateTo (No Launch)

When the launch step varies but navigation is consistent:

```swift
private func navigateToSettings() {
    tapButton(.tabBarId(.settings))
    waitForElement(app.navigationBars, id: "Settings")
}
```

---

## Login Helpers

Login helpers abstract authentication flows. They typically live in a base class since multiple test files need them.

### Email Login

```swift
func loginWithEmail(email: String, password: String = UITestSeedDefaults.password) {
    typeInField(fieldId: .loginId(.emailField), text: email)
    typeInField(fieldId: .loginId(.passwordField), isSecure: true, text: password)
    tapButton(.loginId(.submitButton))
    dismissPasswordPromptIfNeeded()
}
```

### Guest Login

```swift
func loginAsGuest() {
    tapButton(.loginId(.guestButton))
    tapButton(.welcomeId(.continueButton))
}
```

### Seeded Login

When using NnTestKit's seeding infrastructure, combine seed setup with login:

```swift
func launchSeededWithLogin(config: SeedConfig = SeedConfig()) {
    setSeedConfig(config, envKeys: [TestEnvKey.disableAds.rawValue])
    launchApp(tapGetStarted: true)
    loginWithEmail(email: mainUserEmail)
}
```

Note the use of `setSeedConfig` (not `launchSeeded`) because the login flow controls the launch.

---

## Relaunch Helpers

Some tests need to verify state persistence across app restarts. Relaunch helpers terminate and relaunch the app with adjusted configuration.

### Pattern

```swift
func relaunchApp(enableFeature: Bool = false) {
    app.terminate()
    
    // Adjust environment for the relaunch
    removeKeyFromENV(TestEnvKey.logout.rawValue)  // Don't auto-logout on relaunch
    
    if enableFeature {
        removeKeyFromENV(TestEnvKey.disableAds.rawValue)
    }
    
    app.launch()
}
```

### When to Use

- Testing that data persists after the app is killed and relaunched
- Testing features that only appear on second launch (e.g., ads after sign-up)
- Testing different launch configurations in the same test

---

## CRUD Helpers

For features with standard create/read/update/delete flows, helper methods make tests declarative:

### Create

```swift
private func addItem(_ name: String) {
    tapButton(.listId(.addButton))
    typeInField(fieldId: .detailId(.nameField), text: name)
    tapButton(.detailId(.saveButton))
}
```

### Read / Find

```swift
private func getItemRow(_ name: String) -> XCUIElement {
    getRowContainingText(text: name, isRequiredToExist: true)
}
```

### Update

```swift
private func editItemName(oldName: String, newName: String) {
    getItemRow(oldName).tap()
    typeInField(fieldId: .detailId(.nameField), text: newName, clearField: true)
    tapButton(.detailId(.saveButton))
}
```

### Delete

```swift
private func deleteItem(_ name: String) {
    let row = getItemRow(name)
    deleteRow(row: row, withConfirmationAlert: true)
}
```

Tests then read as business logic:

```swift
func test_can_edit_item_name() {
    launchAndNavigateToList()
    addItem("Original Name")
    editItemName(oldName: "Original Name", newName: "Updated Name")
    elementAppeared(app.staticTexts, named: "Updated Name")
}
```

---

## Verification Helpers

When multiple tests verify the same UI state, extract assertion groups into helpers:

```swift
private func verifyEmptyState() {
    elementAppeared(app.staticTexts, named: .listId(.emptyStateLabel))
    assertElementIsNil(query: app.buttons, id: .listId(.filterToggle))
}

private func verifyItemCount(_ expected: Int) {
    let countLabel = waitForElement(app.staticTexts, id: .listId(.countLabel))
    XCTAssertEqual(countLabel.label, "\(expected) items")
}
```

### Rules

- Verification helpers should be clearly named with `verify` or `assert` prefix
- They contain only assertions — no navigation or actions
- They should fail with clear, specific messages

---

## Limit / Edge Case Helpers

For testing capacity limits, quota enforcement, or boundary conditions:

```swift
private func fillToLimit(config: SeedConfig) {
    launchAndNavigateToList(config: config)
    // Add items until limit is reached
    for i in 1...config.maxItems {
        addItem("Item \(i)")
    }
}

private func verifyLimitReached() {
    tapButton(.listId(.addButton))
    elementAppeared(app.staticTexts, named: "Limit Reached")
}

private func verifyCanAddAfterDelete() {
    deleteItem("Item 1")
    addItem("Replacement Item")
    elementAppeared(app.staticTexts, named: "Replacement Item")
}
```

---

## StoreKit / In-App Purchase Helpers

For testing premium features, set up a `SKTestSession` in a base class:

```swift
class BaseProUserUITestCase: BaseUITestCase {
    var session: SKTestSession!
    
    override func setUpWithError() throws {
        session = try SKTestSession(configurationFileNamed: "StoreKitConfig")
        session.resetToDefaultState()
        session.clearTransactions()
        session.disableDialogs = true
        try super.setUpWithError()
    }
    
    func purchasePro() {
        tapButton(.upgradeId(.purchaseButton))
        // StoreKit test session auto-approves
        elementAppeared(app.staticTexts, named: "Pro Activated")
    }
}
```

---

## Alert and System Prompt Helpers

### Third-Party Auth Alerts

```swift
func handleGoogleSignInAlert() {
    waitForThirdPartyAlert(
        decription: "wants to use google.com",
        button: "Continue"
    )
}
```

### Confirmation Dialogs

```swift
private func confirmDeletion() {
    tapAlertButton(buttonId: "Delete")
}

private func cancelDeletion() {
    tapAlertButton(buttonId: "Cancel")
}
```

---

## Data Generation Helpers

For tests that create entities, use unique names to avoid collisions:

```swift
private func makeUniqueName(_ prefix: String) -> String {
    "\(prefix)_\(getRandomNumber())\(getRandomNumber())"
}
```

For seeded tests, use `mainUserEmail` and `seedEmail(for:)` instead of `makeRandomEmail()` — these are tied to the run's unique `runId`.

---

## Where Helpers Live

| Scope | Location |
|-------|----------|
| Used by one test class | Private extension on that class |
| Used by multiple classes in same feature | Intermediate base class (e.g., `BaseSettingsUITestCase`) |
| Used across all test classes | Extension on `BaseUITestCase` in the `Shared/` directory |
| Used across projects | NnTestKit itself (propose upstream if truly generic) |

The goal is to keep helpers as close to their usage as possible while eliminating duplication.

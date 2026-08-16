# UI Test File Structural Reference

This document is the **canonical source of truth** for how Swift UI test files must be structured. It defines **rules**, not suggestions.

UI tests are fundamentally different from unit tests: they use XCTest (not Swift Testing), require `@MainActor` classes (not structs), launch a real app process, and interact through accessibility identifiers. These differences drive the structural rules below.

---

## 1. Imports

All UI test files must declare imports at the top, in this order:

1. `import XCTest`
2. `import NnUITestHelpers` (provides `BaseUITestCase` and all interaction helpers)
3. Feature-specific accessibility ID modules (e.g., `import MyFeatureAccessibility`)
4. Any additional test helper imports (e.g., `import NnLoginUITestHelpers`)

### Rules

- `XCTest` must always be imported
- `NnUITestHelpers` must always be imported (it provides `BaseUITestCase`)
- Do **not** use `@testable import` in UI tests — UI tests interact with the app through its public UI, not internal APIs
- Accessibility ID modules are imported as regular (non-testable) imports since they are separate public targets
- No unused imports

---

## 2. Test Class

Each UI test file must declare **exactly one** test class.

### Required Shape

```swift
@MainActor
final class <Feature>UITests: BaseUITestCase {
```

### Rules

- Must be `@MainActor` — all XCUITest interactions run on the main thread
- Must be `final class` — UI tests require XCTestCase inheritance
- Must inherit from `BaseUITestCase` (or a project-specific subclass of it)
- Never use `struct` for UI tests (unlike unit tests)
- Never use Swift Testing (`import Testing`, `@Test`) for UI tests — XCUITest requires XCTest

### When to Use an Intermediate Base Class

Create an intermediate base class when multiple test classes share setup that goes beyond what `BaseUITestCase` provides:

- **User-role-based**: `BaseGuestUITestCase`, `BaseProUserUITestCase` — when different user types require distinct login flows, StoreKit sessions, or environment configuration
- **Feature-area-based**: `BaseSettingsUITestCase` — when multiple test classes in the same area share navigation helpers

Intermediate base classes should:
- Live in a shared directory within the UI test target
- Be `open` or non-final so test classes can inherit from them
- Contain only setup and shared helpers — never test methods

---

## 3. setUp

### Required Pattern

```swift
override func setUpWithError() throws {
    try super.setUpWithError()
    // Additional setup here (env keys, StoreKit sessions, etc.)
}
```

### Non-Throwing Variant

When the setup body cannot throw, the non-`throws` form is acceptable:

```swift
override func setUp() {
    super.setUp()
    app.launchEnvironment["UI_TEST_DEFAULTS_SUFFIX"] = UUID().uuidString
}
```

Use `setUpWithError() throws` when any line in the body could throw (e.g., `SKTestSession` initialization). Use `setUp()` when the body is purely assignment or `app.launchEnvironment` mutation.

### Rules

- Always call `super.setUp()` (or `super.setUpWithError()` in the throwing variant) first — it sets `continueAfterFailure = false` and injects `IS_UI_TESTING`
- Do **not** call `app.launch()` in setUp unless every test in the class uses the same launch configuration
- Prefer launching in individual test methods or in private helpers — this gives each test control over its seed config and environment keys
- Set `UITestSeedDefaults.timeout` here if the CI environment needs a longer default

### No tearDown Required

- `BaseUITestCase` does not require explicit tearDown
- Each test relaunches the app fresh, providing natural isolation
- Only add tearDown if you need to clean up external state (e.g., StoreKit sessions)

---

## 4. Test Methods

Test methods go in the main class body, separated by `// MARK:` comments when the class covers multiple related areas.

```swift
// MARK: - Login
func test_can_login_with_valid_credentials() { ... }
func test_cannot_login_with_empty_email() { ... }

// MARK: - Password Reset
func test_can_request_password_reset() { ... }
```

See `UITestWritingReference.md` for test writing rules.

---

## 5. Private Helpers

Private helper methods go in extensions at the bottom of the file, below all test methods.

### Rules

- Use `private` helpers for repeated navigation sequences, multi-step setup, or assertion groups
- Group helpers by purpose using `// MARK:` comments
- Helpers must not contain assertions unless they are assertion-specific helpers (e.g., `verifyEmptyState()`)
- Navigation helpers should be named `navigateTo<Screen>()` or `launchAndNavigateTo<Screen>()`
- Keep helpers in the test file when they're specific to that file; move to the base class when shared across files

### Example Structure

```swift
@MainActor
final class TaskListUITests: BaseUITestCase {
    // MARK: - Adding Tasks
    func test_can_add_task_with_valid_name() { ... }
    func test_cannot_add_task_without_name() { ... }
    
    // MARK: - Deleting Tasks
    func test_can_delete_existing_task() { ... }
}

// MARK: - Helpers
private extension TaskListUITests {
    func launchAndNavigateToTaskList(config: SeedConfig = SeedConfig()) {
        launchSeeded(config: config)
        tapButton(.tabBarId(.tasks))
    }
    
    func addTask(_ name: String) {
        tapButton(.taskListId(.addButton))
        typeInField(fieldId: .taskDetailId(.nameField), text: name)
        tapButton(.taskDetailId(.saveButton))
    }
}
```

---

## 6. File Organization Summary

```
// 1. Imports
import XCTest
import NnUITestHelpers
import MyFeatureAccessibility

// 2. Test class declaration
@MainActor
final class FeatureUITests: BaseUITestCase {

    // 3. setUp (optional — only if needed beyond BaseUITestCase defaults)
    override func setUpWithError() throws { ... }

    // 4. Test methods grouped by // MARK:
    // MARK: - Area A
    func test_scenario_expected_outcome() { ... }

    // MARK: - Area B
    func test_another_scenario() { ... }
}

// 5. Private helpers
// MARK: - Helpers
private extension FeatureUITests {
    func navigateToFeature() { ... }
}
```

---

## 7. File Location

UI test files live in the project's UI test target (e.g., `MyAppUITests/`).

### Rules

- Organize by feature area using subdirectories: `MyAppUITests/LoginTests/`, `MyAppUITests/SettingsTests/`
- Shared base classes and helpers go in a `Shared/` subdirectory
- One test class per file
- File name matches class name: `TaskListUITests.swift` contains `TaskListUITests`
- Do not create new UI test targets — add files to the existing one

### Discovering the UI Test Target

Before creating files, find the existing UI test target:
1. Search for files importing `XCTest` that reference `XCUIApplication`
2. Look for directories ending in `UITests`
3. Check the Xcode project for UI test targets

### Synchronized Folder References

Modern Xcode projects (Xcode 16+) often declare the UI test target's source group as a `PBXFileSystemSynchronizedRootGroup`:

```
FEAF7E9E2FB8FCE700164251 /* MyAppUITests */ = {
    isa = PBXFileSystemSynchronizedRootGroup;
    path = MyAppUITests;
};
```

When the group is synchronized, any `.swift` file dropped into the folder is automatically picked up by the target — no `project.pbxproj` edits required to add new test files. Check for `PBXFileSystemSynchronizedRootGroup` in the pbxproj before manually wiring up files; if it's there, splitting tests into new files is a pure filesystem operation.

This does NOT apply to package product dependencies — adding a new accessibility module to the test target still requires the standard Xcode UI flow (or pbxproj edits) to link it.

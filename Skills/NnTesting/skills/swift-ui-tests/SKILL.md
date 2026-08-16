---
name: swift-ui-tests
description: Sets up and writes Swift UI tests (XCUITest) following project conventions with NnTestKit's BaseUITestCase. USE WHEN setting up UI test files, writing UI tests, creating UI test structure, working with XCUITest, BaseUITestCase, accessibility identifiers for testing, UI test seeding, or writing end-to-end iOS tests.
argument-hint: [feature-or-flow-under-test]
---

# SwiftUITests

Unified skill for setting up and writing Swift UI tests (XCUITest) following canonical conventions built on NnTestKit's `BaseUITestCase`.

UI tests verify complete user flows through the running app. They differ fundamentally from unit tests: they launch an `XCUIApplication`, interact with real UI elements via accessibility identifiers, and assert visible state. This skill covers the structural and behavioral patterns that make UI tests reliable, readable, and maintainable.

---

## Workflow Routing

| Trigger | Workflow | Description |
|---------|----------|-------------|
| Set up a UI test file, create UI test structure, audit UI test file structure | `Workflows/SetupUITestFile.md` | Creates or validates the structural setup of a Swift UI test file |
| Write UI tests, add UI test cases, test a user flow, test a screen | `Workflows/WriteUITests.md` | Writes UI test cases for an existing, structurally valid UI test file |

---

## Context Files

| File | Purpose | Load When |
|------|---------|-----------|
| `UITestStructuralReference.md` | Canonical rules for UI test file structure (imports, class hierarchy, setUp, helpers) | Setting up or auditing a UI test file |
| `UITestWritingReference.md` | Canonical rules for writing UI test cases (naming, structure, assertions, steps) | Writing or reviewing UI test cases |
| `AccessibilityIdReference.md` | How to define and use accessibility identifier enums for type-safe test references | Creating accessibility ID enums or referencing them in tests |
| `SeedingReference.md` | Patterns for test data setup via environment keys and typed seed configs | Setting up test data, feature flags, or launch configuration |
| `UITestHelperPatterns.md` | Reusable helper method patterns (navigation, login, relaunch, data generation) | Writing shared helpers in base classes or extensions |

For NnTestKit API details (method signatures, parameters, behavioral notes), load the `NnTestKit` skill's `UITestApi.md` reference.

---

## Examples

- "Set up UI tests for the Settings screen" -> `Workflows/SetupUITestFile.md`
- "Write UI tests for the login flow" -> `Workflows/WriteUITests.md`
- "Audit the UI test structure for DashboardUITests" -> `Workflows/SetupUITestFile.md`
- "Add a test for the purchase flow" -> `Workflows/WriteUITests.md`

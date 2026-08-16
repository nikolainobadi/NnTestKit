# SetupUITestFile Workflow

You are setting up or validating the **structure** of a Swift UI test file for the provided feature or flow.

This workflow is **structural only**.

Do not:
- Write test cases (beyond the single launch smoke test)
- Invent user flows
- Infer assertions
- Guess about the app's navigation structure

---

## Execution Order (Strict)

Follow these steps **in order**. Do not skip steps. Do not preload resources prematurely.

---

## Step 1: Identify What Is Being Tested

Determine **which feature, screen, or user flow** is under test.

This must come from:
- The explicit argument provided to the skill, **or**
- A direct clarification request to the user

### If the feature is not known

- Stop immediately
- Ask the user which feature or flow is being tested
- Do not read any resources
- Do not locate files
- Do not make assumptions

Only proceed once the feature under test is explicitly identified.

---

## Step 2: Discover Existing UI Test Infrastructure

Before creating files, understand the project's current UI test setup:

1. **Find the UI test target**: Search for directories ending in `UITests`, or files that import `XCTest` and reference `XCUIApplication`
2. **Find the base class hierarchy**: Search for classes inheriting from `BaseUITestCase` — there may be intermediate base classes (e.g., `BaseGuestUITestCase`, `BaseProUserUITestCase`)
3. **Find accessibility ID modules**: Search for enums with `AccessibilityId` in their name, or modules/targets with `Accessibility` in their name
4. **Find shared helpers**: Look for a `Shared/` directory in the UI test target containing base class extensions

Understanding the existing infrastructure is essential — the new file must integrate with what's already there, not create parallel patterns.

---

## Step 3: Locate or Create the UI Test File

### If a test file already exists for this feature

- Use the existing file
- Proceed to structural validation (Step 4)

### If no test file exists

Read `UITestStructuralReference.md`, then:

1. Determine the correct subdirectory within the UI test target (follow existing directory organization)
2. Determine the correct class name following the `<Feature><UserRole>UITests` pattern
3. Determine which base class to inherit from (plain `BaseUITestCase` or an intermediate)
4. Determine which accessibility ID modules to import

Create the file. The output must be complete and immediately compilable — no placeholders.

---

## Step 4: Apply Structural Rules

Read `UITestStructuralReference.md` before applying any rules.

Validate or create the file against these requirements:

1. **Imports** are correct and in order (XCTest, NnUITestHelpers, accessibility modules, other helpers)
2. **Class declaration** is `@MainActor final class` inheriting from the appropriate base
3. **setUp** calls `super.setUpWithError()` and adds any necessary environment configuration
4. **Private helpers** are in an extension at the bottom of the file
5. **File location** follows the project's existing organizational pattern

If anything in this workflow conflicts with `UITestStructuralReference.md`, `UITestStructuralReference.md` wins.

---

## Step 5: Accessibility ID Check

Check whether accessibility identifiers exist for the feature being tested:

- If an accessibility enum exists for this screen, verify the import is included
- If no accessibility enum exists, inform the user that they'll need to create one (reference `AccessibilityIdReference.md`) and add `.accessibilityIdentifier()` calls to their SwiftUI views before the tests can reference those elements

Do not create accessibility ID enums in this workflow — that's a production code change the user must make themselves.

---

## Your Task

Ensure the UI test file exists and complies with all structural requirements from `UITestStructuralReference.md`.

---

## Output Rules

### When the test file does not exist

- Output the **entire contents** of the new test file
- Include one smoke test that verifies the app launches:
  ```swift
  func test_app_launches_successfully() {
      launchSeeded()  // or launchApp() if the project doesn't use seeding
      // Verify the target screen appears
      elementAppeared(app.navigationBars, named: "<ScreenTitle>")
  }
  ```
- The output must be immediately compilable (assuming dependencies exist)
- No placeholders or TODO comments

### When the test file exists

- Output **only actionable violations** of the structural rules
- Describe exactly what must change
- Do not rewrite the file unless explicitly asked

---

## Absolute Constraints

- Never write test cases beyond the single launch smoke test
- Never guess navigation paths — ask the user if unclear
- Never create new UI test targets — add files to the existing one
- Never create accessibility ID modules — that's production code

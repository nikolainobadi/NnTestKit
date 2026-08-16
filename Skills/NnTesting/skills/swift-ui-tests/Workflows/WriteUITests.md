# WriteUITests Workflow

You are writing **UI test cases** for an existing Swift UI test file.

This workflow assumes the test file already exists and that its structure complies with the setup rules enforced by the `SetupUITestFile` workflow.

This workflow must never create files or modify test structure (imports, class declaration, setUp).

---

## Preconditions

If no argument is provided identifying the feature or flow under test:

- Stop immediately
- Ask the user which feature or flow to write tests for
- Do not read any files
- Do not write tests
- Do not make assumptions

Only continue once the feature under test is explicitly provided.

---

## Structural Validation

Before writing tests, verify that the existing test file has valid structure:

- The file must import `XCTest` and `NnUITestHelpers`
- The test class must inherit from `BaseUITestCase` (or a subclass of it)
- The class must be `@MainActor`

If the test file has structural violations:

- Stop immediately
- Inform the user that the test file structure is invalid
- Recommend running the `SetupUITestFile` workflow first
- Do not write tests on top of an invalid structure

---

## Canonical Rules

All rules for writing UI test cases are defined in:

- `UITestWritingReference.md`

You must read `UITestWritingReference.md` before writing or modifying any test code. This is mandatory, not conditional.

You must treat that document as the single source of truth.

---

## Research Phase

Before writing tests, gather context:

1. **Read the existing test file** to understand current coverage and helper methods
2. **Read the production views** for the feature being tested to understand:
   - Available accessibility identifiers
   - User flows and navigation paths
   - Conditional UI (role-based, state-based)
3. **Read the base class** to understand available shared helpers (launch methods, login methods, navigation helpers)
4. **Read accessibility ID enums** for the feature to know which elements can be referenced type-safely
5. **Check if a seed config exists** and what parameters it supports

This research informs which tests are meaningful and which NnTestKit helpers to use.

---

## Your Task

Once the feature is identified and research is complete:

- Write UI test cases that conform **exactly** to `UITestWritingReference.md`
- Use `snake_case` test method names that describe behavior
- Structure each test as: Seed -> Launch -> Act -> Assert
- Use NnTestKit helpers (not raw XCUIApplication calls) for interactions
- Use type-safe accessibility ID references when available
- Use `runStep` for multi-phase tests
- Each test must launch the app fresh and be fully independent
- Create private helper methods for repeated sequences

---

## What to Test

Focus on **user-visible behavior**, not implementation details:

### Good Test Candidates
- Happy path: core flow works as expected
- Validation: required fields, format checks
- Access control: features available/restricted by user role
- Empty states: what the user sees with no data
- Limits: what happens at capacity
- Error states: what the user sees when something fails
- State transitions: before/after an action changes something

### Bad Test Candidates
- Internal state changes not reflected in UI
- Specific animation timing
- Network request details
- Database schema

---

## Output Rules

- Do not modify imports
- Do not modify the class declaration
- Do not modify setUp
- Add `// MARK:` sections when adding tests for a new area to a file that already has organized sections
- Create private helper methods in the bottom extension for any repeated sequence used in 2+ tests
- Do not add comments inside test cases
- Output only valid Swift test code

Be precise. Follow the rules exactly.

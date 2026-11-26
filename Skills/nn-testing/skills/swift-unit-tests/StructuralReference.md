# Swift Unit Test File Canonical Guidelines
## Core Resource

This document is the **canonical source of truth** for how Swift unit test files must be structured.
It is intentionally model-agnostic and is meant to be referenced by model-specific `SKILL.md` adapters.

This resource defines **rules**, not suggestions.


No code examples appear in this document.

Illustrative examples live alongside this file:
- `MakeSutExamples.md` for construction patterns
- `MockInvariantTest.md` for the single allowed invariant test

## Contents

- 1. Imports
- 2. Test Type
- 3. `makeSUT`
- 4. Mock and Test Double Rules
- 5. Allowed Invariant Test (Single Exception)
- 6. Leak Tracking and Lifecycle Management

---

## 1. Imports

All Swift unit test files must declare imports at the top of the file, in the following order:

1. `import Testing`
2. `@testable import <ModuleName>`

### Rules

- `Testing` must always be imported
- The module under test must always be imported using `@testable`
- Additional imports are allowed only if strictly required by the tests
- When memory leak tracking is required, the module that provides the leak-tracking helper must be imported (see section 6)
- No unused imports are allowed

---

## 2. Test Type

Each test file must declare **exactly one top-level test type**.

### Preferred Type: `struct`

- Default choice
- Used in all cases unless a clear exception applies
- Must not use `@Suite`

### When to Use `final class`

A `final class` test type is allowed **only when all of the following are true**:

1. The System Under Test (SUT) is a reference type
2. There is a real risk of retain cycles
3. Memory leak tracking is required

If there is uncertainty, a `struct` must be used.

### `@MainActor` Requirements

If the SUT is annotated with `@MainActor`, the test type must also be annotated with `@MainActor`.

Actor isolation does not imply reference semantics.

---

## 3. `makeSUT`

Every test file must define **exactly one** `makeSUT` helper.

### Rules

- There must never be more than one `makeSUT` per test file
- `makeSUT` must return the System Under Test
- `makeSUT` must live in a private extension
- The extension must be placed at the bottom of the file
- Other private extensions (Helpers, Test Doubles) go above the SUT extension
- The extension must be labeled exactly `// MARK: - SUT`

---

### Responsibilities

`makeSUT` is the **single construction boundary** for the test file.

It is responsible for:

- Instantiating the System Under Test
- Instantiating all required dependencies
- Instantiating all required mocks or test doubles
- Wiring dependencies and mocks into the System Under Test

Construction must never occur inside test cases.

---

### Parameters

`makeSUT` parameters exist to model **test scenarios**, not to mirror implementation details.

Parameters should:
- Represent meaningful differences between test cases
- Default to valid, neutral values that represent the baseline scenario

Parameters must not:
- Blindly mirror initializer signatures
- Expose irrelevant construction details
- Require tests to understand internal wiring

Tests must not construct dependencies or mocks outside of `makeSUT`.

---

### Return Values

`makeSUT` must return the System Under Test.

Dependencies and mocks must also be returned when:
- Their internal state is asserted in tests
- Their recorded behavior is inspected
- Their outputs are validated after exercising the SUT

Allowed return shapes:
- The SUT alone
- A tuple containing the SUT and one or more dependencies or mocks

A tuple return must label every element. The System Under Test is labeled `sut`; each dependency or mock is labeled by its role (for example `delegate`).

Tests must not recreate or access dependencies through other means.

---

### Constraints

- `makeSUT` must not contain assertions, test logic, or validation
- `makeSUT` must not hide dependencies that tests need to observe
- Inline SUT, dependency, or mock creation inside tests is not allowed

### Generic SUTs

When the System Under Test is a generic type:

- `makeSUT` must specify concrete type parameters
- Choose the simplest concrete types that satisfy the generic constraints (e.g., `String`, `Int`, `Void`)
- Generic constraints must be derived from the source code, not guessed
- If the generic constraints cannot be determined, stop and ask the user
- The test type itself must not be generic

---

## 4. Mock and Test Double Rules

For all mock construction, configuration, state, and sharing rules, see [MockRules.md](MockRules.md).

---

## 5. Allowed Invariant Test (Single Exception)

If a test file defines mocks with observable `private(set)` state, **exactly one** invariant test is allowed to verify baseline correctness.

An illustrative example is provided in `MockInvariantTest.md`.

Rules:
- Only one invariant test is permitted per test file
- The test must assert **only baseline state**
- The test must not exercise the SUT or validate behavior
- This is the **only test** the setup workflow is permitted to generate

---

## 6. Leak Tracking and Lifecycle Management

When memory leak tracking is required:

- The test type must be a `final class`
- Leak tracking must be performed inside `makeSUT`
- Leak tracking must not appear in test cases

### Call-Site Forwarding

Leak failures must point at the test that created the SUT, not at `makeSUT`. So:

- `makeSUT` takes the call-site location (file, line, and whatever else the leak-tracking helper accepts) as parameters
- These parameters must always be the **final parameters** in the `makeSUT` signature
- `makeSUT` forwards them unchanged to the leak-tracking helper

Forbidden:
- Calling the leak-tracking helper without forwarding the call-site parameters
- Constructing call-site values inside `makeSUT`
- Reordering call-site parameters ahead of scenario parameters

### Library-Specific Rules

The exact import, test-type annotation, parameter list, and call form depend on the leak-tracking library. Follow the **Leak-Tracking Library** section of this skill's `SKILL.md` before writing or revising a `makeSUT` that tracks leaks.

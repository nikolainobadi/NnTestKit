---
name: swift-unit-tests
description: Sets up, writes, and revises Swift unit tests following project conventions. USE WHEN setting up test files, writing unit tests, validating test structure, auditing, refactoring or reformatting an existing test file to follow the conventions, or working with Swift testing conventions.
argument-hint: [type-under-test]
---

# SwiftUnitTests

Unified skill for setting up and writing Swift unit tests following canonical conventions.

---

## Views Are Out of Scope

This skill does not write, set up, or revise unit tests for Views. Once the type under test is identified, and before any workflow acts on it, read its source and check its protocol conformance:

- **It is a View** if it conforms to `SwiftUI.View` (declares `var body: some View`), `UIViewRepresentable`, or `UIViewControllerRepresentable`.
- **It is not a View** if it is a ViewModel, Store, Presenter, Reducer, or other type that does not conform to those protocols, even when its name contains "View".

If it is a View, stop and tell the user this skill does not write unit tests for Views. Take no further action.

---

## Workflow Routing

| Trigger | Workflow | Description |
|---------|----------|-------------|
| Set up a test file, create test structure, validate test file structure | `Workflows/SetupTestFile.md` | Creates or validates the structural setup of a Swift unit test file |
| Write tests, add test cases, test behavior | `Workflows/WriteTests.md` | Writes unit test cases for an existing, structurally valid test file |
| Refactor, revise, reformat, or update an existing test file to follow the conventions; bring a test file into compliance; fix style violations in tests | `Workflows/ReviseTestFile.md` | Audits an existing test file and revises it into compliance, preserving behavior |

Read the selected workflow completely before acting. It governs which context files to read and what to output. If the workflow or a file it requires cannot be read, stop and tell the user which file is missing; do not apply its rules from memory.

---

## Context Files

| File | Purpose |
|------|---------|
| `StructuralReference.md` | Canonical rules for test file structure (imports, test type, makeSUT, leak tracking) |
| `TestWritingReference.md` | Canonical rules for writing test cases (descriptions, assertions, organization) |
| `MockRules.md` | Mock construction, configuration, state, and sharing rules |
| `TestFileLocationRules.md` | Rules for locating and creating test files |
| `MakeSutExamples.md` | Illustrative makeSUT usage patterns |
| `MockInvariantTest.md` | Example of the single allowed invariant test |

These conventions name no third-party helper library.

---

## Leak-Tracking Library

Before writing or revising a `makeSUT` that tracks leaks, check whether the test target depends on the NnTestKit package (`Package.swift` or the Xcode project's package dependencies).

- **It does:** load the **NnTestKit** skill and read its `LeakTrackingConventions.md` completely. It governs the import, the test-type annotation, the `makeSUT` parameters, and the call form.
- **It does, but the NnTestKit skill is not available:** stop and tell the user to install the `NnTesting` plugin. Do not write the call form from memory.
- **It does not:** use the project's own leak-tracking helper under `StructuralReference.md` section 6. If there is none, ask the user before adding leak tracking.

---

## Examples

- "Set up tests for MyFeatureManager" → `Workflows/SetupTestFile.md`
- "Write unit tests for NetworkClient" → `Workflows/WriteTests.md`
- "Validate the test structure for ParserTests" → `Workflows/SetupTestFile.md`
- "Refactor DailyCareCalculatorTests to follow the conventions" → `Workflows/ReviseTestFile.md`
- "These tests use @Test strings — bring them into compliance" → `Workflows/ReviseTestFile.md`

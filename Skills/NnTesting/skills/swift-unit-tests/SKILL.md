---
name: swift-unit-tests
description: Sets up, writes, and revises Swift unit tests following project conventions. USE WHEN setting up test files, writing unit tests, auditing test structure, refactoring or reformatting an existing test file to follow the conventions, or working with Swift testing conventions.
argument-hint: [type-under-test]
---

# SwiftUnitTests

Unified skill for setting up and writing Swift unit tests following canonical conventions.

---

## Workflow Routing

| Trigger | Workflow | Description |
|---------|----------|-------------|
| Set up a test file, create test structure, audit test file structure | `Workflows/SetupTestFile.md` | Creates or validates the structural setup of a Swift unit test file |
| Write tests, add test cases, test behavior | `Workflows/WriteTests.md` | Writes unit test cases for an existing, structurally valid test file |
| Refactor, revise, reformat, or update an existing test file to follow the conventions; bring a test file into compliance; fix style violations in tests | `Workflows/ReviseTestFile.md` | Audits an existing test file and revises it into compliance, preserving behavior |

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

---

## Examples

- "Set up tests for MyFeatureManager" → `Workflows/SetupTestFile.md`
- "Write unit tests for NetworkClient" → `Workflows/WriteTests.md`
- "Audit the test structure for ParserTests" → `Workflows/SetupTestFile.md`
- "Refactor DailyCareCalculatorTests to follow the conventions" → `Workflows/ReviseTestFile.md`
- "These tests use @Test strings — bring them into compliance" → `Workflows/ReviseTestFile.md`

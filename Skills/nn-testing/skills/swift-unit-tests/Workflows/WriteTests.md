# WriteTests Workflow

You are writing **unit test cases only** for an existing Swift test file.

This workflow assumes the test file already exists and that its structure complies with the setup rules enforced by the `SetupTestFile` workflow.

This workflow must never create files or modify test structure.

---

## Preconditions

If no argument is provided identifying the type under test:

- Stop immediately
- Ask the user which file or type is being tested
- Do not read any files
- Do not write tests
- Do not make assumptions

Only continue once the type under test is explicitly provided.

---

## Structural Validation

Before writing tests, verify that the existing test file has valid structure:

- The file must have correct imports (`import Testing`, `@testable import`)
- The file must have exactly one `makeSUT` in a private extension
- The test type must be appropriate (`struct` or `final class` per StructuralReference rules)

If the test file has structural violations:

- Stop immediately
- Inform the user that the test file structure is invalid
- Recommend running the `SetupTestFile` workflow first
- Do not write tests on top of an invalid structure

---

## Canonical rules

All rules for writing Swift unit tests are defined in the canonical reference:

- `TestWritingReference.md`

You must read `TestWritingReference.md` before writing or modifying any test code. This is mandatory, not conditional.

You must treat that document as the single source of truth.

Do not deviate from it.
Do not reinterpret it.
Do not weaken any rule.

---

## Your task

Once the type under test is explicitly provided:

- Read the existing test file
- Write unit test cases that conform **exactly** to the canonical rules
- Use behavior-driven backtick-escaped function names as test descriptions (not `@Test("...")` string arguments)
- Prefer one assertion per test
- Use arguments only when justified
- Ensure tests are isolated and side-effect free
- Do not assert implementation details

---

## Output rules

- Do not modify imports
- Do not modify the test type declaration
- Do not modify `makeSUT`
- Do not add helpers or test doubles unless required by the tests
- Do not add comments inside test cases
- Do not explain the tests
- Output only valid Swift test code

Be precise. Follow the rules exactly.

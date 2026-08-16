# Swift Unit Test Writing Canonical Guidelines
## Core Reference for `WriteTests` Workflow

This document defines the **non-negotiable rules** for writing Swift unit tests, once the test file structure is already established.

It is reference material.
It is consulted before writing or modifying tests.
It does not describe workflow or provide examples.

If a test violates this document, the test is wrong.

## Test Descriptions

Every test must use a **behavior-driven** description.

### Rules

- All tests use `@Test` with the description as a **backtick-escaped function name**
- The `@Test("...")` string argument form is **not used**
- The `@Test` attribute must appear on its own line directly above the `func` declaration — never inline on the same line
- The function name IS the test description — no separate string needed
- Test descriptions must describe **observable behavior**
- Test descriptions must not describe implementation details
- Test descriptions must not name the method under test
- Test descriptions must remain stable if implementation details change

### Form

```swift
// Correct:
@Test
func `Bonus stores the provided value`() {

// Incorrect — string argument form:
@Test("Bonus stores the provided value")
func storesValue() {

// Incorrect — @Test inline with func:
@Test func `Bonus stores the provided value`() {
```

A reader must understand what is being tested without reading the test body.

### Required Characteristics

A test description must answer:
- What is being exercised
- Under what condition
- What outcome is expected

### Prohibited Characteristics

- Naming the method under test
- Referring to private helpers
- Describing how the result is produced
- Encoding assumptions about implementation strategy

---

## Assertions and Behavioral Scope

- One test represents **one behavioral scenario**
- **Exactly one assertion per test** is the default
- Multiple assertions are allowed only when:
  - Splitting the test would significantly reduce clarity
  - The assertions are logically inseparable
  - The test still validates a single behavior

The following are not allowed:
- Multiple unrelated assertions
- Assertions validating different behaviors
- Assertions compensating for unclear test intent

---

## Assertion Style

The expression inside `#expect(...)` must read directly. It communicates the behavior under test, with no syntactic ceremony obscuring intent.

### Boolean Assertions

- Use the bare boolean: `#expect(value)` for true, `#expect(!value)` for false
- `#expect(value == true)` and `#expect(value == false)` are not allowed
- For `Optional<Bool>` (e.g. a JSON cast like `dict["key"] as? Bool`), unwrap with `try #require` first, then assert on the bare bool

```swift
// Correct:
#expect(response.success)
#expect(!response.success)

let success = try #require(object["success"] as? Bool)
#expect(success)

// Incorrect:
#expect(response.success == true)
#expect(response.success == false)
#expect(object["success"] as? Bool == true)
```

### Optional Assertions

- Optional chaining (`?.`) inside `#expect(...)` is not allowed
- Comparing an `Optional<T>` to a non-nil value of `T` is not allowed
- Unwrap optionals with `try #require` before the `#expect`, then assert on the unwrapped value
- Add `throws` to the test signature when introducing `try #require`

```swift
// Correct:
let data = try #require(response.data)
#expect(data.name == "session")

// Incorrect:
#expect(response.data?.name == "session")
#expect(request.params == ["a": "b"])  // request.params is Optional
```

### Allowed Exception

Pure presence checks remain as-is. They assert nil-ness, not the wrapped value:

- `#expect(x == nil)`
- `#expect(x != nil)`

These do not require `try #require`.

---

## Test Organization

Tests must be organized to clearly communicate behavioral intent.

### Primary Structure

- Behavioral groupings must be separated using **extensions**
- Each extension represents a distinct behavioral area or scenario set
- Extensions are the primary mechanism for organizing non-trivial test suites
- The primary test type declaration must not be empty
- The first behavioral group must live inside the primary test type declaration
- Extensions are used only for additional behavioral groups beyond the first
- A test file must not consist solely of extensions with an empty primary type

### Use of `// MARK:`

- `// MARK:` may be used **inside extensions** to further clarify intent
- `// MARK:` must not be used as a substitute for extensions when multiple behavioral groups exist
- Large monolithic test types organized only with `// MARK:` are not allowed

### Scope Rules

- A single test type without extensions is acceptable only for trivially small test suites
- Once multiple behavioral groupings are present, extensions are required
- Grouping optimizes for **readability and intent**, not parity with production code

---

## Arguments

Arguments may be used only when:

- The same behavior is validated across multiple inputs
- The test logic is identical except for input and expected output
- Arguments meaningfully reduce duplication

Arguments should be preferred when multiple tests would otherwise validate the
**same behavioral rule** across different input values.

Common cases include:
- Boundary conditions (e.g. meets vs exceeds a threshold)
- Equivalent valid inputs
- Multiple inputs producing the same observable outcome

Arguments must not be used when they:
- Obscure test intent
- Combine unrelated behaviors
- Replace clearly distinct behavioral scenarios

If arguments reduce clarity, they must not be used.

### Rules

- Arguments must not obscure intent
- Argument-driven tests must remain readable without inspecting the body
- Do not generalize unrelated behaviors into a single argument-driven test

If arguments reduce clarity, they must not be used.

### Decision Heuristic

Use this when deciding whether several tests should consolidate into a single parameterized test:

- If the test body asserts the **same rule** against each input, parameterize
- If the test body would require an `if` or `switch` on the parameter to decide what to assert, the tests exercise different rules — keep them separate
- If consolidation requires a shared construction step that varies in shape across cases, prefer separate tests; the duplication is documentation, not noise

The goal is one rule per parameterized test, evaluated against many inputs — not one test that branches on its inputs.

---

## Typed Inputs

Tests must construct their inputs through the type system. Raw strings, dictionaries-of-`Any`, byte arrays, and other untyped literals must not be scattered across test cases.

### Rule

- Inputs that pass through the type system unchanged are written in typed Swift directly
- Inputs that originate in an untyped form (e.g. serialized wire formats, command-line argument strings, URL queries, environment variables, raw bytes) must enter the test through a single private helper that accepts typed parameters and emits the untyped form
- Each test body operates entirely in typed Swift on either side of that helper

### Rationale

A scattered untyped literal in every test case obscures intent, multiplies the surface where format mistakes can hide, and makes refactors painful. A single typed boundary keeps the untyped format visible in one place and lets each test read as a typed scenario.

### Allowed Exception

When the test exists specifically to verify the literal untyped form — for example, a key being absent, a specific encoding shape, a contract pin against drift — the raw literal is the subject of the test, and the typed helper would defeat its purpose. In those cases the raw literal stays.

### Helper Placement

Untyped-boundary helpers follow the existing Local Helpers rules: scoped to the test type, defined in their own private extension, and not in the `// MARK: - SUT` section.

---

## Input Identity

When a test asserts that an input value is preserved by the SUT, the assertion must reference the same binding the SUT received — not a duplicate literal.

### Rule

- A value passed into `makeSUT` (or directly into the SUT) and later checked on the SUT must be held in a named local
- The assertion must reference that local
- Duplicating the literal across the setup and the assertion is not allowed

### Rationale

A duplicated literal turns a single assertion into two places that must stay in sync. If one drifts during a refactor — a stray edit to the setup literal that the assertion literal misses — the test still compiles, still runs, and silently asserts the wrong thing. A single named binding makes "what went in is what comes out" explicit and removes the drift surface.

### Allowed Exception

When the test exists specifically to verify a literal value — for example, a default, a documented constant, or a contract pin — the literal is the subject of the assertion and may appear directly.

---

## SUT and Dependency Binding

`makeSUT` returns the SUT alone, or a tuple of the SUT and the dependencies a test observes. Each test must bind only the elements it uses.

### Rule

- When a test uses only the SUT, bind it through the tuple accessor: `let sut = makeSUT().sut`
- When a test uses only a dependency, bind it the same way: `let delegate = makeSUT().delegate`
- When a test uses the SUT together with one or more dependencies, destructure them in a single binding: `let (sut, delegate) = makeSUT()`
- Discarding a tuple element with a `_` placeholder is not allowed

### Rationale

A `_` placeholder is noise — it signals "something is here that I am deliberately ignoring" in every test that doesn't need it. Binding only the elements a test actually uses keeps the top of each test an honest declaration of the scenario's surface: a reader sees exactly what is exercised and what is observed, with nothing discarded.

---

## Model Construction

Tests should prefer **factory methods** over direct model instantiation.

Factories exist to:
- Reduce setup noise in test cases
- Make test intent explicit through named parameters
- Provide safe, sensible defaults
- Allow selective override of only what matters for a given test

### Discovery Rules

Before constructing any data model in a test:

- The test must first check whether a factory method already exists
- Known factory locations (e.g. `TestFactory.swift` or equivalent test helpers) must be searched before using direct initialization
- The model must not assume a factory exists without verifying it

If a factory method exists, it must be used.

### Rules

- Models used in tests should be created via factory methods **when available**
- Direct initializer usage is discouraged
- Factories must provide defaults that represent valid, neutral state
- Factories must allow callers to override only the values relevant to the test

### Allowed Exceptions

Direct initialization is allowed only when:
- The initializer itself is the subject of the test, or
- No factory exists and introducing one would add unnecessary indirection

The absence of a factory does **not** justify guessing initializer behavior.

### Non-Guessing Requirement

When no factory exists:

- The model must inspect the data model directly
- Initializers, defaults, and invariants must be derived from the source, not inferred
- Constructor parameters must not be guessed or hallucinated
- If required information cannot be determined safely, the model must stop and ask

### Factory Responsibilities

Factories must not:
- Perform assertions
- Encode test expectations
- Rely on global or static mutable state
- Introduce hidden randomness or side effects
- Depend on test execution order

Factories must be:
- Deterministic
- Side-effect free
- Focused solely on constructing test data

### Local Helpers

Factories are intended to construct **general-purpose test data**.

Local helper methods may be introduced when:
- A specific behavioral scenario requires composition beyond a single factory call
- The helper expresses scenario intent rather than data shape
- The helper is used only within a single test file

Local helpers must:
- Be scoped to the test type
- Not replace or duplicate existing factory methods
- Not live in the `// MARK: - SUT` section

Factories should be extended only when:
- The construction pattern is broadly reusable
- The factory improves clarity across multiple test files

### Placement

Factories may live in:
- A dedicated test helper file
- A shared test support module

Factories must not:
- Be coupled to a specific test case
- Contain test logic
---

## Async and Concurrency

- Async tests are written only when the behavior requires it
- Actor isolation must not be guessed
- If the type under test is `@MainActor`, the test type must also be `@MainActor`
- Time-based waits are not allowed

---

## No Comments in Test Cases

### Absolute Rule

- **No comments inside test cases**

Test descriptions must carry the full explanatory burden.

If a test requires comments to understand, the test description is insufficient.

---

## Test Isolation

Each test must be **fully isolated**.

- Tests must not rely on execution order
- Tests must not share mutable state
- Tests must be independently runnable

All required setup must occur inside the test body or `makeSUT`.

---

## No Side Effects Between Tests

Tests must not:

- Mutate shared global state
- Depend on static state from previous tests
- Leave behind artifacts that affect subsequent tests

If side effects are unavoidable, they must be explicitly reset and scoped to the test only.

---

## Mocks, Stubs, and Test Doubles

- Test doubles model **behavior**, not interactions
- Call count assertions are not allowed
- Assertions must not exist inside test doubles

### State Rules

- All mutable state is `private`
- State observed by tests is `private(set)`
- Public mutable state is not allowed

### Structure Rules

- Test doubles are concrete types
- Test doubles live inside the test type
- Test doubles are not shared across files unless explicitly justified

---

## Prohibited Practices

The following are not allowed:

- Call count assertions
- Asserting incidental implementation details
- Public mutable state on test doubles
- Assertions inside mocks or helpers
- Commented-out or disabled tests
- Print statements
- Inline comments explaining test intent
- "Just in case" dependencies or configuration

---

## Authority

If any test, helper, or workflow conflicts with this document:

- This document wins
- The test must be rewritten

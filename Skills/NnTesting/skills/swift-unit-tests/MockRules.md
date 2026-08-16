# Mock and Test Double Rules

This document defines the canonical rules for mock construction, configuration, and state management in Swift unit test files.

All mocks created during setup must follow these rules. If anything conflicts with `StructuralReference.md`, `StructuralReference.md` wins.

---

## Construction

`makeSUT` is responsible for constructing **all mocks and test doubles**.

Tests must never construct mocks directly.

Mocks must:
- Be concrete types (`final class` or `struct`)
- Be instantiated inside `makeSUT`
- Be deterministic
- Default to a neutral baseline
- Expose only observable state via `private(set)`

Mocks must not:
- Perform assertions
- Encode test expectations
- Decide correctness
- Contain business logic
- Branch based on assumed test scenarios

Mocks exist to **record and expose observable behavior**, not to validate it.

---

## Mock Consolidation

When the SUT depends on multiple protocols, use **a single mock type** named **`MockDelegate`** that conforms to all required protocols.

Rules:
- A single mock **must** satisfy multiple protocol dependencies
- The mock **must** be named `MockDelegate`
- Creating one mock per protocol is **forbidden by default**

Multiple mocks are allowed **only when**:
- The mocks must be configured differently for the same test
- The mocks' observable state must be asserted independently
- A single mock would make test intent unclear

### Naming When Multiple Mocks Are Justified

When the exception applies and multiple mocks are required:

- Name each mock by its **role**, prefixed with `Mock`: e.g., `MockRepository`, `MockLogger`, `MockAuthProvider`
- The name must describe the collaborator's role, not the protocol it conforms to
- Do not use generic names like `Mock1`, `Mock2`, or `MockA`
- `MockDelegate` is reserved for the consolidated single-mock pattern

The consolidated mock represents **one testing collaborator**, regardless of protocol count.

---

## Property Modeling

Configuration properties:
- Provided at initialization or via `makeSUT` parameters
- Immutable (`let`), `private`
- Represent scenario setup, not expectations

Observable properties:
- Declared as `private(set)`
- Default to neutral values
- Exist solely for test assertions
- Must not be mutated directly by tests

---

## State Invariants

### Collection Properties
- Collection-based observable properties must **never** be optional
- Collections must default to an empty value
- Optional collections (`[T]?`, `Set<T>?`) are forbidden

### Scalar Properties
- May be optional **only when absence itself is meaningful**

### Default Cardinality Rule

Observable mock state must default to **single-invocation semantics**.

- Collection-based observable state is **forbidden by default**
- Defensive modeling ("it might be called more than once") is not allowed

A collection may be used **only when**:
- Multiple invocations are intentional
- Tests assert on multiplicity, order, or accumulation
- Single-value modeling would lose meaningful information

### Initialization
- Empty collections for collection types
- `false` for booleans
- `nil` only when semantically meaningful
- Mocks must never rely on tests to "initialize" observable state

---

## Error Handling

Mocks may simulate errors **only when the real dependency can throw**.

When a mocked protocol includes `throws` requirements, error simulation support is **mandatory**:
- Every mock must include a `throwError: Bool` configuration property (default `false`)
- Error behavior must be deterministic, controlled only via initialization or `makeSUT` parameters
- A single flag controls all throwing methods uniformly

Prohibited:
- Per-method error switches
- Call-order-dependent error behavior
- Internal error state toggling

---

## Configuration Boundary

- Configuration must be expressed as parameters on `makeSUT`
- Tests must not mutate mocks directly
- Parameters model scenario-level differences, not mock internals

---

## Placement and Sharing

By default, mocks must:
- Live inside the test file
- Be scoped via a private extension
- Not be shared across test files

A mock may be shared **only when**:
- Multiple test files require the same mock
- The mock already exists in a shared test support module
- Duplication would introduce divergence

Shared mocks follow the same constraints as file-local mocks.

Mocks must not be shared speculatively or when tightly coupled to a single SUT.

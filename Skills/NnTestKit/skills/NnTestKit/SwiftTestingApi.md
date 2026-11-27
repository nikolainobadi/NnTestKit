# Swift Testing API

Memory leak tracking via `@LeakTracked` macro plus Combine and Observation helpers for Swift's Testing framework.

Libraries: `NnSwiftTestingHelpers`, `NnTestKitMacros`

## Import Guide

| Type / Symbol | Import |
|---------------|--------|
| `@LeakTracked`, `trackForMemoryLeaks` (Swift Testing) | `import NnSwiftTestingHelpers` |
| `TrackableObject` | `import NnSwiftTestingHelpers` |
| `Published.Publisher.waitUntil(timeout:condition:)` | `import NnSwiftTestingHelpers` |
| `observationStream(of:)`, `AsyncStream.waitUntil`, `expectObservationFires` | `import NnSwiftTestingHelpers` |

---

## Macro: @LeakTracked

Attached member macro that injects memory leak tracking into a test class without requiring inheritance.

```swift
@attached(member, names: named(trackForMemoryLeaks), arbitrary)
public macro LeakTracked() = #externalMacro(module: "NnTestKitMacros", type: "LeakTrackedMacro")
```

### Generated Members

When `@LeakTracked` is applied to a class, it generates:

| Member | Visibility | Description |
|--------|------------|-------------|
| `_NnLeakBehavior` | `public enum` | Three leak detection behaviors: `.failIfLeaked`, `.warnIfLeaked`, `.expectLeak` |
| `_nn_lock` | `private var` | `NSLock` for thread-safe access to tracked objects |
| `_nn_tracked` | `private var` | Array of `(object: TrackableObject, behavior: _NnLeakBehavior)` tuples |
| `trackForMemoryLeaks(_:behavior:fileID:filePath:line:column:)` | `public func` | Registers an object for leak checking. Returns `TrackableObject` (`@discardableResult`) |
| `deinit` | — | Iterates tracked objects and asserts based on behavior |

### _NnLeakBehavior Cases

| Case | Behavior at `deinit` |
|------|---------------------|
| `.failIfLeaked` (default) | `#expect(weakRef == nil)` — test fails if object still alive |
| `.warnIfLeaked` | `withKnownIssue { #expect(...) }` — logs warning, does not fail |
| `.expectLeak` | `#expect(weakRef != nil)` — test fails if object was deallocated |

### Usage Example

```swift
import Testing
@testable import YourModule

@LeakTracked
final class MyFeatureTests {
    @Test("Object is properly deallocated")
    func deallocation() {
        let sut = makeSUT()
        // sut goes out of scope -> trackForMemoryLeaks checks at deinit
    }

    @Test("Known leak is expected")
    func knownLeak() {
        let sut = makeSUT()
        sut.createRetainCycle()
        trackForMemoryLeaks(sut, behavior: .expectLeak)
    }

    private func makeSUT(
        fileID: String = #fileID,
        filePath: String = #filePath,
        line: Int = #line,
        column: Int = #column
    ) -> MyClass {
        let sut = MyClass()
        trackForMemoryLeaks(sut, fileID: fileID, filePath: filePath, line: line, column: column)
        return sut
    }
}
```

### Cross-Actor Safety

```swift
@LeakTracked
final class CrossActorTests {
    @Test("Background actor tracking is safe")
    func backgroundCall() async {
        let t = Task { [self] in
            let sut = LeakFreeSUT()
            self.trackForMemoryLeaks(sut)
        }
        await t.value
    }

    @Test("Main actor tracking is safe")
    func mainActorCall() async {
        let sut = LeakFreeSUT()
        _ = await MainActor.run { [self] in
            self.trackForMemoryLeaks(sut)
        }
    }
}
```

### Behavioral Notes

- **Thread safety**: `_nn_lock` (NSLock) synchronizes all access to `_nn_tracked`. Safe to call `trackForMemoryLeaks` from background actors.
- **Deinit checking**: Copies `_nn_tracked` under lock, then iterates without the lock. Safe because no mutation can occur during `deinit`.
- **Source location**: Uses Swift Testing's `SourceLocation(fileID:filePath:line:column:)` — 4 parameters, not the XCTest 2-parameter pattern.
- **Must be a class**: `@LeakTracked` generates `deinit`, which requires a class (not struct).
- **`.warnIfLeaked` mechanics**: Only enters `withKnownIssue` when a leak is detected — the inner `#expect` always evaluates to false when reached.

### Memory Leak Tracking: XCTest vs. @LeakTracked

| Dimension | `XCTestCase.trackForMemoryLeaks` | `@LeakTracked` macro |
|---|---|---|
| Framework | XCTest | Swift Testing |
| Behavior modes | `.failIfLeaked` only | `.failIfLeaked`, `.warnIfLeaked`, `.expectLeak` |
| When checked | XCTest teardown block | Class `deinit` |
| Assertion style | `XCTAssertNil` | `#expect` |
| Stdout side effect | Prints "checking for..." always | None |
| Return value | None | `@discardableResult TrackableObject` |
| Thread safety | No lock | NSLock-synchronized |
| Source location | `file: StaticString, line: UInt` | `fileID, filePath, line, column` |

**Decision**: Use `@LeakTracked` for all new Swift Testing suites. Use `trackForMemoryLeaks` only in `XCTestCase` subclasses.

---

## Class: TrackableObject

Holds a weak reference to a tracked object for memory leak detection.

```swift
public final class TrackableObject: @unchecked Sendable {
    public weak var weakRef: AnyObject?
    public let errorMessage: String
    public let sourceLocation: SourceLocation

    public init(weakRef: AnyObject, sourceLocation: SourceLocation)
}
```

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `weakRef` | `AnyObject?` (weak) | Weak reference to the tracked object; non-nil at teardown indicates a leak |
| `errorMessage` | `String` | Pre-formatted message: `"<description> should have been deallocated. Potential memory leak"` |
| `sourceLocation` | `SourceLocation` | `Testing.SourceLocation` captured at the call site |

### Initialization

| Initializer | Description |
|-------------|-------------|
| `init(weakRef: AnyObject, sourceLocation: SourceLocation)` | Creates a trackable object with a weak reference and source location |

### Behavioral Notes

- `errorMessage` is generated at construction time using `String(describing: weakRef)` — captures the object's description while still alive.
- Consumers typically don't create `TrackableObject` directly — it's returned by the generated `trackForMemoryLeaks` method.

---

## Extension: Published.Publisher (Equatable & Sendable)

Combine publisher waiting helper for Swift Testing async contexts.

```swift
@MainActor
public extension Published.Publisher where Output: Equatable & Sendable {
    enum PublisherError: Error {
        case timeout
    }

    func waitUntil(timeout: Double = 1, condition: @escaping (Output) -> Bool) async throws
}
```

### Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `waitUntil(timeout:condition:)` | `Void` | Waits for a publisher to emit a value matching the condition |

### Enum: PublisherError

| Case | Description |
|------|-------------|
| `.timeout` | Condition was not met within the timeout period |

### Usage Example

```swift
@Test("Items load successfully")
@MainActor
func itemsLoad() async throws {
    let viewModel = ItemsViewModel()
    viewModel.loadItems()
    try await viewModel.$items.waitUntil { $0.count == 3 }
}
```

### Publisher Waiting: waitForCondition vs. waitUntil

| Dimension | `XCTestCase.waitForCondition` | `Published.Publisher.waitUntil` |
|---|---|---|
| Framework | XCTest | Swift Testing / any async context |
| Blocking style | Synchronous `XCTWaiter.wait` | `async throws` |
| Inverted mode | Yes (`shouldFailIfConditionIsMet`) | No |
| Publisher scope | Any `Publisher` | `Published.Publisher` only |
| Actor restriction | None | `@MainActor` only |
| Default timeout | 3 seconds | 1 second |
| Cancellable management | Stores in caller's `Set<AnyCancellable>` | Internal tasks, not externally cancellable |
| Failure style | `XCTFail` inline | Throws `PublisherError.timeout` |

**Decision**: Use `waitUntil` in `@MainActor` Swift Testing tests observing `@Published` properties. Use `waitForCondition` in XCTest with any `Publisher` type. For `@Observable` properties, see the Observation helpers below.

### Behavioral Notes

- **@MainActor required**: The entire extension is `@MainActor`-annotated.
- **Double-resume guard**: Internal `didResume` boolean prevents continuation from being resumed twice.
- **Publisher completion**: If the publisher completes before the condition is met, throws `CancellationError` (not `PublisherError.timeout`).
- **Observation task is fire-and-forget**: The value-observing `Task` is not stored and cannot be cancelled externally. It continues running until the publisher completes or is deallocated.
- **Constrained to `Equatable & Sendable`**: The `Output` type must conform to both protocols.

---

## Helpers: Observation (`@Observable`)

Async helpers for testing `@Observable` change propagation. Built on `withObservationTracking` with self-re-registering callbacks so callers get a continuous stream of values instead of a single-shot observer.

**Availability:** `@available(macOS 14, iOS 17, tvOS 17, watchOS 10, *)` — required by the Observation framework.

```swift
@MainActor
public func observationStream<T: Sendable>(
    of read: @escaping @MainActor () -> T
) -> AsyncStream<T>

public extension AsyncStream where Element: Sendable {
    enum WaitError: Error { case timeout }

    func waitUntil(
        timeout: Double = 1,
        condition: @escaping (Element) -> Bool
    ) async throws
}

@MainActor
public func expectObservationFires<T: Sendable>(
    when trigger: () async throws -> Void,
    afterReading read: @autoclosure @escaping @MainActor () -> T,
    timeout: Double = 1,
    sourceLocation: SourceLocation = #_sourceLocation
) async rethrows
```

### Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `observationStream(of:)` | `AsyncStream<T>` | Bridges an `@Observable` property to a continuous async stream of post-change values |
| `AsyncStream.waitUntil(timeout:condition:)` | `Void` | Waits for the stream to yield a value matching the condition, or throws `WaitError.timeout` |
| `expectObservationFires(when:afterReading:timeout:sourceLocation:)` | `Void` | One-shot assertion: after `trigger` runs, at least one observation must fire within `timeout` |

### Enum: AsyncStream.WaitError

| Case | Description |
|------|-------------|
| `.timeout` | Condition was not satisfied within the timeout period |

### Usage: expectObservationFires

```swift
@Test("Wrapper preserves observation propagation")
@MainActor
func wrapperFiresObservation() async {
    let source = CounterModel()
    let wrapper = CounterWrapper(source: source)

    await expectObservationFires(when: {
        source.count += 1
    }, afterReading: wrapper.count)
}
```

### Usage: observationStream + waitUntil

```swift
@Test("Items load via @Observable view model")
@MainActor
func itemsLoad() async throws {
    let viewModel = ItemsViewModel()
    let stream = observationStream(of: { viewModel.items })

    viewModel.loadItems()
    try await stream.waitUntil { $0.count == 3 }
}
```

### Observation Waiting: waitUntil (Combine) vs. observationStream + waitUntil

| Dimension | `Published.Publisher.waitUntil` | `observationStream(of:).waitUntil` |
|---|---|---|
| Source | `@Published` property (Combine) | `@Observable` property (Observation framework) |
| Platforms | iOS 13+ / macOS 10.15+ | iOS 17+ / macOS 14+ |
| Output constraint | `Equatable & Sendable` | `Sendable` (no `Equatable` needed) |
| Actor restriction | `@MainActor` only | `@MainActor` on the read closure |
| Initial value | Receives current value on subscribe | Yields **only on changes** (no initial value) |
| Default timeout | 1 second | 1 second |
| Failure style | Throws `PublisherError.timeout` | Throws `WaitError.timeout` |

**Decision**: Use the Combine helper for `@Published`. Use `observationStream` for `@Observable`. Use `expectObservationFires` when you only need to assert "a change reached this read" without caring about the value.

### Behavioral Notes — Observation

- **Self-re-registering tracking**: `withObservationTracking`'s `onChange` is single-shot. `observationStream` works around this by dispatching a `@MainActor` task that yields the new value and re-registers tracking. This means rapid successive mutations may **coalesce into a single yield** with the latest value.
- **No initial value**: `observationStream` does not emit the current value on subscribe. If your predicate already holds before subscription, `waitUntil` will still wait for the next change. Mutate *after* taking the stream.
- **Synchronous registration**: `observationStream` registers tracking synchronously before returning, so triggering a mutation immediately after the call is safe.
- **Continuation termination**: When the stream's consumer finishes iterating, the next `onChange` callback detects `.terminated` from `continuation.yield(...)` and stops re-registering.
- **expectObservationFires uses `try?`**: Timeouts are converted into a failing `#expect` with the source location, not a thrown error. The function's `rethrows` only propagates errors from the caller-supplied `trigger`.
- **AsyncStream.waitUntil is generic**: The extension is public on any `AsyncStream where Element: Sendable`, not scoped to Observation usage. Useful with any custom stream.

---

## Best Practices

- **Use `@LeakTracked` on a `final class`, not a struct** — The macro generates `deinit`, which requires reference type semantics.
- **Forward all 4 source location parameters** — `makeSUT` factories should accept `fileID`, `filePath`, `line`, `column` with `#fileID`, `#filePath`, `#line`, `#column` defaults.
- **Use `.warnIfLeaked` for known issues** — When a leak exists but isn't fixable yet, `.warnIfLeaked` logs without failing.
- **Use `.expectLeak` for intentional retain cycles** — Test that a deliberate retain cycle (e.g., delegate pattern) behaves as expected.
- **`waitUntil` default timeout is 1s** — Much shorter than `waitForCondition`'s 3s default. Increase for slow operations.
- **`waitUntil` requires `@MainActor` test context** — Annotate the test method or struct with `@MainActor`.
- **Take the observation stream before mutating** — `observationStream` yields only post-change values. Set up the stream first, then call the trigger that mutates the `@Observable`.
- **Prefer `expectObservationFires` for "did it fire?" checks** — Use the lower-level `observationStream` + `waitUntil` pair only when you need to assert on the actual value reached.

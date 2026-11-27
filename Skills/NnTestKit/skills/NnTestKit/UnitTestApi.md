# Unit Test API

XCTest extensions for memory leak tracking, property/array/error assertions, Combine publisher testing, async waiting, and test environment detection.

Libraries: `NnTestHelpers`, `NnTestVariables`

## Import Guide

| Type / Symbol | Import |
|---------------|--------|
| `IS_TRUE`, `IS_UI_TESTING` | `import NnTestVariables` |
| `ProcessInfo.isTesting`, `.isUITesting`, `.containsKey(_:)` | `import NnTestVariables` |
| `trackForMemoryLeaks`, `assertProperty`, `assertArray`, `assertThrownError` | `import NnTestHelpers` |
| `waitForCondition`, `waitForAsyncMethod`, `StubErrorType` | `import NnTestHelpers` |
| `Date.from(year:month:day:)`, `Date.asDatePickerString()` | `import NnTestHelpers` |

---

## Constants

```swift
public let IS_TRUE = "IS_TRUE"
public let IS_UI_TESTING = "IS_UI_TESTING"
```

String constants used for environment variable-based test detection. `BaseUITestCase` sets `IS_UI_TESTING = IS_TRUE` in the app's launch environment automatically.

---

## Extension: ProcessInfo

Test environment detection via process environment and Objective-C runtime introspection.

```swift
public extension ProcessInfo {
    static var isTesting: Bool { get }
    static var isUITesting: Bool { get }
    static func containsKey(_ key: String) -> Bool
}
```

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `isTesting` | `Bool` | Returns `true` if `isUITesting` is true OR `XCTestCase` class exists at runtime |
| `isUITesting` | `Bool` | Returns `true` if `environment[IS_UI_TESTING] == IS_TRUE` |

### Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `containsKey(_ key: String)` | `Bool` | Returns `true` if `environment[key] == IS_TRUE` |

### Usage Example

```swift
// In production code — conditionally skip behavior during tests
if !ProcessInfo.isTesting {
    analytics.track(event)
}

// Check custom environment flags set via addKeyToENV
if ProcessInfo.containsKey("SKIP_ONBOARDING") {
    showMainScreen()
}
```

### Behavioral Notes

- `isTesting` uses `NSClassFromString("XCTestCase")` — returns `true` in both unit test and UI test environments.
- `containsKey` requires the value to be exactly `"IS_TRUE"`, not just the key's presence.
- `NnTestVariables` can be imported in production targets (no XCTest dependency).

---

## Extension: Date

Test-specific date construction and formatting helpers.

```swift
public extension Date {
    static func from(year: Int, month: Int, day: Int, hour: Int = 8, minute: Int = 0) -> Date
    func asDatePickerString() -> String
}
```

### Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `from(year:month:day:hour:minute:)` | `Date` | Constructs a Date from components using Gregorian calendar |
| `asDatePickerString()` | `String` | Formats date as `"MMM d, yyyy"` (e.g., `"Jan 1, 2024"`) |

### Usage Example

```swift
let testDate = Date.from(year: 2024, month: 3, day: 15)
let formatted = testDate.asDatePickerString() // "Mar 15, 2024"
```

### Behavioral Notes

- `from(year:month:day:)` force-unwraps the result — invalid components (e.g., month 13) cause a crash.
- Default `hour` is 8, `minute` is 0.
- `asDatePickerString()` creates a new `DateFormatter` on every call. Format is locale-independent (English abbreviated month).
- The `"MMM d, yyyy"` format matches what `assertDateInPicker` expects — these are paired.

---

## Enum: StubErrorType

```swift
public enum StubErrorType: Error {
    case genericError
}
```

Sentinel error type used as the default parameter in `assertThrownError` and `asyncAssertThrownError`. When detected at runtime, it changes the assertion behavior to "any error is unexpected" rather than "match this specific error."

---

## Extension: XCTestCase — Async Waiting

```swift
public extension XCTestCase {
    func waitForAsyncMethodInNanoseconds(_ nanoseconds: UInt64 = 0_100_000_000) async throws
    func waitForAsyncMethod(seconds: Double = 0.1) async throws
}
```

### Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `waitForAsyncMethodInNanoseconds(_:)` | `Void` | Sleeps for specified nanoseconds (default 0.1s) |
| `waitForAsyncMethod(seconds:)` | `Void` | Sleeps for specified seconds (default 0.1s) |

### Behavioral Notes

- `waitForAsyncMethod` delegates to `waitForAsyncMethodInNanoseconds` after converting seconds to nanoseconds.
- Negative `seconds` values produce a very large `UInt64` due to unsigned wrapping — no validation is performed.
- `CancellationError` propagates if the enclosing `Task` is cancelled during sleep.

---

## Extension: XCTestCase — Memory Leak Tracking

```swift
public extension XCTestCase {
    func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line)
}
```

### Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `trackForMemoryLeaks(_:file:line:)` | `Void` | Registers a teardown block that asserts the instance was deallocated |

### Usage Example

```swift
func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> MyClass {
    let sut = MyClass()
    trackForMemoryLeaks(sut, file: file, line: line)
    return sut
}
```

### Behavioral Notes

- Registers an `addTeardownBlock` that captures `instance` as `[weak instance]`.
- Prints `"checking for <description>"` to stdout on every teardown, even when no leak exists.
- Failure is reported at the original call site's `file`/`line`, not the teardown location.
- Only supports "fail if leaked" behavior. For `.warnIfLeaked` or `.expectLeak`, use `@LeakTracked` macro instead.

---

## Extension: XCTestCase — Publisher Testing

```swift
public extension XCTestCase {
    func waitForCondition<P: Publisher>(
        publisher: P,
        description: String = "waiting for publisher",
        shouldFailIfConditionIsMet: Bool = false,
        cancellables: inout Set<AnyCancellable>,
        timeout: TimeInterval = 3,
        condition: @escaping (P.Output) -> Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    )
}
```

### Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `waitForCondition(publisher:description:shouldFailIfConditionIsMet:cancellables:timeout:condition:file:line:)` | `Void` | Subscribes to a publisher and waits for a condition to be met |

### Parameters: waitForCondition

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `publisher` | `P: Publisher` | required | The publisher to subscribe to |
| `description` | `String` | `"waiting for publisher"` | Description for the expectation |
| `shouldFailIfConditionIsMet` | `Bool` | `false` | If `true`, fails when condition is fulfilled (inverted expectation) |
| `cancellables` | `inout Set<AnyCancellable>` | required | Storage for the subscription |
| `timeout` | `TimeInterval` | `3` | Time to wait before failing |
| `condition` | `(P.Output) -> Bool` | required | Closure that returns `true` when condition is met |

### Usage Example

```swift
var cancellables = Set<AnyCancellable>()

// Assert a publisher emits a specific value
waitForCondition(
    publisher: viewModel.$items,
    cancellables: &cancellables,
    condition: { $0.count == 3 }
)

// Assert a publisher does NOT emit a value (inverted)
waitForCondition(
    publisher: viewModel.$error,
    shouldFailIfConditionIsMet: true,
    cancellables: &cancellables,
    condition: { $0 != nil }
)
```

### Behavioral Notes

- Uses `XCTWaiter().wait(for:timeout:)` — synchronous blocking wait. Default timeout is 3 seconds.
- Subscription is stored in the caller's `cancellables` set and persists after the call.
- Publisher `.failure` completion triggers `XCTFail` on the publisher's delivery thread.
- The `evaluateWaitResult` helper maps all `XCTWaiter.Result` cases to descriptive failure messages.
- Note: there is a typo in the timeout failure message: `"timout should not occur..."`.

---

## Extension: XCTestCase — Assertions

```swift
public extension XCTestCase {
    func assertProperty<T>(_ property: T?, name: String? = nil, assertion: ((T) -> Void)? = nil, ...)
    func assertPropertyEquality<T: Equatable>(_ property: T?, name: String? = nil, expectedProperty: T, ...)
    func assertArray<T: Equatable>(_ array: [T], contains items: [T], ...)
    func assertArray<T: Equatable>(_ array: [T], doesNotContain items: [T], ...)
    func assertIdentifiableArray<T: Identifiable>(_ array: [T], contains items: [T], ...)
    func assertIdentifiableArray<T: Identifiable>(_ array: [T], doesNotContain items: [T], ...)
    func assertNoErrorThrown(action: @escaping () throws -> Void, _ message: String? = nil, ...)
    func asyncAssertNoErrorThrown(action: @escaping () async throws -> Void, _ message: String? = nil, ...) async
    func assertThrownError<ErrorType: Error & Equatable>(expectedError: ErrorType = StubErrorType.genericError, action: @escaping () throws -> Void, ...)
    func asyncAssertThrownError<ErrorType: Error & Equatable>(expectedError: ErrorType = StubErrorType.genericError, action: @escaping () async throws -> Void, ...) async
    func handleError<ErrorType: Error & Equatable>(_ error: Error, expectedError: ErrorType, ...)
}
```

### Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `assertProperty(_:name:assertion:)` | `Void` | Unwraps optional, runs assertion closure if non-nil |
| `assertPropertyEquality(_:name:expectedProperty:)` | `Void` | Unwraps optional and asserts equality |
| `assertArray(_:contains:)` | `Void` | Asserts array contains all specified items |
| `assertArray(_:doesNotContain:)` | `Void` | Asserts array does not contain any specified items |
| `assertIdentifiableArray(_:contains:)` | `Void` | Asserts array contains items by `.id` equality |
| `assertIdentifiableArray(_:doesNotContain:)` | `Void` | Asserts array does not contain items by `.id` |
| `assertNoErrorThrown(action:)` | `Void` | Asserts synchronous action does not throw |
| `asyncAssertNoErrorThrown(action:)` | `Void` | Asserts async action does not throw |
| `assertThrownError(expectedError:action:)` | `Void` | Asserts action throws a specific error |
| `asyncAssertThrownError(expectedError:action:)` | `Void` | Asserts async action throws a specific error |
| `handleError(_:expectedError:)` | `Void` | Type-casts and asserts error equality |

### Usage Example

```swift
// Optional unwrapping with assertion
assertProperty(viewModel.selectedItem, name: "selectedItem") { item in
    XCTAssertEqual(item.name, "Expected")
}

// Equality check
assertPropertyEquality(viewModel.title, expectedProperty: "Welcome")

// Array assertions
assertArray(viewModel.items, contains: [item1, item2])
assertArray(viewModel.deletedItems, doesNotContain: [activeItem])

// Error assertions
assertThrownError(expectedError: MyError.notFound) {
    try sut.loadItem(id: "invalid")
}

await asyncAssertThrownError(expectedError: NetworkError.timeout) {
    try await sut.fetchData()
}
```

### Assertion Error Checking Guide

| Need | Use |
|:-----|:----|
| Assert nothing throws | `assertNoErrorThrown(action:)` or `asyncAssertNoErrorThrown(action:)` |
| Assert a specific error is thrown | `assertThrownError(expectedError: MyError.specific, action:)` |
| Assert any error is thrown (no type check) | Not directly supported — use `do/catch` with `XCTFail` in the `do` block |

### Behavioral Notes

- `assertProperty` with no `assertion` closure acts as a nil-check only.
- `assertArray` and `assertIdentifiableArray` check every item (no early exit) — each missing item is a separate failure.
- `assertIdentifiableArray` compares by `.id`, not value equality.
- `assertThrownError` with default `StubErrorType.genericError` treats any caught error as unexpected (calls `XCTFail`). You must provide a real `expectedError` to match a specific error type.
- `handleError` casts via `as? ErrorType` — if the thrown error is a different type, fails with "unexpected error".

---

## Best Practices

- **Memory leak tracking in every `makeSUT`** — Always pair object creation with `trackForMemoryLeaks` using forwarded `file`/`line` parameters so failures point to the test, not the factory.
- **Use `@LeakTracked` for new tests** — The XCTest `trackForMemoryLeaks` only supports fail-on-leak. For warn or expect-leak behaviors, use the `@LeakTracked` macro in Swift Testing.
- **Forward `file`/`line` in test helpers** — Any helper that calls assertion methods should accept `file: StaticString = #filePath, line: UInt = #line` and pass them through.
- **`assertThrownError` requires a real error type** — The default `StubErrorType.genericError` parameter is a sentinel that inverts behavior. Always pass your expected error explicitly.
- **`waitForCondition` timeout defaults to 3s** — For fast-expected conditions, pass a shorter timeout. The subscription persists in `cancellables` after the call.
- **`ProcessInfo.isTesting` detects both unit and UI tests** — Use `ProcessInfo.isUITesting` if you need to distinguish between them.

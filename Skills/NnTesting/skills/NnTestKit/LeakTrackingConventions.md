# Leak Tracking Conventions (NnTestKit)

How the leak-tracking rules in the **nn-testing** plugin's `swift-unit-tests` skill (`StructuralReference.md`, section 6) apply when the test target uses NnTestKit.

The general rules live there and are not repeated here: use a `final class` test type only when leak tracking is required, track inside `makeSUT` and never in test cases, and make the call-site parameters the last `makeSUT` parameters, forwarded unchanged. This file adds only what is specific to NnTestKit.

For the full API (behaviors, `TrackableObject`, cross-actor safety), see `SwiftTestingApi.md`.

---

## Rules

When memory leak tracking is required in a Swift Testing suite:

- `import NnSwiftTestingHelpers` must be added
- The test type must be annotated with `@LeakTracked`

### Required `makeSUT` Parameters

- `fileID: String = #fileID`
- `filePath: String = #filePath`
- `line: Int = #line`
- `column: Int = #column`

### Required Call Form

- `trackForMemoryLeaks(sut, fileID: fileID, filePath: filePath, line: line, column: column)`

### Forbidden

- Calling `trackForMemoryLeaks(sut)` without forwarding call-site parameters

---

## Example: Reference-Type SUT With Leak Tracking

```swift
import Testing
import NnSwiftTestingHelpers
@testable import MyFeatureKit

@LeakTracked
final class FeatureTests {
}


// MARK: - SUT
private extension FeatureTests {
    func makeSUT(
        fileID: String = #fileID,
        filePath: String = #filePath,
        line: Int = #line,
        column: Int = #column
    ) -> (sut: Feature, delegate: MockDelegate) {
        let delegate = MockDelegate()
        let sut = Feature(delegate: delegate)

        trackForMemoryLeaks(
            sut,
            fileID: fileID,
            filePath: filePath,
            line: line,
            column: column
        )

        return (sut, delegate)
    }
}
```

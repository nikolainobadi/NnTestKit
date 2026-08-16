# makeSUT Examples

This document provides **canonical examples** of `makeSUT` usage patterns.
All examples conform to the rules defined in `StructuralReference.md`.

These examples are instructional only and are not meant to be copied verbatim.
They illustrate **why** a given `makeSUT` shape is correct and **when** each pattern applies.

---

## Example 1: Simple SUT With No Dependencies

```swift
private extension FeatureTests {
    func makeSUT() -> Feature {
        return Feature()
    }
}
```

---

## Example 2: Utility Enum With Static Behavior

```swift
private extension MathUtilitiesTests {
    func makeSUT() -> MathUtilities.Type {
        return MathUtilities.self
    }
}
```

---

## Example 3: Single Dependency Returned for Validation

```swift
private extension FeatureTests {
    func makeSUT(isEnabled: Bool = true) -> (sut: Feature, delegate: MockDelegate) {
        let delegate = MockDelegate(isEnabled: isEnabled)
        let sut = Feature(delegate: delegate)
        return (sut, delegate)
    }
}
```

---

## Example 4: Multiple Dependencies Created, Only Some Returned

```swift
private extension FeatureTests {
    func makeSUT(
        isEnabled: Bool = true,
        cachedValue: String? = nil
    ) -> (sut: Feature, delegate: MockDelegate) {
        let cache = MockCache(value: cachedValue)
        let logger = MockLogger()
        let delegate = MockDelegate(isEnabled: isEnabled)

        let sut = Feature(
            cache: cache,
            logger: logger,
            delegate: delegate
        )

        return (sut, delegate)
    }
}
```

---

## Example 5: Scenario Modeling With Parameters

```swift
private extension FeatureTests {
    func makeSUT(
        hasAccess: Bool = true,
        errorOnSave: Bool = false
    ) -> (sut: Feature, repository: MockRepository) {
        let repository = MockRepository(
            hasAccess: hasAccess,
            errorOnSave: errorOnSave
        )

        let sut = Feature(repository: repository)
        return (sut, repository)
    }
}
```

---

## Example 6: Reference-Type SUT With Leak Tracking

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

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
        let store = InMemoryStore(value: cachedValue)
        let delegate = MockDelegate(isEnabled: isEnabled)

        let sut = Feature(
            store: store,
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

A leak-tracking `makeSUT` depends on the leak-tracking library, so its example lives with that library. See the **Leak-Tracking Library** section of this skill's `SKILL.md`.

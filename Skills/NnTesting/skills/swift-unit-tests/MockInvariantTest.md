# Mock Invariant Test Example

This is the **only test** the setup workflow is permitted to generate.
It validates mock baseline correctness, not SUT behavior.

For full rules, see `StructuralReference.md` section 5.

---

## Basic Example

```swift
@Test
func `Starting values are empty`() {
    let (_, delegate) = makeSUT()

    #expect(delegate.savedPresets.isEmpty)
}
```

---

## Multiple Baseline Assertions

When multiple mocks or multiple observable properties exist, a single test may include multiple assertions — all must validate baseline state only.

```swift
@Test
func `Starting values are empty`() {
    let (_, delegate, cache) = makeSUT()

    #expect(delegate.savedPresets.isEmpty)
    #expect(delegate.didSave == false)
    #expect(cache.cachedValues.isEmpty)
}
```

---

## Authority

This file is **illustrative only**. If it conflicts with `StructuralReference.md`, `StructuralReference.md` wins.

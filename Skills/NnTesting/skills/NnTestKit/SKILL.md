---
name: NnTestKit
description: NnTestKit Swift API reference for iOS/macOS testing utilities. USE WHEN writing XCTest tests, Swift Testing tests, UI tests, memory leak tracking, publisher testing, Observable testing, test assertions, @LeakTracked macro, BaseUITestCase, trackForMemoryLeaks, expectObservationFires, observationStream, UI test seeding, launchSeeded.
user-invocable: true
---

# NnTestKit

Testing utilities for iOS/macOS projects — XCTest extensions, Swift Testing helpers with @LeakTracked macro, UI test base class, and UI test seeding infrastructure.

**Dependency:** `https://github.com/nikolainobadi/NnTestKit.git` (2.2.0)
**Platforms:** iOS 17+, macOS 13+ | **Swift:** 5.10
<!-- package_path: . --> <!-- this skill lives inside the NnTestKit repo it documents -->

## Context Files

| File | Purpose | Load When |
|------|---------|-----------|
| `UnitTestApi.md` | XCTest extensions — memory leak tracking, assertions, publisher testing, test environment detection | Writing XCTest unit tests |
| `SwiftTestingApi.md` | @LeakTracked macro, TrackableObject, Combine + Observation helpers for Swift Testing | Writing Swift Testing tests |
| `UITestApi.md` | BaseUITestCase — element waiting/interaction, buttons, text input, date pickers, assertions, seeding helpers | Writing UI tests |

## Quick Reference

- **Memory leak tracking**: `trackForMemoryLeaks()` (XCTest) or `@LeakTracked` macro (Swift Testing, recommended)
- **Assertions**: `assertProperty`, `assertPropertyEquality`, `assertArray`, `assertThrownError` + async variants
- **Publisher testing**: `waitForCondition` (XCTest, any Publisher) or `waitUntil` (Swift Testing, @Published only)
- **Observation testing**: `observationStream(of:)` + `AsyncStream.waitUntil`, or `expectObservationFires` (Swift Testing, @Observable, iOS 17+ / macOS 14+)
- **UI test base**: `BaseUITestCase` — element waiting, button tapping, text input, date picker (incl. `selectTime` for `.hourAndMinute`), stepper, toggle helpers
- **UI test seeding**: `launchSeeded(config:)`, `setSeedConfig(_:)`, `UITestSeedContext<Config>`, `mainUserEmail`, `dismissPasswordPromptIfNeeded()`
- **Configurable timeouts**: `UITestSeedDefaults.timeout` (default 10s) is the global fallback for all UI helper `timeout:` parameters
- **Test environment**: `ProcessInfo.isTesting`, `ProcessInfo.isUITesting`, `addKeyToENV`

## Examples

- "How do I track memory leaks in my XCTest?" -> Loads `UnitTestApi.md`
- "Set up a Swift Testing suite with leak tracking" -> Loads `SwiftTestingApi.md`
- "Write a UI test that taps a button and verifies text" -> Loads `UITestApi.md`
- "Seed a UI test with a typed config and a unique test user" -> Loads `UITestApi.md`

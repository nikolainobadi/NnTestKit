# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

NnTestKit is a Swift package providing testing utilities for iOS/macOS projects. It consists of four libraries plus an internal macro target:
- **NnTestHelpers**: Main testing utilities extending XCTest (memory leak tracking, assertions, async helpers)
- **NnUITestHelpers**: XCUITest base class and helpers (element waiting, date pickers, alerts, seeding)
- **NnTestVariables**: Lightweight library with test-related properties (can be included in production)
- **NnSwiftTestingHelpers**: Support for Swift's new Testing framework — `@LeakTracked` macro for memory leak tracking, plus Combine and Observation testing helpers
- **NnTestKitMacros**: Macro target backing `NnSwiftTestingHelpers` (requires Swift 5.10+)

## Build & Test Commands

```bash
# Build the package
swift build

# Run tests
swift test

# Build for specific platform
swift build -Xswiftc -sdk -Xswiftc $(xcrun --sdk iphonesimulator --show-sdk-path) -Xswiftc -target -Xswiftc x86_64-apple-ios15.0-simulator

# Clean build
swift package clean
```

## Architecture

### Library Dependencies
- `NnTestHelpers` depends on `NnTestVariables`
- `NnUITestHelpers` depends on `NnTestHelpers`
- `NnSwiftTestingHelpers` depends on `NnTestKitMacros`
- `NnTestKitMacros` requires Swift 5.10+ and SwiftSyntax
- All helper libraries import testing frameworks (XCTest/Testing) and should only be used in test targets

### Key Components

**NnTestHelpers/XCTestCase+Extensions.swift**: Core XCTest extensions including:
- Memory leak tracking via `trackForMemoryLeaks()`
- Property assertions (`assertProperty`, `assertPropertyEquality`)
- Array assertions (`assertArray`)
- Error handling assertions (sync and async versions)
- Combine publisher testing utilities (Swift 6 compatible with `@preconcurrency`)

**NnUITestHelpers/BaseUITestCase.swift**: UI testing base class providing:
- Environment variable setup helpers
- UI element waiting and interaction
- Date picker, row selection/deletion helpers
- Third-party alert handling
- Swift 6 compatible with `@MainActor` annotation

**NnSwiftTestingHelpers/LeakTracked.swift**: `@LeakTracked` macro declaration and `TrackableObject` class for memory leak tracking without inheritance

**NnSwiftTestingHelpers/CombineHelpers.swift**: `Published.Publisher.waitUntil(timeout:condition:)` for asserting that a `@Published` property eventually reaches a target state

**NnSwiftTestingHelpers/ObservationHelpers.swift**: `observationStream(of:)`, `AsyncStream.waitUntil`, and `expectObservationFires` for testing `@Observable` change propagation (iOS 17+ / macOS 14+)

**NnTestKitMacros/LeakTrackedMacro.swift**: Macro implementation that injects memory tracking functionality with thread-safe NSLock synchronization

**NnTestVariables/TestVariables.swift**: ProcessInfo extensions for test detection (`isTesting`, `isUITesting`)

## Testing Patterns

### Memory Leak Detection

**Recommended: Using @LeakTracked Macro (Swift 5.10+)**
```swift
import Testing
@testable import YourModule

@LeakTracked
final class MyTestSuite {
    @Test("Memory leak detection")
    func test_memoryLeak() {
        let sut = makeSUT()
        // Test operations...
    }

    private func makeSUT(fileID: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column) -> MyClass {
        let sut = MyClass()
        trackForMemoryLeaks(sut, fileID: fileID, filePath: filePath, line: line, column: column)
        return sut
    }
}
```

**XCTest Pattern**
```swift
func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> MyClass {
    let sut = MyClass()
    trackForMemoryLeaks(sut, file: file, line: line)
    return sut
}
```

### Benefits of @LeakTracked Macro
- No inheritance requirement — the suite is a plain `final class`, not an `XCTestCase` subclass
- Thread-safe implementation with NSLock synchronization
- Cleaner composition-based approach
- Swift 6 concurrency compatible
- Supports multiple leak detection behaviors (fail, warn, expect leak)
- Comprehensive documentation with migration examples

**Note:** the macro generates a `deinit` and mutates stored properties from a
non-`mutating` method, so the decorated type **must be a class**. Applying
`@LeakTracked` to a `struct` will not compile.

## The Skills (`Skills/`)

The published skills for this package live in this repo, in three plugins. They
are not copies of documentation kept elsewhere — they *are* the source of truth,
consumed by every project that installs them.

| Plugin | Skill | Covers |
|---|---|---|
| `Skills/nn-testing` | `skills/swift-unit-tests` | Unit test conventions and workflows — library-neutral, no NnTestKit APIs |
| `Skills/NnTesting` | `skills/NnTestKit` | The API reference — `UnitTestApi.md`, `SwiftTestingApi.md`, `UITestApi.md` — plus `LeakTrackingConventions.md` |
| `Skills/nn-ui-testing` | `skills/swift-ui-tests` | UI test conventions, seeding, accessibility identifiers (built on `BaseUITestCase`) |

### Independent plugins

The three plugins are independent: none declares another in
`"dependencies"`, and `NnTesting` does not mention `nn-testing` or
`nn-ui-testing` at all. A project installs any combination.

`nn-testing` and `nn-ui-testing` may refer to the `NnTestKit` skill, but only as
optional: every reference says what to do when that skill is not installed
(read the details from the project's existing tests or the resolved NnTestKit
package source). Their skills must never stop because `NnTesting` is missing.

**Layering rule:** a convention that names an NnTestKit API (`@LeakTracked`,
`trackForMemoryLeaks`, `NnSwiftTestingHelpers`, …) belongs in the `NnTestKit`
skill. `swift-unit-tests` states the principle and routes there, optionally, from one
place — the "Leak-Tracking Library" section of its `SKILL.md`. Keep
`swift-unit-tests` free of NnTestKit APIs.

`swift-ui-tests` is built on `BaseUITestCase` helpers throughout, so it lives in
its own plugin, `nn-ui-testing`, and installs separately from
`swift-unit-tests`. It states conventions only; NnTestKit API facts belong in
`UITestApi.md`, and the skill points there.

### It lives here so it changes with the API

It previously lived in a separate marketplace repo, which meant an API change
and its documentation change were two PRs in two repos — a convention with no
enforcement point. It drifted, repeatedly. Co-locating them makes the API change
and the doc change the same diff, reviewed together.

**Any PR that changes the public API must also update `Skills/`.** No CI check
enforces this; it is a review convention.

### `plugin.json` `version` is written by nnex

`nnex ship package` sets the `version` field in both
`Skills/nn-testing/.claude-plugin/plugin.json` and
`Skills/NnTesting/.claude-plugin/plugin.json` to the release tag on every
release. **Do not edit it by hand.** Claude Code reads this field first when
deciding whether an installed plugin has an update, so a hand-typed number that
falls behind keeps consumers on an old copy. Because nnex writes it alongside the
marketplace `ref` (below), the two always name the same release.

## Releasing

Releases go through `nnex ship package`, which tags the release and publishes
the skills. Both plugins have their own marketplace entry, each **pinned to the
same release tag**, not to a branch:

```jsonc
// nn-swift-skills/.claude-plugin/marketplace.json
{
  "name": "NnTesting",
  "source": {
    "source": "git-subdir",
    "url": "https://github.com/nikolainobadi/NnTestKit.git",
    "path": "Skills/NnTesting",
    "ref": "2.2.1"          // <- bumped on every release
  }
},
{
  "name": "nn-testing",
  "source": {
    "source": "git-subdir",
    "url": "https://github.com/nikolainobadi/NnTestKit.git",
    "path": "Skills/nn-testing",
    "ref": "2.2.1"          // <- bumped on every release, same tag
  }
}
```

**Skill edits ship on release, not on merge.** Merging a documentation fix
changes nothing for consumers until the next tag is cut and the pinned `ref`
moves. This surprises people who just merged a correction and can't see it. It
is the intended trade: what consumers read always describes a version they can
actually depend on.

**The failure mode to know about:** an unbumped `ref` serves the previous
release's documentation forever. Nothing errors and nothing warns. All three skill
folders (`Skills/NnTesting`, `Skills/nn-testing`, and `Skills/nn-ui-testing`) are
listed as the target's `skills` in `.nnex/nnex.json`, so every `nnex ship package`
publishes all three. If a folder ever drops out of that list, its conventions go
silently stale.

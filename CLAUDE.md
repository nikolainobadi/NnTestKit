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

The published skill for this package lives in this repo, in one plugin. It is
not a copy of documentation kept elsewhere — it *is* the source of truth,
consumed by every project that installs it.

| Plugin | Skill | Covers |
|---|---|---|
| `Skills/NnTesting` | `skills/NnTestKit` | The API reference — `UnitTestApi.md`, `SwiftTestingApi.md`, `UITestApi.md` — plus `LeakTrackingConventions.md` |

### API reference only

`NnTesting` holds NnTestKit's API reference and nothing else. Unit and UI test
conventions (`swift-unit-tests`, `swift-ui-tests`) are maintained outside this
repo as separate plugins. `NnTesting` must not depend on or mention them: it
declares no `"dependencies"`, and its skill files make no reference to them.

**Layering rule:** API facts (signatures, parameters, behavior of
`@LeakTracked`, `trackForMemoryLeaks`, `BaseUITestCase`, seeding helpers, …)
belong in the `NnTestKit` skill. Conventions about how to structure and write
tests do not.

### It lives here so it changes with the API

It previously lived in a separate marketplace repo, which meant an API change
and its documentation change were two PRs in two repos — a convention with no
enforcement point. It drifted, repeatedly. Co-locating them makes the API change
and the doc change the same diff, reviewed together.

**Any PR that changes the public API must also update `Skills/`.** No CI check
enforces this; it is a review convention.

### `plugin.json` `version` is written by nnex

`nnex ship package` sets the `version` field in
`Skills/NnTesting/.claude-plugin/plugin.json` to the release tag on every
release. **Do not edit it by hand.** Claude Code reads this field first when
deciding whether an installed plugin has an update, so a hand-typed number that
falls behind keeps consumers on an old copy. Because nnex writes it alongside the
marketplace `ref` (below), the two always name the same release.

## Releasing

Releases go through `nnex ship package`, which tags the release and publishes
the skill. Its marketplace entry is **pinned to the release tag**, not to a
branch:

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
}
```

**Skill edits ship on release, not on merge.** Merging a documentation fix
changes nothing for consumers until the next tag is cut and the pinned `ref`
moves. This surprises people who just merged a correction and can't see it. It
is the intended trade: what consumers read always describes a version they can
actually depend on.

**The failure mode to know about:** an unbumped `ref` serves the previous
release's documentation forever. Nothing errors and nothing warns. The skill folder
(`Skills/NnTesting`) is listed as the target's `skills` in `.nnex/nnex.json`, so
every `nnex ship package` publishes it. If it ever drops out of that list, the API
reference goes silently stale.

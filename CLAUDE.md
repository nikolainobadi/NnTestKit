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

## The Skill (`Skills/NnTesting`)

The published API reference for this package lives in this repo, at
`Skills/NnTesting`. It is not a copy of documentation kept elsewhere — it *is*
the source of truth, consumed by every project that installs the `NnTesting`
plugin.

| Skill | Covers |
|---|---|
| `skills/NnTestKit` | The API reference — `UnitTestApi.md`, `SwiftTestingApi.md`, `UITestApi.md` |
| `skills/swift-unit-tests` | Unit test conventions and workflows |
| `skills/swift-ui-tests` | UI test conventions, seeding, accessibility identifiers |

### It lives here so it changes with the API

It previously lived in a separate marketplace repo, which meant an API change
and its documentation change were two PRs in two repos — a convention with no
enforcement point. It drifted, repeatedly. Co-locating them makes the API change
and the doc change the same diff, reviewed together.

**Any PR that changes the public API must also update `Skills/`.** The
`.github/workflows/skill-docs.yml` check enforces this: it fails a PR that
touches `public`/`open`/`package` declarations under `Sources/` without touching
anything under `Skills/`. If a PR genuinely changes no documented behavior
(reformatting, an internal rename, moving a file), add the `skip-skill-check`
label to waive it.

### `plugin.json` deliberately has no `version`

`Skills/NnTesting/.claude-plugin/plugin.json` intentionally omits the `version`
field. **Do not reintroduce it.** Git-based plugin sources key their cache by
commit sha, so the field is never read — it is a hand-typed number that nothing
verifies and nothing updates, which recreates exactly the stale-number problem
the co-location was meant to end. The marketplace `ref` (below) is the real
version pin.

## Releasing

The marketplace entry for this skill is **pinned to a release tag**, not to a
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

The bump is automated. `.github/workflows/skill-ref-bump.yml` fires on tag push,
rewrites the `ref` in `nikolainobadi/nn-swift-skills`, and opens a PR there.

**If that automation is ever removed, the bump becomes a manual cross-repo step**
— and this is the failure mode to know about: an unbumped `ref` serves the
previous release's documentation forever. Nothing errors and nothing warns. The
`skill-docs.yml` check cannot see it either; that check only guards "API changed
without `Skills/` updated." So the ref-bump workflow is not optional.

### The `MARKETPLACE_TOKEN` secret

`skill-ref-bump.yml` needs a repo secret `MARKETPLACE_TOKEN`: a fine-grained
token with `contents:write` and `pull-requests:write` on
`nikolainobadi/nn-swift-skills`, and nothing else.

**It is shared across every package repo that publishes to that marketplace**
(SwiftPickerKit, NnArgumentParser, this one, …). The grant is identical in each,
so a per-package token would buy no reduction in blast radius and cost another
expiry date to track.

The corollary is that **rotation is fan-out**: when it expires or is revoked, the
bump breaks in *every* repo holding it, and each needs `gh secret set` again. A
failed ref-bump run complaining about the token almost always means "rotate the
shared token," not "this repo's workflow is broken."

| | |
|---|---|
| Token name | `nn-swift-skills-ref-bump` (named for what it grants, not for a holder) |
| Expiry | _record the expiry date here when the token is next rotated_ |
| Scope | `contents:write`, `pull-requests:write` on `nikolainobadi/nn-swift-skills` only |

Never substitute a `gh auth token` for this — those typically carry `repo` scope
across the whole account, turning a two-permission grant into a total one.
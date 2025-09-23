# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

NnTestKit is a Swift package providing testing utilities for iOS/macOS projects. It consists of four libraries:
- **NnTestHelpers**: Main testing utilities extending XCTest (memory leak tracking, assertions, UI test helpers)
- **NnTestVariables**: Lightweight library with test-related properties (can be included in production)
- **NnSwiftTestingHelpers**: Support for Swift's new Testing framework with memory leak tracking
- **NnTestKitMacros**: Swift macros for enhanced testing functionality (requires Swift 5.10+)

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
- `NnSwiftTestingHelpers` depends on `NnTestKitMacros`
- `NnTestKitMacros` requires Swift 5.10+ and SwiftSyntax
- All helper libraries import testing frameworks (XCTest/Testing) and should only be used in test targets

### Key Components

**NnTestHelpers/XCTestCase+Extensions.swift**: Core XCTest extensions including:
- Memory leak tracking via `trackForMemoryLeaks()`
- Property assertions (`assertProperty`, `assertPropertyEquality`)
- Array assertions (`assertArray`)
- Error handling assertions (sync and async versions)
- Combine publisher testing utilities

**NnTestHelpers/BaseUITestCase.swift**: UI testing base class providing:
- Environment variable setup helpers
- UI element waiting and interaction
- Date picker, row selection/deletion helpers
- Third-party alert handling

**NnSwiftTestingHelpers/SwiftTesting+MemoryLeakTracking.swift**: `TrackingMemoryLeaks` base class for Swift Testing framework that validates tracked objects are deallocated in `deinit` (deprecated in favor of `@LeakTracked` macro)

**NnSwiftTestingHelpers/LeakTracked.swift**: `@LeakTracked` macro for memory leak tracking without inheritance, includes `TrackableObject` and `SourceLocation` types

**NnTestKitMacros/LeakTrackedMacro.swift**: Macro implementation that injects memory tracking functionality and `@Suite(.serialized)` automatically

**NnTestVariables/TestVariables.swift**: ProcessInfo extensions for test detection (`isTesting`, `isUITesting`)

## Testing Patterns

### Memory Leak Detection

**Recommended: Using @LeakTracked Macro (Swift 5.10+)**
```swift
import Testing
@testable import YourModule

@LeakTracked
struct MyTestSuite {
    @Test("Memory leak detection")
    func test_memoryLeak() {
        let _ = makeSUT()
    }

    private func makeSUT(fileID: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column) -> MyClass {
        let sut = MyClass()
        trackForMemoryLeaks(sut, fileID: fileID, filePath: filePath, line: line, column: column)
        return sut
    }
}
```

**Legacy: Using TrackingMemoryLeaks Base Class (Deprecated)**
```swift
final class MyTestSuite: TrackingMemoryLeaks {
    @Test("Memory leak detection")
    func test_memoryLeak() {
        let _ = makeSUT()
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
- No inheritance requirement (use struct or class)
- Automatic `@Suite(.serialized)` injection eliminates Sendable conformance issues
- Thread-safe implementation with NSLock
- Cleaner composition-based approach
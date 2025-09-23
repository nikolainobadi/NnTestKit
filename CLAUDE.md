# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

NnTestKit is a Swift package providing testing utilities for iOS/macOS projects. It consists of three libraries:
- **NnTestHelpers**: Main testing utilities extending XCTest (memory leak tracking, assertions, UI test helpers)
- **NnTestVariables**: Lightweight library with test-related properties (can be included in production)
- **NnSwiftTestingHelpers**: Support for Swift's new Testing framework with memory leak tracking

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
- `NnSwiftTestingHelpers` is standalone
- Both helper libraries import testing frameworks (XCTest/Testing) and should only be used in test targets

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

**NnSwiftTestingHelpers/SwiftTesting+MemoryLeakTracking.swift**: `TrackingMemoryLeaks` base class for Swift Testing framework that validates tracked objects are deallocated in `deinit`

**NnTestVariables/TestVariables.swift**: ProcessInfo extensions for test detection (`isTesting`, `isUITesting`)

## Testing Patterns

Memory leak detection requires calling `trackForMemoryLeaks()` in factory methods with proper source location parameters:
```swift
func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> MyClass {
    let sut = MyClass()
    trackForMemoryLeaks(sut, file: file, line: line)
    return sut
}
```

For Swift Testing, inherit from `TrackingMemoryLeaks` and pass source location parameters to track objects.
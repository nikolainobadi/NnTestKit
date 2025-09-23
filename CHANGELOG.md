# Changelog

All notable changes to NnTestKit will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.4.0] - 2025-09-23
### Added
- New `@LeakTracked` macro for memory leak detection without inheritance requirement
- Swift macros support through new `NnTestKitMacros` library
- Comprehensive documentation for `@LeakTracked` macro with migration guide from deprecated `TrackingMemoryLeaks`

### Changed
- Deprecated `TrackingMemoryLeaks` class in favor of `@LeakTracked` macro for better Sendable conformance

### Fixed
- Swift 6 concurrency warnings with `@MainActor` annotation on `BaseUITestCase`
- Combine import concurrency warning with `@preconcurrency` attribute

## [1.3.0] - 2025-01-14
### Added
- Combine testing support with new `CombineHelpers` for testing `@Published` properties
- `waitUntil` method for async waiting on publishers with customizable timeout
- `PublisherError.timeout` for handling publisher timeout scenarios
- Comprehensive README documentation with usage examples

## [1.2.1] - 2025-01-14
### Changed
- Moved Swift Testing helpers to separate `NnSwiftTestingHelpers` library for better separation of concerns

## [1.2.0] - 2025-01-14
### Added
- Swift Testing framework support with memory leak tracking
- `TrackingMemoryLeaks` class for detecting retain cycles using Swift Testing
- Source location tracking for Swift Testing memory leak detection

### Changed
- Minor code reformatting

## [1.1.3] - 2024-05-23
### Changed
- Updated README with improved examples and formatting

## [1.1.2] - 2024-05-23
### Fixed
- Fixed bug with `evaluateWaitResult` for inverted expectations in wait conditions

## [1.1.1] - 2024-05-23
### Changed
- Added more robust failure messages for `waitForCondition` method
- Updated `waitForCondition` to properly handle file/line arguments for better error tracking

## [1.1.0] - 2024-05-23
### Added
- Enhanced UI testing utilities in `BaseUITestCase`
- Improved async testing with `waitForAsync` method

### Fixed
- Fixed `waitForAsync` method implementation
- Fixed `assertError` methods for more reliable error testing

### Changed
- Updated inline documentation throughout the codebase
- Enhanced `Date+TestExtensions` with additional testing utilities

## [1.0.0] - 2024-05-22
### Added
- Core XCTest extension library for iOS testing
- Memory leak tracking with `trackForMemoryLeaks` method
- Property assertions (`assertProperty`, `assertPropertyEquality`)
- Array assertions with `assertArray` contains methods
- Error handling assertions with file/line tracking
- Complete `BaseUITestCase` for UI testing with:
  - Environment variable setup
  - Element waiting and finding utilities
  - Date picker manipulation
  - Table/collection view row management
  - Third-party alert handling
  - Text field input utilities
- `NnTestVariables` library with `ProcessInfo` extensions for test detection
- Swift 5.5 support with iOS 15+ and macOS 12+ platform requirements
- Comprehensive README documentation

[Unreleased]: https://github.com/nikolainobadi/NnTestKit/compare/v1.3.0...HEAD
[1.3.0]: https://github.com/nikolainobadi/NnTestKit/compare/v1.2.1...v1.3.0
[1.2.1]: https://github.com/nikolainobadi/NnTestKit/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/nikolainobadi/NnTestKit/compare/v1.1.3...v1.2.0
[1.1.3]: https://github.com/nikolainobadi/NnTestKit/compare/v1.1.2...v1.1.3
[1.1.2]: https://github.com/nikolainobadi/NnTestKit/compare/v1.1.1...v1.1.2
[1.1.1]: https://github.com/nikolainobadi/NnTestKit/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/nikolainobadi/NnTestKit/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/nikolainobadi/NnTestKit/releases/tag/v1.0.0
# Changelog

All notable changes to NnTestKit will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.2.1] - 2026-08-16

Documentation and tooling release. No public API changes.

### Added
- The `NnTesting` skill now lives in this repo at `Skills/NnTesting`, so the API reference changes in the same PR as the API it documents. It is published through the `nn-swift-skills` marketplace, pinned to this tag
- `.github/workflows/skill-docs.yml` fails any PR that changes a `public`/`open`/`package` declaration under `Sources/` without touching `Skills/`. Waive with the `skip-skill-check` label when a PR changes no documented behavior
- `.github/workflows/skill-ref-bump.yml` bumps the marketplace's pinned `ref` on tag push, so released documentation always matches a shipped version
- README sections for `observationStream(of:)`, `expectObservationFires`, `Published.Publisher.waitUntil`, and `selectTime` — all shipped in 2.2.0 but previously undocumented

### Fixed
- README platform badge claimed iOS 15+ / macOS 12+; the package requires iOS 17+ / macOS 13+
- README and doc comments on `waitForElement`, `elementAppeared`, `elementNotAppeared`, and `deleteRow` still described a 3-second default timeout, which 2.1.0 replaced with `UITestSeedDefaults.timeout` (10 seconds)
- README stated `selectDate` could only change the day, or the month and day, omitting `selectTime`
- README named the `typeInField` parameter `shouldTapFieldBeforeTyping`; it is `tapFieldBeforeTyping`
- `CLAUDE.md` showed `@LeakTracked` applied to a `struct`; the macro generates a `deinit` and requires a class
- Broken table-of-contents anchor for the BaseUITestCase section

## [2.2.0] - 2026-05-23

### Added
- Add `observationStream(of:)` helper in `NnSwiftTestingHelpers` that bridges an `@Observable` property to an `AsyncStream` of post-change values, mirroring the ergonomics of `Published.Publisher.waitUntil` from `CombineHelpers` (macOS 14+, iOS 17+, tvOS 17+, watchOS 10+)
- Add `AsyncStream.waitUntil(timeout:condition:)` extension (with `AsyncStream.WaitError.timeout`) for awaiting a value that satisfies a predicate
- Add `expectObservationFires(when:afterReading:timeout:sourceLocation:)` one-shot assertion that verifies an `@Observable` property change propagates through `withObservationTracking` after running a trigger
- Add `selectTime(pickerId:hour:minute:period:timeout:)` helper on `BaseUITestCase` for adjusting compact-style `DatePicker`s configured with `displayedComponents: .hourAndMinute`, including optional AM/PM wheel support for 12-hour locales

## [2.1.0] - 2026-04-11

### Added
- New `UITestSeedContext<Config>` struct in `NnTestVariables` for passing typed seed configuration from UI tests into the app under test, with a `fromEnvironment(_:)` factory that decodes `UITEST_SEED_CONFIG` JSON
- New `UITestSeedKey` enum (`runId`, `userEmail`, `seedConfig`) exposing canonical environment variable names shared between test and app targets
- New `UITestSeedDefaults` namespace with a `password` constant and a mutable `timeout` property (default 10s) used as the fallback timeout for all UI helpers
- Add `launchSeeded(config:envKeys:)` helper on `BaseUITestCase` that encodes a `Codable` seed config, sets a unique `runId` and test user email, and launches the app
- Add `setSeedConfig(_:envKeys:)` helper for seeding the environment when another flow owns the launch step
- Add `mainUserEmail` property and `seedEmail(for:)` helper on `BaseUITestCase` for retrieving generated per-run test user emails
- Add `makeUniqueName(_:)` helper for generating collision-free names across UI test runs
- Add `dismissPasswordPromptIfNeeded(timeout:)` helper that dismisses the iOS "Save Password?" system prompt after login flows
- Add `tapFirstButton(_:query:timeout:)` helper that taps the first matching button, for cases where iOS (e.g. iOS 26+ alerts) creates duplicate elements in the accessibility tree

### Changed
- UI test helper timeouts now default to `UITestSeedDefaults.timeout` (10 seconds) instead of a hard-coded 3 seconds, and can be overridden globally by setting `UITestSeedDefaults.timeout` in `setUpWithError`. Affected methods: `tapButton`, `tapAlertButton`, `tapAlertSheetButton`, `tapToggle`, `tapSegmentedControl`, `adjustStepper`, `waitForElement`, `elementAppeared`, `elementNotAppeared`, `typeInField`, and `typeInAlertField`

## [2.0.0] - 2025-11-22
### Changed
- **BREAKING**: Moved UI testing helpers from `NnTestHelpers` to new `NnUITestHelpers` library
  - `BaseUITestCase` and all UI test extensions now require importing `NnUITestHelpers`
  - Update Package.swift to include `.product(name: "NnUITestHelpers", package: "NnTestKit")`
  - Update test file imports from `import NnTestHelpers` to `import NnUITestHelpers`
- Refactored `BaseUITestCase` into focused extension files for better organization
- Updated `tapAlertButton` default button identifier from "Ok" to "Okay"

### Added
- New `NnUITestHelpers` library with focused UI testing utilities
- Timeout parameters (default 3 seconds) to all UI test helper methods for customizable element waiting:
  - Button actions (`tapButton`, `tapAlertButton`, `tapAlertSheetButton`)
  - Control actions (`tapToggle`, `tapSegmentedControl`, `adjustStepper`)
  - Element retrieval (`getRowContainingText`, `getField`)
  - Text input (`typeInField`, `typeInAlertField`)
  - Date picker actions (`selectDate`)
  - Row actions (`deleteRow`)
  - Assertions (`assertButton`)

### Removed
- **BREAKING**: Removed deprecated `TrackingMemoryLeaks` class (use `@LeakTracked` macro instead)

## [1.4.1] - 2025-09-27
### Changed
- Clarified @LeakTracked macro documentation to emphasize class requirement over struct
- Expanded memory leak detection usage examples with proper import statements
- Simplified test class declarations throughout README documentation

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

[Unreleased]: https://github.com/nikolainobadi/NnTestKit/compare/v2.2.0...HEAD
[2.2.0]: https://github.com/nikolainobadi/NnTestKit/compare/v2.1.0...v2.2.0
[2.1.0]: https://github.com/nikolainobadi/NnTestKit/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/nikolainobadi/NnTestKit/compare/v1.4.1...v2.0.0
[1.4.1]: https://github.com/nikolainobadi/NnTestKit/compare/v1.4.0...v1.4.1
[1.4.0]: https://github.com/nikolainobadi/NnTestKit/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/nikolainobadi/NnTestKit/compare/v1.2.1...v1.3.0
[1.2.1]: https://github.com/nikolainobadi/NnTestKit/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/nikolainobadi/NnTestKit/compare/v1.1.3...v1.2.0
[1.1.3]: https://github.com/nikolainobadi/NnTestKit/compare/v1.1.2...v1.1.3
[1.1.2]: https://github.com/nikolainobadi/NnTestKit/compare/v1.1.1...v1.1.2
[1.1.1]: https://github.com/nikolainobadi/NnTestKit/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/nikolainobadi/NnTestKit/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/nikolainobadi/NnTestKit/releases/tag/v1.0.0
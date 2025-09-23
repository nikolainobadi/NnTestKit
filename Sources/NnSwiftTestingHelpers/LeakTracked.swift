//
//  LeakTracked.swift
//  NnTestKit
//
//  Created by Nikolai Nobadi on 1/22/25.
//

import Foundation
import Testing

/// A macro that adds memory leak tracking capabilities to test suites.
///
/// `@LeakTracked` automatically injects memory leak tracking functionality into your test suite,
/// allowing you to detect and validate memory management in your tests. The macro generates:
/// - A `trackForMemoryLeaks(_:behavior:)` method to track objects
/// - Automatic verification in `deinit` that tracked objects were deallocated
/// - Thread-safe tracking with proper synchronization
///
/// ## Usage
///
/// Apply the macro to your test suite:
/// ```swift
/// @LeakTracked
/// struct MyTestSuite {
///     @Test("Verify no memory leaks")
///     func test_objectDeallocates() {
///         let object = MyClass()
///         trackForMemoryLeaks(object)  // Will fail if object leaks
///     }
/// }
/// ```
///
/// ## Behavior Modes
///
/// The macro supports three leak detection behaviors:
///
/// ### `.failIfLeaked` (Default)
/// Fails the test if a tracked object is not deallocated:
/// ```swift
/// trackForMemoryLeaks(object)  // Fails on leak
/// trackForMemoryLeaks(object, behavior: .failIfLeaked)  // Explicit
/// ```
///
/// ### `.warnIfLeaked`
/// Logs a warning but doesn't fail the test:
/// ```swift
/// trackForMemoryLeaks(object, behavior: .warnIfLeaked)
/// ```
///
/// ### `.expectLeak`
/// Fails if the object IS deallocated (useful for testing retain cycles):
/// ```swift
/// trackForMemoryLeaks(object, behavior: .expectLeak)
/// ```
///
/// ## Factory Method Pattern
///
/// Common pattern for system under test (SUT) creation:
/// ```swift
/// @LeakTracked
/// struct ViewModelTests {
///     @Test("ViewModel deallocates properly")
///     func test_viewModelLifecycle() {
///         let sut = makeSUT()
///         // Test operations...
///     }
///
///     private func makeSUT(
///         fileID: String = #fileID,
///         filePath: String = #filePath,
///         line: Int = #line,
///         column: Int = #column
///     ) -> ViewModel {
///         let service = MockService()
///         let sut = ViewModel(service: service)
///
///         // Track both objects
///         trackForMemoryLeaks(service, fileID: fileID, filePath: filePath, line: line, column: column)
///         trackForMemoryLeaks(sut, fileID: fileID, filePath: filePath, line: line, column: column)
///
///         return sut
///     }
/// }
/// ```
///
/// ## Migration from TrackingMemoryLeaks
///
/// If migrating from the deprecated `TrackingMemoryLeaks` base class:
///
/// **Before (Deprecated):**
/// ```swift
/// final class MyTests: TrackingMemoryLeaks {
///     @Test func test_example() {
///         let object = MyClass()
///         trackForMemoryLeaks(object)
///     }
/// }
/// ```
///
/// **After (Recommended):**
/// ```swift
/// @LeakTracked
/// struct MyTests {
///     @Test func test_example() {
///         let object = MyClass()
///         trackForMemoryLeaks(object)
///     }
/// }
/// ```
///
/// ## Thread Safety
///
/// The generated tracking is thread-safe using NSLock for synchronization.
/// Multiple tests can run concurrently without interference.
///
/// ## Requirements
///
/// - Swift 5.10 or later
/// - Swift Testing framework
/// - Import both `Testing` and `Foundation` in your test file
///
/// - Note: The macro automatically adds `@Suite(.serialized)` to avoid Sendable conformance issues
@attached(member, names: named(trackForMemoryLeaks), arbitrary)
public macro LeakTracked() = #externalMacro(module: "NnTestKitMacros", type: "LeakTrackedMacro")

/// An object wrapper that tracks a weak reference for memory leak detection.
///
/// `TrackableObject` holds a weak reference to an object being tracked for memory leaks,
/// along with the source location where tracking was initiated. This allows the test
/// framework to report the exact location where a leaked object was tracked.
///
/// - Note: This class is marked as `@unchecked Sendable` because it's only used
///         within the controlled environment of test execution and properly
///         synchronized by the generated macro code.
public final class TrackableObject: @unchecked Sendable {
    /// Weak reference to the tracked object. If this is non-nil at test teardown,
    /// it indicates a memory leak.
    public weak var weakRef: AnyObject?

    /// The error message to display if a leak is detected.
    public let errorMessage: String

    /// The source location where `trackForMemoryLeaks` was called,
    /// used for accurate error reporting.
    public let sourceLocation: SourceLocation

    /// Creates a new trackable object.
    /// - Parameters:
    ///   - weakRef: The object to track for memory leaks
    ///   - sourceLocation: The location where tracking was initiated
    public init(weakRef: AnyObject, sourceLocation: SourceLocation) {
        self.weakRef = weakRef
        self.sourceLocation = sourceLocation
        self.errorMessage = "\(String(describing: weakRef)) should have been deallocated. Potential memory leak"
    }
}

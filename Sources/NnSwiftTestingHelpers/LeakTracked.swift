//
//  LeakTracked.swift
//  NnTestKit
//
//  Created by Nikolai Nobadi on 1/22/25.
//

import Foundation
import Testing

/// A macro that adds memory leak tracking capabilities to test classes.
///
/// `@LeakTracked` automatically injects memory leak tracking functionality into your test class,
/// allowing you to detect and validate memory management in your tests. The macro generates:
/// - A `trackForMemoryLeaks(_:behavior:)` method to track objects
/// - Automatic verification in `deinit` that tracked objects were deallocated
/// - Thread-safe tracking with proper synchronization
///
/// **Important**: This macro can only be applied to classes (not structs) because it adds a `deinit`
/// method to verify tracked objects were deallocated
///
/// ## Usage
///
/// Apply the macro to your test class and use the `makeSUT` factory pattern:
/// ```swift
/// @LeakTracked
/// final class MyTestSuite {
///     @Test("Verify no memory leaks")
///     func test_objectDeallocates() {
///         let sut = makeSUT()
///         // Test operations...
///     }
///
///     private func makeSUT(
///         fileID: String = #fileID,
///         filePath: String = #filePath,
///         line: Int = #line,
///         column: Int = #column
///     ) -> MyClass {
///         let sut = MyClass()
///         trackForMemoryLeaks(sut, fileID: fileID, filePath: filePath, line: line, column: column)
///         return sut
///     }
/// }
/// ```
///
/// ## Behavior Modes
///
/// The macro supports three leak detection behaviors that can be specified in your `makeSUT` method:
///
/// ### `.failIfLeaked` (Default)
/// Fails the test if a tracked object is not deallocated:
/// ```swift
/// private func makeSUT(fileID: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column) -> MyClass {
///     let sut = MyClass()
///     trackForMemoryLeaks(sut, fileID: fileID, filePath: filePath, line: line, column: column)  // Default: fails on leak
///     return sut
/// }
/// ```
///
/// ### `.warnIfLeaked`
/// Logs a warning but doesn't fail the test:
/// ```swift
/// private func makeSUT(fileID: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column) -> MyClass {
///     let sut = MyClass()
///     trackForMemoryLeaks(sut, behavior: .warnIfLeaked, fileID: fileID, filePath: filePath, line: line, column: column)
///     return sut
/// }
/// ```
///
/// ### `.expectLeak`
/// Fails if the object IS deallocated (useful for testing retain cycles):
/// ```swift
/// private func makeSUT(fileID: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column) -> MyClass {
///     let sut = MyClass()
///     trackForMemoryLeaks(sut, behavior: .expectLeak, fileID: fileID, filePath: filePath, line: line, column: column)
///     return sut
/// }
/// ```
///
/// ## Tracking Multiple Objects
///
/// When your SUT has dependencies, track them all in the `makeSUT` method:
/// ```swift
/// @LeakTracked
/// final class ViewModelTests {
///     @Test("ViewModel and dependencies deallocate properly")
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
///         let repository = MockRepository()
///         let sut = ViewModel(service: service, repository: repository)
///
///         // Track all objects that should be deallocated
///         trackForMemoryLeaks(service, fileID: fileID, filePath: filePath, line: line, column: column)
///         trackForMemoryLeaks(repository, fileID: fileID, filePath: filePath, line: line, column: column)
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
///         let sut = makeSUT()
///         // Test operations...
///     }
///
///     private func makeSUT(fileID: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column) -> MyClass {
///         let sut = MyClass()
///         trackForMemoryLeaks(sut, fileID: fileID, filePath: filePath, line: line, column: column)
///         return sut
///     }
/// }
/// ```
///
/// **After (Recommended):**
/// ```swift
/// @LeakTracked
/// final class MyTests {
///     @Test func test_example() {
///         let sut = makeSUT()
///         // Test operations...
///     }
///
///     private func makeSUT(fileID: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column) -> MyClass {
///         let sut = MyClass()
///         trackForMemoryLeaks(sut, fileID: fileID, filePath: filePath, line: line, column: column)
///         return sut
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
/// - Note: The macro can only be applied to classes (not structs) as it injects a `deinit` method
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

//
//  TrackingMemoryLeaks.swift
//  NnTestKit
//
//  Created by Nikolai Nobadi on 4/5/25.
//

import Testing

/// A utility class to track objects for memory leaks in tests using Swift's `Testing` framework.
/// When the instance of this class is deallocated, it verifies that all tracked objects have also been deallocated.
///
/// **Deprecated**: Consider using the new `@LeakTracked` macro instead, which provides the same functionality
/// without requiring inheritance and automatically handles Sendable conformance issues.
///
/// ## Traditional Usage (Deprecated)
/// ```swift
/// import Testing
/// @testable import YourModule
///
/// final class MyClassSwiftTesting: TrackingMemoryLeaks {
///     @Test("MyClass leaks memory due to retain cycle")
///     func test_memoryLeakDetected() {
///         let _ = makeSUT()
///     }
/// }
///
/// private extension MyClassSwiftTesting {
///     func makeSUT(fileID: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column) -> MyClass {
///         let service = MyService()
///         let sut = MyClass(service: service)
///         trackForMemoryLeaks(sut, fileID: fileID, filePath: filePath, line: line, column: column)
///         return sut
///     }
/// }
/// ```
///
/// ## New Usage with @LeakTracked Macro
/// ```swift
/// @LeakTracked
/// struct MyTestSuite {
///     @Test("MyClass leaks memory due to retain cycle")
///     func test_memoryLeakDetected() {
///         let _ = makeSUT()
///     }
///
///     private func makeSUT(fileID: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column) -> MyClass {
///         let service = MyService()
///         let sut = MyClass(service: service)
///         trackForMemoryLeaks(sut, fileID: fileID, filePath: filePath, line: line, column: column)
///         return sut
///     }
/// }
/// ```
@available(*, deprecated, message: "Use @LeakTracked macro instead. Simply replace 'class MyTests: TrackingMemoryLeaks' with '@LeakTracked struct MyTests'. The macro provides better Sendable conformance, no inheritance requirement, and automatic thread safety.")
open class TrackingMemoryLeaks {
    private var trackingList: [TrackableObject] = []
    
    public init() { }

    /// On deinitialization—similar to using `addTeardownBlock` in `XCTestCase`—this asserts that all tracked objects have been deallocated.
    /// If any object is still in memory at teardown, the test fails with a descriptive message and the source location where tracking was initiated.
    deinit {
        for object in trackingList {
            #expect(object.weakRef == nil, "\(object.errorMessage)", sourceLocation: object.sourceLocation)
        }
    }

    /// Tracks the given reference for memory leaks. Should be called within a test method.
    /// - Parameters:
    ///   - ref: The reference to an object that should be deallocated by the end of the test.
    ///   - fileID: The file ID where the tracking is set. Default is the current file.
    ///   - filePath: The file path where the tracking is set. Default is the current path.
    ///   - line: The line number where the tracking is set. Default is the current line.
    ///   - column: The column number where the tracking is set. Default is the current column.
    public func trackForMemoryLeaks(_ ref: AnyObject, fileID: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column) {
        trackingList.append(TrackableObject(weakRef: ref, sourceLocation: .init(fileID: fileID, filePath: filePath, line: line, column: column)))
    }
}

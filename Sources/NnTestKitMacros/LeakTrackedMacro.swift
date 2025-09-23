//
//  LeakTrackedMacro.swift
//  NnTestKit
//
//  Created by Nikolai Nobadi on 1/22/25.
//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxBuilder
import SwiftCompilerPlugin

/// Implementation of the `@LeakTracked` macro that generates memory leak tracking code.
///
/// This macro injects the following into the decorated type:
/// 1. An enum defining leak detection behaviors
/// 2. Thread-safe storage for tracked objects
/// 3. A public API method `trackForMemoryLeaks`
/// 4. A `deinit` that validates all tracked objects were deallocated
///
/// ## Generated Code Structure
///
/// The macro generates:
/// - `_NnLeakBehavior` enum with three modes: `.failIfLeaked`, `.warnIfLeaked`, `.expectLeak`
/// - `_nn_lock` (NSLock) and `_nn_tracked` array for thread-safe object tracking
/// - `trackForMemoryLeaks(_:behavior:fileID:filePath:line:column:)` public method
/// - `deinit` implementation that checks all tracked objects based on their behavior
///
/// ## Thread Safety
///
/// Uses NSLock to synchronize access to the tracking array, ensuring thread-safe
/// operation in concurrent test execution environments.
///
/// ## Implementation Notes
///
/// - The generated code uses Testing framework's `#expect` for assertions
/// - Source locations are preserved from the call site for accurate error reporting
/// - The `deinit` runs assertions appropriate to each object's configured behavior
public struct LeakTrackedMacro: MemberMacro {
    /// Expands the macro to generate memory leak tracking functionality.
    ///
    /// - Parameters:
    ///   - node: The attribute syntax node representing the macro application
    ///   - decl: The declaration group (struct/class) being decorated
    ///   - context: The macro expansion context
    /// - Returns: Array of generated declarations to inject into the type
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf decl: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {

        // Behavior enum for configuring how each tracked object should be validated
        let behaviorEnum: DeclSyntax =
        """
        public enum _NnLeakBehavior {
            case failIfLeaked        // default: fail when a leak is detected
            case warnIfLeaked        // log a warning, but do not fail
            case expectLeak          // test expects a leak; fail if NOT leaked
        }
        """

        // Thread-safe storage for tracked objects and their behaviors
        let storage: DeclSyntax =
        """
        private var _nn_lock = Foundation.NSLock()
        private var _nn_tracked: [(object: TrackableObject, behavior: _NnLeakBehavior)] = []
        """

        // Public API method for tracking objects for memory leaks
        let apiMain: DeclSyntax =
        """
        @discardableResult
        public func trackForMemoryLeaks(_ ref: AnyObject,
                                        behavior: _NnLeakBehavior = .failIfLeaked,
                                        fileID: String = #fileID,
                                        filePath: String = #filePath,
                                        line: Int = #line,
                                        column: Int = #column) -> TrackableObject {
            let item = TrackableObject(
                weakRef: ref,
                sourceLocation: Testing.SourceLocation(
                    fileID: fileID,
                    filePath: filePath,
                    line: line,
                    column: column
                )
            )
            _nn_lock.lock()
            _nn_tracked.append((item, behavior))
            _nn_lock.unlock()
            return item
        }
        """

        // Deinit implementation that validates all tracked objects based on their behavior
        let deinitDecl: DeclSyntax =
        """
        deinit {
            _nn_lock.lock()
            let items = _nn_tracked
            _nn_lock.unlock()

            for (object, behavior) in items {
                let leaked = (object.weakRef != nil)

                switch behavior {
                case .failIfLeaked:
                    #expect(
                        !leaked,
                        "\\(object.errorMessage)",
                        sourceLocation: object.sourceLocation
                    )
                case .warnIfLeaked:
                    if leaked {
                        withKnownIssue(.init(rawValue: object.errorMessage)) {
                            #expect(!leaked, "\\(object.errorMessage)", sourceLocation: object.sourceLocation)
                        }
                    }
                case .expectLeak:
                    // Here a leak is the EXPECTED outcome; fail if it DIDN'T leak.
                    #expect(
                        leaked,
                        "Expected a memory leak, but object was deallocated",
                        sourceLocation: object.sourceLocation
                    )
                }
            }
        }
        """

        return [behaviorEnum, storage, apiMain, deinitDecl]
    }
}

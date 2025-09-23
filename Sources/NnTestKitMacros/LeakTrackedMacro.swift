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

public struct LeakTrackedMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf decl: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {

        let behaviorEnum: DeclSyntax =
        """
        public enum _NnLeakBehavior {
            case failIfLeaked        // default: fail when a leak is detected
            case warnIfLeaked        // log a warning, but do not fail
            case expectLeak          // test expects a leak; fail if NOT leaked
        }
        """

        let storage: DeclSyntax =
        """
        private var _nn_lock = Foundation.NSLock()
        private var _nn_tracked: [(object: TrackableObject, behavior: _NnLeakBehavior)] = []
        """

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

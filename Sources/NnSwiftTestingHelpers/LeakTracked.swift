//
//  LeakTracked.swift
//  NnTestKit
//
//  Created by Nikolai Nobadi on 1/22/25.
//

import Foundation
import Testing

@attached(member, names: named(trackForMemoryLeaks), arbitrary)
public macro LeakTracked() = #externalMacro(module: "NnTestKitMacros", type: "LeakTrackedMacro")

public final class TrackableObject: @unchecked Sendable {
    public weak var weakRef: AnyObject?
    public let errorMessage: String
    public let sourceLocation: SourceLocation  

    public init(weakRef: AnyObject, sourceLocation: SourceLocation) {
        self.weakRef = weakRef
        self.sourceLocation = sourceLocation
        self.errorMessage = "\(String(describing: weakRef)) should have been deallocated. Potential memory leak"
    }
}

//
//  RunStep.swift
//  NnTestKit
//
//  Created by Nikolai Nobadi on 11/21/25.
//

import XCTest

@MainActor
public func runStep(_ details: String, block: () -> Void) {
    XCTContext.runActivity(named: details) { _ in
        block()
    }
}

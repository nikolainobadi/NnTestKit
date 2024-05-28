//
//  TestVariables.swift
//  
//
//  Created by Nikolai Nobadi on 5/22/24.
//

import Foundation

public let IS_TRUE = "IS_TRUE"
public let IS_UI_TESTING = "IS_UI_TESTING"

public extension ProcessInfo {
    static var isTesting: Bool {
        return processInfo.environment[IS_UI_TESTING] == IS_TRUE || NSClassFromString("XCTestCase") != nil
    }
    
    static func containsKey(_ key: String) -> Bool {
        return processInfo.environment[key] == IS_TRUE
    }
}

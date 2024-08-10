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
    /// Indicates whether the app is running in a testing environment.
    static var isTesting: Bool {
        return isUITesting || NSClassFromString("XCTestCase") != nil
    }
    
    /// Indicates whether the app is running in a UI test environment.
    static var isUITesting: Bool {
        return processInfo.environment[IS_UI_TESTING] == IS_TRUE
    }
    
    /// Checks if a specified key is present in the environment variables.
    /// - Parameter key: The key to check.
    /// - Returns: `true` if the key is present, otherwise `false`.
    static func containsKey(_ key: String) -> Bool {
        return processInfo.environment[key] == IS_TRUE
    }
}


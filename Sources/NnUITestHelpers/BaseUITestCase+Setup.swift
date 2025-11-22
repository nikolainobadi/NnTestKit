//
//  BaseUITestCase+Setup.swift
//
//
//  Created by Nikolai Nobadi on 5/22/24.
//

import XCTest
import NnTestVariables

// MARK: - Setup Helpers
public extension BaseUITestCase {
    /// Adds a key-value pair to the launch environment of the app.
    /// - Parameters:
    ///   - key: The key to add.
    ///   - value: The value to associate with the key. Default is "IS_TRUE".
    func addKeyToENV(_ key: String, value: String = IS_TRUE) {
        app.launchEnvironment[key] = value
    }
}

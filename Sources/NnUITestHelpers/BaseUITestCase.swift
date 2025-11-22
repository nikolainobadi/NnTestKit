//
//  BaseUITestCase.swift
//
//
//  Created by Nikolai Nobadi on 5/22/24.
//

import XCTest
import NnTestHelpers
import NnTestVariables

@MainActor
open class BaseUITestCase: XCTestCase {
    public let app = XCUIApplication()

    open override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchEnvironment[IS_UI_TESTING] = IS_TRUE
    }
}

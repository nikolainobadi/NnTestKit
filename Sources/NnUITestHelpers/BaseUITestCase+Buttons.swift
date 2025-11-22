//
//  BaseUITestCase+Buttons.swift
//
//
//  Created by Nikolai Nobadi on 5/22/24.
//

import XCTest

// MARK: - Button Actions
public extension BaseUITestCase {
    /// Taps a button in an alert sheet with the specified identifier.
    /// - Parameters:
    ///   - id: The identifier of the button.
    func tapAlertSheetButton(_ id: String, timeout: TimeInterval = 3, file: StaticString = #filePath, line: UInt = #line) {
        tapButton(id, query: app.scrollViews.otherElements.buttons, timeout: timeout, file: file, line: line)
    }

    /// Taps a button with the specified identifier.
    /// - Parameters:
    ///   - name: The name of the button.
    ///   - query: The query to use for finding the button. Default is nil.
    func tapButton(_ name: String, query: XCUIElementQuery? = nil, timeout: TimeInterval = 3, file: StaticString = #filePath, line: UInt = #line) {
        waitForElement(query ?? app.buttons, id: name, timeout: timeout, file: file, line: line).tap()
    }

    /// Taps a specified button in an alert if it exists.
    /// - Parameters:
    ///   - buttonId: The identifier for the alert button to tap. Default is "Ok".
    func tapAlertButton(buttonId: String = "Ok", timeout: TimeInterval = 3, file: StaticString = #filePath, line: UInt = #line) {
        waitForElement(app.alerts.buttons, id: buttonId, timeout: timeout, file: file, line: line).tap()
    }
}

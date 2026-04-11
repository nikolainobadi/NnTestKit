//
//  BaseUITestCase+Buttons.swift
//
//
//  Created by Nikolai Nobadi on 5/22/24.
//

import XCTest
import NnTestVariables

// MARK: - Button Actions
public extension BaseUITestCase {
    /// Taps a button inside an action sheet presented over a scroll view container.
    func tapAlertSheetButton(_ id: String, timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) {
        tapButton(id, query: app.scrollViews.otherElements.buttons, timeout: timeout, file: file, line: line)
    }

    /// Waits for a button with the given identifier to appear in the provided query (or the app's buttons) and taps it.
    func tapButton(_ name: String, query: XCUIElementQuery? = nil, timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) {
        waitForElement(query ?? app.buttons, id: name, timeout: timeout, file: file, line: line).tap()
    }

    /// Taps a button inside a system alert, defaulting to the "Okay" dismiss button.
    func tapAlertButton(buttonId: String = "Okay", timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) {
        waitForElement(app.alerts.buttons, id: buttonId, timeout: timeout, file: file, line: line).tap()
    }

    /// Taps the first matching button with the given identifier. Use when iOS
    /// creates duplicate elements in the accessibility tree (e.g. nested buttons
    /// inside alerts on iOS 26+).
    func tapFirstButton(_ name: String, query: XCUIElementQuery? = nil, timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) {
        let timeout = timeout ?? UITestSeedDefaults.timeout
        let button = (query ?? app.buttons)[name].firstMatch

        XCTAssertTrue(button.waitForExistence(timeout: timeout), "\(name) button should appear within \(timeout) seconds", file: file, line: line)
        button.tap()
    }
}

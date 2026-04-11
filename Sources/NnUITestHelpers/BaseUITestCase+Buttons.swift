//
//  BaseUITestCase+Buttons.swift
//
//
//  Created by Nikolai Nobadi on 5/22/24.
//

import XCTest

// MARK: - Button Actions
public extension BaseUITestCase {
    func tapAlertSheetButton(_ id: String, timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) {
        tapButton(id, query: app.scrollViews.otherElements.buttons, timeout: timeout, file: file, line: line)
    }

    func tapButton(_ name: String, query: XCUIElementQuery? = nil, timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) {
        waitForElement(query ?? app.buttons, id: name, timeout: timeout, file: file, line: line).tap()
    }

    func tapAlertButton(buttonId: String = "Okay", timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) {
        waitForElement(app.alerts.buttons, id: buttonId, timeout: timeout, file: file, line: line).tap()
    }
}

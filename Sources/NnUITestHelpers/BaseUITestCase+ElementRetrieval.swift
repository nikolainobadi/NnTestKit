//
//  BaseUITestCase+ElementRetrieval.swift
//
//
//  Created by Nikolai Nobadi on 5/22/24.
//

import XCTest

// MARK: - Element Retrieval
public extension BaseUITestCase {
    @discardableResult
    func getRowContainingText(parentViewId: String, text: String, maxScrollAttempts: Int = 3, isRequiredToExist: Bool = false, timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
        let parentView = waitForElement(app.collectionViews, id: parentViewId, timeout: timeout, file: file, line: line)

        return getRowContainingText(parentView: parentView, text: text, maxScrollAttempts: maxScrollAttempts, isRequiredToExist: isRequiredToExist, file: file, line: line)
    }

    @discardableResult
    func getRowContainingText(parentView: XCUIElement? = nil, text: String, maxScrollAttempts: Int = 3, isRequiredToExist: Bool = false, file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
        var currentAttempt = 0
        let parentView = parentView ?? app.collectionViews.firstMatch

        while currentAttempt < maxScrollAttempts {
            let row = parentView.cells.containing(.staticText, identifier: text).element
            if row.exists && row.isHittable {
                while !row.isFullyVisible(in: parentView) {
                    parentView.swipeUp()
                }
                return row
            }
            parentView.swipeUp()
            currentAttempt += 1
        }

        if isRequiredToExist {
            XCTFail("unable to find row with text \(text) after \(maxScrollAttempts) scroll attempts", file: file, line: line)
        }

        return parentView.cells.containing(.staticText, identifier: text).element
    }

    func getRowIndex(_ text: String, parentView: XCUIElement? = nil) -> Int? {
        let parentView = parentView ?? app.collectionViews.firstMatch

        return parentView.cells.allElementsBoundByIndex.firstIndex(where: { $0.staticTexts[text].exists })
    }

    @discardableResult
    func getField(fieldId: String, query: XCUIElementQuery? = nil, isSecure: Bool, _ message: String? = nil, timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
        if isSecure {
            return waitForElement(query ?? app.secureTextFields, id: fieldId, timeout: timeout, message, file: file, line: line)
        }
        return waitForElement(query ?? app.textFields, id: fieldId, timeout: timeout, message, file: file, line: line)
    }
}

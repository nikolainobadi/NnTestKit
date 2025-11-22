//
//  BaseUITestCase+ElementRetrieval.swift
//
//
//  Created by Nikolai Nobadi on 5/22/24.
//

import XCTest

// MARK: - Element Retrieval
public extension BaseUITestCase {
    /// Retrieves a row containing the specified text from a parent view.
    /// - Parameters:
    ///   - parentViewId: The identifier of the parent view.
    ///   - text: The text to search for.
    ///   - maxScrollAttempts: The maximum number of scroll attempts. Default is 3.
    ///   - isRequiredToExist: Whether the row is required to exist. Default is false.
    /// - Returns: The found `XCUIElement`.
    @discardableResult
    func getRowContainingText(parentViewId: String, text: String, maxScrollAttempts: Int = 3, isRequiredToExist: Bool = false, file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
        let parentView = waitForElement(app.collectionViews, id: parentViewId, file: file, line: line)

        return getRowContainingText(parentView: parentView, text: text, maxScrollAttempts: maxScrollAttempts, isRequiredToExist: isRequiredToExist, file: file, line: line)
    }

    /// Retrieves a row containing the specified text from a parent view.
    /// - Parameters:
    ///   - parentView: The parent view to search within. Default is nil.
    ///   - text: The text to search for.
    ///   - maxScrollAttempts: The maximum number of scroll attempts. Default is 3.
    ///   - isRequiredToExist: Whether the row is required to exist. Default is false.
    /// - Returns: The found `XCUIElement`.
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
            XCTFail("unable to find row with text \(text) after \(3) scroll attempts", file: file, line: line)
        }

        return parentView.cells.containing(.staticText, identifier: text).element
    }

    /// Retrieves the index of a row containing the specified text.
    /// - Parameters:
    ///   - text: The text to search for.
    ///   - parentView: The parent view to search within. Default is nil.
    /// - Returns: The index of the row, or nil if not found.
    func getRowIndex(_ text: String, parentView: XCUIElement? = nil) -> Int? {
        let parentView = parentView ?? app.collectionViews.firstMatch

        return parentView.cells.allElementsBoundByIndex.firstIndex(where: { $0.staticTexts[text].exists })
    }

    /// Retrieves a field element with the specified identifier.
    /// - Parameters:
    ///   - fieldId: The identifier of the field.
    ///   - query: The query to use for finding the field. Default is nil.
    ///   - isSecure: Whether the field is a secure text field.
    ///   - message: The error message to use if the field does not appear. Default is nil.
    /// - Returns: The found `XCUIElement`.
    @discardableResult
    func getField(fieldId: String, query: XCUIElementQuery? = nil, isSecure: Bool, _ message: String? = nil, file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
        if isSecure {
            return waitForElement(query ?? app.secureTextFields, id: fieldId, message, file: file, line: line)
        }
        return waitForElement(query ?? app.textFields, id: fieldId, message, file: file, line: line)
    }
}

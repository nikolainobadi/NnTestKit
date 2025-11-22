//
//  BaseUITestCase+Assertions.swift
//
//
//  Created by Nikolai Nobadi on 5/22/24.
//

import XCTest
import NnTestHelpers

// MARK: - Assertion Helpers
public extension BaseUITestCase {
    /// Asserts that an element with the specified identifier does not exist.
    /// - Parameters:
    ///   - query: The query to use for finding the element.
    ///   - id: The identifier of the element.
    ///   - message: The error message to use if the element exists. Default is nil.
    func assertElementIsNil(query: XCUIElementQuery, id: String, _ message: String? = nil, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertFalse(query[id].exists, message ?? "element '\(id)' should not exist", file: file, line: line)
    }

    /// Asserts that the date in a date picker matches the expected date.
    /// - Parameters:
    ///   - datePicker: The date picker element.
    ///   - date: The expected date.
    ///   - message: The error message to use if the dates do not match. Default is nil.
    func assertDateInPicker(_ datePicker: XCUIElement, date: Date, _ message: String? = nil, file: StaticString = #filePath, line: UInt = #line) {
        assertPropertyEquality(datePicker.buttons.firstMatch.value as? String, expectedProperty: date.asDatePickerString(), file: file, line: line)
    }

    /// Asserts that the text in a field matches the expected text.
    /// - Parameters:
    ///   - field: The field element.
    ///   - text: The expected text.
    func assertFieldText(field: XCUIElement, isEqualTo text: String, file: StaticString = #filePath, line: UInt = #line) {
        assertPropertyEquality(field.value as? String, expectedProperty: text, file: file, line: line)
    }

    /// Asserts that a button with the specified identifier is enabled or disabled.
    /// - Parameters:
    ///   - id: The identifier of the button.
    ///   - query: The query to use for finding the button. Default is nil.
    ///   - isEnabled: Whether the button should be enabled.
    func assertButton(id: String, query: XCUIElementQuery? = nil, isEnabled: Bool, file: StaticString = #filePath, line: UInt = #line) {
        let button = waitForElement(query ?? app.buttons, id: id, file: file, line: line)

        if isEnabled {
            XCTAssertTrue(button.isEnabled, "button \(id) should be enabled", file: file, line: line)
        } else {
            XCTAssertFalse(button.isEnabled, "expected button \(id) to be disabled", file: file, line: line)
        }
    }

    /// Asserts the index of a row containing the specified text within sections.
    /// - Parameters:
    ///   - rowText: The text in the row to find.
    ///   - parentView: The parent view containing the row. Default is nil.
    ///   - currentSectionId: The identifier of the current section.
    ///   - nextSectionId: The identifier of the next section. Default is nil.
    func assertRowIndex(rowText: String, parentView: XCUIElement? = nil, currentSectionId: String, nextSectionId: String?, file: StaticString = #filePath, line: UInt = #line) {
        getRowContainingText(parentView: parentView ?? app.collectionViews.firstMatch, text: rowText, isRequiredToExist: true, file: file, line: line)

        guard let rowIndex = getRowIndex(rowText, parentView: parentView) else {
            XCTFail("unable to find index for \(rowText)", file: file, line: line)
            return
        }

        guard let currentSectionIndex = getRowIndex(currentSectionId) else {
            XCTFail("unable to find index for currentSectionId \(currentSectionId)", file: file, line: line)
            return
        }

        XCTAssertTrue(currentSectionIndex < rowIndex, "\(currentSectionIndex) should be less than \(rowIndex)", file: file, line: line)

        if let nextSectionId {
            guard let nextSectionIndex = getRowIndex(nextSectionId) else {
                XCTFail("unable to find index for nextSectionId \(nextSectionId)", file: file, line: line)
                return
            }

            XCTAssertTrue(rowIndex < nextSectionIndex, "\(rowIndex) should be less than \(nextSectionIndex)", file: file, line: line)
        }
    }
}

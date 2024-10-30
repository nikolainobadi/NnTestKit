//
//  BaseUITestCase.swift
//
//
//  Created by Nikolai Nobadi on 5/22/24.
//

import XCTest
import NnTestVariables

open class BaseUITestCase: XCTestCase {
    public let app = XCUIApplication()
    
    open override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchEnvironment[IS_UI_TESTING] = IS_TRUE
    }
}


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


// MARK: - TestData Helpers
public extension BaseUITestCase {
    func makeRandomEmail() -> String {
        return "\(getRandomNumber())tester\(getRandomNumber())\(getRandomNumber())@gmail.com"
    }
    
    func makeRandomUsername() -> String {
        return "tester\(getRandomNumber())\(getRandomNumber())\(getRandomNumber())"
    }
    
    func getRandomNumber() -> Int {
        return Int.random(in: 0...9)
    }
}


// MARK: - UI Element Helpers
public extension BaseUITestCase {
    /// Waits for an element to appear and returns it.
    /// - Parameters:
    ///   - query: The query to use for finding the element.
    ///   - id: The identifier of the element.
    ///   - timeout: The time to wait for the element. Default is 3 seconds.
    ///   - message: The error message to use if the element does not appear. Default is nil.
    /// - Returns: The found `XCUIElement`.
    @discardableResult
    func waitForElement(_ query: XCUIElementQuery, id: String, timeout: TimeInterval = 3, _ message: String? = nil, file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
        let element = query[id]
        
        elementAppeared(query, named: id, timeout: timeout, message, file: file, line: line)
        
        return element
    }
    
    /// Checks if an element appears within a specified timeout.
    /// - Parameters:
    ///   - query: The query to use for finding the element.
    ///   - name: The name of the element.
    ///   - timeout: The time to wait for the element. Default is 3 seconds.
    ///   - message: The error message to use if the element does not appear. Default is nil.
    func elementAppeared(_ query: XCUIElementQuery, named name: String, timeout: TimeInterval = 3, _ message: String? = nil, file: StaticString = #filePath, line: UInt = #line) {
        let element = query[name]
        let existsPredicate = NSPredicate(format: "exists == TRUE")
        let expectation = XCTNSPredicateExpectation(predicate: existsPredicate, object: element)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        
        XCTAssertTrue(result == .completed, message ?? "\(name) should appear within \(timeout) seconds", file: file, line: line)
    }
    
    /// Waits for an element to disappear from the UI.
    /// - Parameters:
    ///   - query: The query to use for finding the element.
    ///   - name: The name of the element.
    ///   - timeout: The time to wait for the element to disappear. Default is 3 seconds.
    ///   - message: The error message to use if the element does not disappear. Default is nil.
    func elementNotAppeared(_ query: XCUIElementQuery, named name: String, timeout: TimeInterval = 2, _ message: String? = nil, file: StaticString = #filePath, line: UInt = #line) {
        let element = query[name]
        let notExistsPredicate = NSPredicate(format: "exists == FALSE")
        let expectation = XCTNSPredicateExpectation(predicate: notExistsPredicate, object: element)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        
        XCTAssertTrue(result == .completed, message ?? "\(name) should not appear within \(timeout) seconds", file: file, line: line)
    }
    
    /// Waits for and dismisses a third-party alert.
    /// - Parameters:
    ///   - description: The description of the alert.
    ///   - button: The button to tap on the alert.
    ///   - withAppTap: Whether to tap the app after handling the alert. Default is false.
    func waitForThirdPartyAlert(decription: String, button: String, withAppTap: Bool = false) {
        addUIInterruptionMonitor(withDescription: description) { (alert) -> Bool in
            if alert.buttons[button].exists {
                alert.buttons[button].tap()
                return true
            }
            return false
        }
        
        if withAppTap {
            app.tap()
        }
    }
    
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

// MARK: - UI Action Helpers
public extension BaseUITestCase {
    /// Selects a date in a date picker.
    /// - Parameters:
    ///   - picker: The date picker element.
    ///   - dayNumberToSelect: The day number to select.
    func selectDate(picker: XCUIElement, dayNumberToSelect: Int) {
        picker.tap()
        app.datePickers.collectionViews.staticTexts["\(dayNumberToSelect)"].tap()
        picker.tap()
    }

    /// Selects a date in a date picker with the specified identifier.
    /// - Parameters:
    ///   - pickerId: The identifier of the date picker.
    ///   - dayNumberToSelect: The day number to select.
    ///   - message: The error message to use if the picker does not appear. Default is nil.
    func selectDate(pickerId: String, dayNumberToSelect: Int, _ message: String? = nil, file: StaticString = #filePath, line: UInt = #line) {
        let picker = waitForElement(app.datePickers, id: pickerId, message, file: file, line: line)
        
        selectDate(picker: picker, dayNumberToSelect: dayNumberToSelect)
    }

    /// Taps a button in an alert sheet with the specified identifier.
    /// - Parameters:
    ///   - id: The identifier of the button.
    func tapAlertSheetButton(_ id: String, file: StaticString = #filePath, line: UInt = #line) {
        tapButton(id, query: app.scrollViews.otherElements.buttons, file: file, line: line)
    }

    /// Taps a button with the specified identifier.
    /// - Parameters:
    ///   - name: The name of the button.
    ///   - query: The query to use for finding the button. Default is nil.
    func tapButton(_ name: String, query: XCUIElementQuery? = nil, file: StaticString = #filePath, line: UInt = #line) {
        waitForElement(query ?? app.buttons, id: name, file: file, line: line).tap()
    }
    
    func tapAlertButton(buttonId: String = "Ok", file: StaticString = #filePath, line: UInt = #line) {
        app.alerts.buttons[buttonId].tap()
    }

    /// Deletes a row with the specified element and swipe button identifier.
    /// - Parameters:
    ///   - row: The row element to delete.
    ///   - swipeButtonId: The identifier of the swipe button. Default is "Delete".
    ///   - withConfirmationAlert: A Boolean value indicating whether a confirmation alert should be handled. Default is false.
    ///   - alertSheetButtonId: The identifier of the alert sheet button, relevant only if withConfirmationAlert is true. Default is nil, which means the swipeButtonId will be used.
    func deleteRow(row: XCUIElement, swipeButtonId: String = "Delete", withConfirmationAlert: Bool = false, alertSheetButtonId: String? = nil, file: StaticString = #filePath, line: UInt = #line) {
        row.swipeLeft()
        tapButton(swipeButtonId, file: file, line: line)
        
        if withConfirmationAlert {
            tapAlertSheetButton(alertSheetButtonId ?? swipeButtonId, file: file, line: line)
        }
    }

    /// Types text into a field with the specified identifier.
    /// - Parameters:
    ///   - fieldId: The identifier of the field.
    ///   - isSecure: Whether the field is a secure text field. Default is false.
    ///   - text: The text to type.
    ///   - clearField: Whether to clear the field before typing. Default is false.
    ///   - tapFieldBeforeTyping: Whether to tap the field before typing. Default is true.
    ///   - tapDoneButton: Whether to tap the submit button on the keyboard after typing. Default is false.
    ///   - submitButtonText: The text of the submit buttton to type. Default is 'Done'.
    func typeInField(fieldId: String, isSecure: Bool = false, text: String, clearField: Bool = false, tapFieldBeforeTyping: Bool = true, tapSubmitButton: Bool = false, submitButtonText: String = "Done", file: StaticString = #filePath, line: UInt = #line) {
        let field = getField(fieldId: fieldId, isSecure: isSecure, file: file, line: line)
        
        typeInField(field: field, text: text, clearField: clearField, tapFieldBeforeTypIng: tapFieldBeforeTyping, tapSubmitButon: tapSubmitButton, submitButtonText: submitButtonText, file: file, line: line)
    }
    
    /// Types text into an alert's text field at the specified index.
    /// - Parameters:
    ///   - fieldIndex: The index of the text field in the alert. Default is 0.
    ///   - text: The text to type.
    ///   - clearField: Whether to clear the field before typing. Default is false.
    ///   - tapFieldBeforeTyping: Whether to tap the field before typing. Default is true.
    ///   - tapSubmitButton: Whether to tap the submit button on the keyboard after typing. Default is false.
    ///   - submitButtonText: The text of the submit button. Default is "Done".
    func typeInAlertField(fieldIndex: Int = 0, text: String, clearField: Bool = false, tapFieldBeforeTyping: Bool = true, tapSubmitButton: Bool = false, submitButtonText: String = "Done", file: StaticString = #filePath, line: UInt = #line) {
        
        let field = app.alerts.textFields.element(boundBy: fieldIndex)
        
        typeInField(field: field, text: text, clearField: clearField, tapFieldBeforeTypIng: tapFieldBeforeTyping, tapSubmitButon: tapSubmitButton, submitButtonText: submitButtonText, file: file, line: line)
    }
    
    /// Types text into a specified field element.
    /// - Parameters:
    ///   - field: The field element to type into.
    ///   - text: The text to type.
    ///   - clearField: Whether to clear the field before typing. Default is false.
    ///   - tapFieldBeforeTypIng: Whether to tap the field before typing. Default is true.
    ///   - tapSubmitButon: Whether to tap the submit button on the keyboard after typing. Default is false.
    ///   - submitButtonText: The text of the submit button. Default is "Done".
    func typeInField(field: XCUIElement, text: String, clearField: Bool = false, tapFieldBeforeTypIng: Bool = true, tapSubmitButon: Bool = false, submitButtonText: String = "Done", file: StaticString = #filePath, line: UInt = #line) {
        
        if tapFieldBeforeTypIng {
            field.tap()
        }
        
        if clearField {
            if let stringValue = field.value as? String, !stringValue.isEmpty {
                let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
                field.typeText(deleteString)
            }
        }
        
        field.typeText(text)
        
        if tapSubmitButon {
            waitForElement(app.keyboards.buttons, id: submitButtonText, file: file, line: line).tap()
        }
    }

    /// Taps a button in a segmented control.
    /// - Parameters:
    ///   - pickerId: The identifier of the segmented control.
    ///   - query: The query to use for finding the segmented control. Default is nil.
    ///   - buttonId: The identifier of the button to tap.
    func tapSegmentedControl(pickerId: String, query: XCUIElementQuery? = nil, buttonId: String, file: StaticString = #filePath, line: UInt = #line) {
        let picker = waitForElement(query ?? app.segmentedControls, id: pickerId, file: file, line: line)
        
        picker.buttons[buttonId].tap()
    }
}

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

// MARK: - Extension Dependencies
public extension XCUIElement {
    /// Checks if the element is fully visible within the parent view.
    /// - Parameter parentView: The parent view to check against.
    /// - Returns: `true` if the element is fully visible, otherwise `false`.
    func isFullyVisible(in parentView: XCUIElement) -> Bool {
        let parentFrame = parentView.frame
        let elementFrame = self.frame
        
        return parentFrame.contains(elementFrame)
    }
}

#if canImport(UIKit)
public extension BaseUITestCase {
    /// Selects a date in a date picker, adjusting the month if necessary.
    /// - Parameters:
    ///   - pickerId: The identifier of the date picker.
    ///   - currentMonth: The current month in the picker. Default is nil.
    ///   - currentYear: The current year in the picker. Default is nil.
    ///   - newMonth: The new month to select. Default is nil.
    ///   - newDay: The day to select.
    func selectDate(pickerId: String, currentMonth: String? = nil, currentYear: Int? = nil, newMonth: String? = nil, newDay: Int, file: StaticString = #filePath, line: UInt = #line) {
        let picker = waitForElement(app.datePickers, id: pickerId, file: file, line: line)
        
        picker.tap()
        
        if let currentMonth, let currentYear, let newMonth {
            tapDatePickerMonthButton(month: currentMonth, year: currentYear, file: file, line: line)
            app.datePickers.pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: newMonth)
            tapDatePickerMonthButton(month: newMonth, year: currentYear, file: file, line: line)
        }
        
        app.datePickers.staticTexts["\(newDay)"].tap()
        picker.tap()
    }

    /// Taps a month button in a date picker.
    /// - Parameters:
    ///   - month: The month to select.
    ///   - year: The year to select.
    private func tapDatePickerMonthButton(month: String, year: Int, file: StaticString = #filePath, line: UInt = #line) {
        waitForElement(app.datePickers.staticTexts, id: "\(month) \(year)", file: file, line: line).tap()
    }
}
#endif

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
    func addKeyToENV(_ key: String, value: String = IS_TRUE) {
        app.launchEnvironment[key] = value
    }
}


// MARK: - UI Element Helpers
public extension BaseUITestCase {
    @discardableResult
    func waitForElement(_ query: XCUIElementQuery, id: String, timeout: TimeInterval = 3, _ message: String? = nil, file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
        let element = query[id]
        
        elementAppeared(query, named: id, timeout: timeout, message, file: file, line: line)
        
        return element
    }
    
    func elementAppeared(_ query: XCUIElementQuery, named name: String, timeout: TimeInterval = 3, _ message: String? = nil, file: StaticString = #filePath, line: UInt = #line) {
        let element = query[name]
        let existsPredicate = NSPredicate(format: "exists == TRUE")
        let expectation = XCTNSPredicateExpectation(predicate: existsPredicate, object: element)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        
        XCTAssertTrue(result == .completed, message ?? "\(name) should appear withing \(timeout) seconds", file: file, line: line)
    }
    
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
    
    @discardableResult
    func getRowContainingText(parentViewId: String, text: String, maxScrollAttempts: Int = 3, isRequiredToExist: Bool = false, file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
        let parentView = waitForElement(app.collectionViews, id: parentViewId, file: file, line: line)
        
        return getRowContainingText(parentView: parentView, text: text, maxScrollAttempts: maxScrollAttempts, isRequiredToExist: isRequiredToExist, file: file, line: line)
    }
    
    @discardableResult
    func getRowContainingText(parentView: XCUIElement? = nil, text: String, maxScrollAttempts: Int = 3, isRequiredToExist: Bool = false, file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
        var currentAttempt = 0
        let parentView = parentView ?? app.collectionViews.firstMatch
        while currentAttempt < maxScrollAttempts {
            let row = parentView.cells.containing(.staticText, identifier: text).element
            
            if row.exists && row.isHittable {
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
    
    func getRowIndex(_ text: String, parentView: XCUIElement? = nil) -> Int? {
        let parentView = parentView ?? app.collectionViews.firstMatch
        
        return parentView.cells.allElementsBoundByIndex.firstIndex(where: { $0.staticTexts[text].exists })
    }

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
    func selectDate(picker: XCUIElement, dayNumberToSelect: Int) {
        picker.tap()
        app.datePickers.collectionViews.staticTexts["\(dayNumberToSelect)"].tap()
        picker.tap()
    }
    
    func selectDate(pickerId: String, dayNumberToSelect: Int, _ message: String? = nil, file: StaticString = #filePath, line: UInt = #line) {
        let picker = waitForElement(app.datePickers, id: pickerId, message, file: file, line: line)
        
        selectDate(picker: picker, dayNumberToSelect: dayNumberToSelect)
    }
    
    func tapAlertSheetButton(_ id: String, file: StaticString = #filePath, line: UInt = #line) {
        tapButton(id, query: app.scrollViews.otherElements.buttons, file: file, line: line)
    }
    
    func tapButton(_ name: String, query: XCUIElementQuery? = nil, file: StaticString = #filePath, line: UInt = #line) {
        waitForElement(query ?? app.buttons, id: name, file: file, line: line).tap()
    }
    
    func deleteRow(row: XCUIElement, swipeButtonId: String = "Delete", alertSheetButtonId: String? = nil, file: StaticString = #filePath, line: UInt = #line) {
        row.swipeLeft()
        tapButton(swipeButtonId, file: file, line: line)
        tapAlertSheetButton(alertSheetButtonId ?? swipeButtonId, file: file, line: line)
    }
    
    func deleteRow(rowText: String, parentView: XCUIElement? = nil, swipeButtonId: String = "Delete", alertSheetButtonId: String? = nil, file: StaticString = #filePath, line: UInt = #line) {
        let row = getRowContainingText(parentView: parentView, text: rowText, file: file, line: line)
        
        deleteRow(row: row, swipeButtonId: swipeButtonId, alertSheetButtonId: alertSheetButtonId, file: file, line: line)
    }
    
    func typeInField(fieldId: String, isSecure: Bool = false, text: String, clearField: Bool = false, file: StaticString = #filePath, line: UInt = #line) {
        let field = getField(fieldId: fieldId, isSecure: isSecure, file: file, line: line)
        field.tap()
        
        if clearField {
            if let stringValue = field.value as? String, !stringValue.isEmpty {
                let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
                field.typeText(deleteString)
            }
        }
        
        field.typeText(text)
    }
    
    func tapSegmentedControl(pickerId: String, query: XCUIElementQuery? = nil, buttonId: String, file: StaticString = #filePath, line: UInt = #line) {
        let picker = waitForElement(query ?? app.segmentedControls, id: pickerId, file: file, line: line)
        
        picker.buttons[buttonId].tap()
    }
}


// MARK: - Assertion Helpers
public extension BaseUITestCase {
    func assertElementIsNil(query: XCUIElementQuery, id: String, _ message: String? = nil, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertFalse(query[id].exists, message ?? "element '\(id)' should not exist", file: file, line: line)
    }
    
    func assertDateInPicker(_ datePicker: XCUIElement, date: Date, _ message: String? = nil, file: StaticString = #filePath, line: UInt = #line) {
        
        assertPropertyEquality(datePicker.buttons.firstMatch.value as? String, expectedProperty: date.asDatePickerString())
    }
    
    func assertFieldText(field: XCUIElement, isEqualTo text: String, file: StaticString = #filePath, line: UInt = #line) {
        assertPropertyEquality(field.value as? String, expectedProperty: text, file: file, line: line)
    }
    
    func assertButton(id: String, query: XCUIElementQuery? = nil, isEnabled: Bool, file: StaticString = #filePath, line: UInt = #line) {
        let button = waitForElement(query ?? app.buttons, id: id, file: file, line: line)
        
        if isEnabled {
            XCTAssertTrue(button.isEnabled, "button \(id) should be enabled", file: file, line: line)
        } else {
            XCTAssertFalse(button.isEnabled, "expected button \(id) to be disabled", file: file, line: line)
        }
    }
        
    func assertRowIndex(rowText: String, parentView: XCUIElement? = nil, currentSectionId: String, nextSectionId: String?, file: StaticString = #filePath, line: UInt = #line) {
        // scroll to find row
        getRowContainingText(parentView: parentView ?? app.collectionViews.firstMatch, text: rowText, isRequiredToExist: true)
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

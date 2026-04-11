//
//  BaseUITestCase+DatePicker.swift
//
//
//  Created by Nikolai Nobadi on 5/22/24.
//

import XCTest
import NnTestHelpers

// MARK: - Date Picker Actions
public extension BaseUITestCase {
    func selectDate(picker: XCUIElement, dayNumberToSelect: Int) {
        picker.tap()
        app.datePickers.collectionViews.staticTexts["\(dayNumberToSelect)"].tap()
        picker.tap()
    }

    func selectDate(pickerId: String, dayNumberToSelect: Int, _ message: String? = nil, timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) {
        let picker = waitForElement(app.datePickers, id: pickerId, timeout: timeout, message, file: file, line: line)

        selectDate(picker: picker, dayNumberToSelect: dayNumberToSelect)
    }

#if canImport(UIKit)
    func selectDate(pickerId: String, currentMonth: String? = nil, currentYear: Int? = nil, newMonth: String? = nil, newDay: Int, timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) {
        let picker = waitForElement(app.datePickers, id: pickerId, timeout: timeout, file: file, line: line)

        picker.tap()

        if let currentMonth, let currentYear, let newMonth {
            tapDatePickerMonthButton(month: currentMonth, year: currentYear, timeout: timeout, file: file, line: line)
            app.datePickers.pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: newMonth)
            tapDatePickerMonthButton(month: newMonth, year: currentYear, timeout: timeout, file: file, line: line)
        }

        app.datePickers.staticTexts["\(newDay)"].tap()
        picker.tap()
    }

    private func tapDatePickerMonthButton(month: String, year: Int, timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) {
        waitForElement(app.datePickers.staticTexts, id: "\(month) \(year)", timeout: timeout, file: file, line: line).tap()
    }
#endif
}

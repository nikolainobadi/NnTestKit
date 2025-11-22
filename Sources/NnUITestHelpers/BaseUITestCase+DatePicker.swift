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

#if canImport(UIKit)
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
#endif
}

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

    /// Adjusts a compact-style `DatePicker` with `displayedComponents: .hourAndMinute`
    /// by tapping it open, setting its hour/minute (and optional AM/PM period)
    /// wheels, then tapping it again to dismiss the inline overlay.
    ///
    /// - Parameters:
    ///   - pickerId: Accessibility identifier of the `DatePicker`.
    ///   - hour: Hour wheel value (e.g. `"9"`). Locale-dependent — 12h locales
    ///     expect 1–12, 24h locales expect 0–23.
    ///   - minute: Minute wheel value (e.g. `"30"`).
    ///   - period: AM/PM wheel value when running under a 12-hour locale; pass
    ///     `nil` under 24-hour locales.
    ///   - timeout: Optional override for the picker-lookup timeout.
    func selectTime(pickerId: String, hour: String, minute: String, period: String? = nil, timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) {
        let picker = waitForElement(app.datePickers, id: pickerId, timeout: timeout, file: file, line: line)
        picker.tap()

        let wheels = app.pickerWheels
        wheels.element(boundBy: 0).adjust(toPickerWheelValue: hour)
        wheels.element(boundBy: 1).adjust(toPickerWheelValue: minute)

        if let period {
            wheels.element(boundBy: 2).adjust(toPickerWheelValue: period)
        }

        picker.tap()
    }
#endif
}

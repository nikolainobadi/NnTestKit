//
//  BaseUITestCase+Controls.swift
//
//
//  Created by Nikolai Nobadi on 5/22/24.
//

import XCTest

// MARK: - Control Actions
public extension BaseUITestCase {
    /// Taps a button in a segmented control.
    /// - Parameters:
    ///   - pickerId: The identifier of the segmented control.
    ///   - query: The query to use for finding the segmented control. Default is nil.
    ///   - buttonId: The identifier of the button to tap.
    func tapSegmentedControl(pickerId: String, query: XCUIElementQuery? = nil, buttonId: String, file: StaticString = #filePath, line: UInt = #line) {
        let picker = waitForElement(query ?? app.segmentedControls, id: pickerId, file: file, line: line)

        picker.buttons[buttonId].tap()
    }

    /// Adjusts the value of a stepper control by either incrementing or decrementing it a specified number of times.
    /// - Parameters:
    ///   - id: The identifier for the stepper control to interact with.
    ///   - isIncrementing: A Boolean indicating whether to increment (`true`) or decrement (`false`) the stepper value.
    ///   - count: The number of times to tap the stepper button. Default is 1.
    func adjustStepper(id: String, isIncrementing: Bool, count: Int = 1, file: StaticString = #filePath, line: UInt = #line) {
        let stepper = waitForElement(app.steppers, id: id, file: file, line: line)
        let buttonId = "\(id)-\(isIncrementing ? "Increment" : "Decrement")"

        for _ in 0..<count {
            stepper.buttons[buttonId].tap()
        }
    }
}

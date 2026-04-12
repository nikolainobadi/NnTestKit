//
//  BaseUITestCase+Controls.swift
//
//
//  Created by Nikolai Nobadi on 5/22/24.
//

import XCTest

// MARK: - Control Actions
public extension BaseUITestCase {
    func tapToggle(_ id: String, timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) {
        tapCenter(of: waitForElement(app.switches, id: id, timeout: timeout, file: file, line: line))
    }

    func tapSegmentedControl(pickerId: String, query: XCUIElementQuery? = nil, buttonId: String, timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) {
        let picker = waitForElement(query ?? app.segmentedControls, id: pickerId, timeout: timeout, file: file, line: line)

        picker.buttons[buttonId].tap()
    }

    func adjustStepper(id: String, isIncrementing: Bool, count: Int = 1, timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) {
        let stepper = waitForElement(app.steppers, id: id, timeout: timeout, file: file, line: line)
        let buttonId = "\(id)-\(isIncrementing ? "Increment" : "Decrement")"

        for _ in 0..<count {
            stepper.buttons[buttonId].tap()
        }
    }
}

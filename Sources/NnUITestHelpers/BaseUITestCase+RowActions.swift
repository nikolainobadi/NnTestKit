//
//  BaseUITestCase+RowActions.swift
//
//
//  Created by Nikolai Nobadi on 5/22/24.
//

import XCTest

// MARK: - Row Actions
public extension BaseUITestCase {
    /// Deletes a row with the specified element and swipe button identifier.
    /// - Parameters:
    ///   - row: The row element to delete.
    ///   - swipeButtonId: The identifier of the swipe button. Default is "Delete".
    ///   - withConfirmationAlert: A Boolean value indicating whether a confirmation alert should be handled. Default is false.
    ///   - alertSheetButtonId: The identifier of the alert sheet button, relevant only if withConfirmationAlert is true. Default is nil, which means the swipeButtonId will be used.
    ///   - timeout: The time to wait for button elements. Defaults to `UITestSeedDefaults.timeout` when nil.
    func deleteRow(row: XCUIElement, swipeButtonId: String = "Delete", withConfirmationAlert: Bool = false, alertSheetButtonId: String? = nil, timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) {
        row.swipeLeft()
        tapButton(swipeButtonId, timeout: timeout, file: file, line: line)

        if withConfirmationAlert {
            tapAlertSheetButton(alertSheetButtonId ?? swipeButtonId, timeout: timeout, file: file, line: line)
        }
    }
}

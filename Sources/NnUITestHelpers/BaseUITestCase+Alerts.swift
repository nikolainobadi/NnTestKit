//
//  BaseUITestCase+Alerts.swift
//
//
//  Created by Nikolai Nobadi on 5/22/24.
//

import XCTest

// MARK: - Alert Handling
public extension BaseUITestCase {
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
}

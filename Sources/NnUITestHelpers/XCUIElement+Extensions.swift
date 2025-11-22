//
//  XCUIElement+Extensions.swift
//
//
//  Created by Nikolai Nobadi on 5/22/24.
//

import XCTest

// MARK: - XCUIElement Extensions
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

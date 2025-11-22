//
//  BaseUITestCase+ElementInteraction.swift
//
//
//  Created by Nikolai Nobadi on 5/22/24.
//

import XCTest

// MARK: - Element Interaction
public extension BaseUITestCase {
    /// Taps the center of an element with adjustable offset.
    /// - Parameters:
    ///   - element: The element to tap.
    ///   - dx: The horizontal offset. Default is 0.8.
    ///   - dy: The vertical offset. Default is 0.5.
    func tapCenter(of element: XCUIElement, dx: CGFloat = 0.8, dy: CGFloat = 0.5) {
        let coord = element.coordinate(withNormalizedOffset: CGVector(dx: dx, dy: dy))
        coord.tap()
    }
}

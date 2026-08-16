//
//  BaseUITestCase+ElementWaiting.swift
//
//
//  Created by Nikolai Nobadi on 5/22/24.
//

import XCTest
import NnTestVariables

// MARK: - Element Waiting & Visibility
public extension BaseUITestCase {
    /// Waits for an element to appear and returns it.
    /// - Parameters:
    ///   - query: The query to use for finding the element.
    ///   - id: The identifier of the element.
    ///   - timeout: The time to wait for the element. Defaults to `UITestSeedDefaults.timeout` when nil.
    ///   - message: The error message to use if the element does not appear. Default is nil.
    /// - Returns: The found `XCUIElement`.
    @discardableResult
    func waitForElement(_ query: XCUIElementQuery, id: String, timeout: TimeInterval? = nil, _ message: String? = nil, file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
        let element = query[id]

        elementAppeared(query, named: id, timeout: timeout ?? UITestSeedDefaults.timeout, message, file: file, line: line)

        return element
    }

    /// Checks if an element appears within a specified timeout.
    /// - Parameters:
    ///   - query: The query to use for finding the element.
    ///   - name: The name of the element.
    ///   - timeout: The time to wait for the element. Defaults to `UITestSeedDefaults.timeout` when nil.
    ///   - message: The error message to use if the element does not appear. Default is nil.
    func elementAppeared(_ query: XCUIElementQuery, named name: String, timeout: TimeInterval? = nil, _ message: String? = nil, file: StaticString = #filePath, line: UInt = #line) {
        let timeout = timeout ?? UITestSeedDefaults.timeout
        let element = query[name]
        let existsPredicate = NSPredicate(format: "exists == TRUE")
        let expectation = XCTNSPredicateExpectation(predicate: existsPredicate, object: element)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)

        XCTAssertTrue(result == .completed, message ?? "\(name) should appear within \(timeout) seconds", file: file, line: line)
    }

    /// Waits for an element to disappear from the UI.
    /// - Parameters:
    ///   - query: The query to use for finding the element.
    ///   - name: The name of the element.
    ///   - timeout: The time to wait for the element to disappear. Defaults to `UITestSeedDefaults.timeout` when nil.
    ///   - message: The error message to use if the element does not disappear. Default is nil.
    func elementNotAppeared(_ query: XCUIElementQuery, named name: String, timeout: TimeInterval? = nil, _ message: String? = nil, file: StaticString = #filePath, line: UInt = #line) {
        let timeout = timeout ?? UITestSeedDefaults.timeout
        let element = query[name]
        let notExistsPredicate = NSPredicate(format: "exists == FALSE")
        let expectation = XCTNSPredicateExpectation(predicate: notExistsPredicate, object: element)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)

        XCTAssertTrue(result == .completed, message ?? "\(name) should not appear within \(timeout) seconds", file: file, line: line)
    }
}

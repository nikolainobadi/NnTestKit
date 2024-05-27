//
//  BaseUITestCase.swift
//
//
//  Created by Nikolai Nobadi on 5/22/24.
//

import XCTest
import NnTestVariables

open class BaseUITestCase: XCTestCase {
    public let app = XCUIApplication()
    
    open override func setUpWithError() throws {
        continueAfterFailure = false
        app.launchEnvironment[IS_UI_TESTING] = IS_TRUE
    }
}


// MARK: - Setup Helpers
public extension BaseUITestCase {
    func addKeyToENV(_ key: String, value: String = IS_TRUE) {
        app.launchEnvironment[key] = value
    }
}


// MARK: - UI Element Helpers
public extension BaseUITestCase {
    @discardableResult
    func waitForElement(_ query: XCUIElementQuery, named name: String, timeout: TimeInterval = 3, file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
        let element = query[name]
        
        elementAppeared(query, named: name, timeout: timeout, file: file, line: line)
        
        return element
    }
    
    func elementAppeared(_ query: XCUIElementQuery, named name: String, timeout: TimeInterval = 3, file: StaticString = #filePath, line: UInt = #line) {
        let element = query[name]
        let existsPredicate = NSPredicate(format: "exists == TRUE")
        let expectation = XCTNSPredicateExpectation(predicate: existsPredicate, object: element)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        
        XCTAssertTrue(result == .completed, "\(name) should appear withing \(timeout) seconds", file: file, line: line)
    }
    
    func waitForThirdPartyAlert(app: XCUIApplication, decription: String, button: String) {
        addUIInterruptionMonitor(withDescription: description) { (alert) -> Bool in
            if alert.buttons[button].exists {
                alert.buttons[button].tap()
                return true
            }
            return false
        }
        
        app.tap()
    }
    
    func typeInField(app: XCUIApplication, fieldId: String, isSecure: Bool = false, text: String, clearField: Bool = false) {
        let field = getField(app: app, fieldId: fieldId, isSecure: isSecure)
        field.tap()
        
        if clearField {
            field.press(forDuration: 1.2)
            waitForElement(app.menuItems, named: "Select All").tap()
            field.typeText(XCUIKeyboardKey.delete.rawValue)
        }
        
        field.typeText(text)
    }
    
    @discardableResult
    func getField(app: XCUIApplication, fieldId: String, isSecure: Bool) -> XCUIElement {
        if isSecure {
            return waitForElement(app.secureTextFields, named: fieldId)
        } else {
            return waitForElement(app.textFields, named: fieldId)
        }
    }
}

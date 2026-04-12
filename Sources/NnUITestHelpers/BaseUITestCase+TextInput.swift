//
//  BaseUITestCase+TextInput.swift
//
//
//  Created by Nikolai Nobadi on 5/22/24.
//

import XCTest

// MARK: - Text Input Actions
public extension BaseUITestCase {
    func typeInField(fieldId: String, isSecure: Bool = false, text: String, clearField: Bool = false, tapFieldBeforeTyping: Bool = true, tapSubmitButton: Bool = false, submitButtonText: String = "Done", timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) {
        let field = getField(fieldId: fieldId, isSecure: isSecure, timeout: timeout, file: file, line: line)

        typeInField(field: field, text: text, clearField: clearField, tapFieldBeforeTypIng: tapFieldBeforeTyping, tapSubmitButon: tapSubmitButton, submitButtonText: submitButtonText, timeout: timeout, file: file, line: line)
    }

    func typeInAlertField(fieldIndex: Int = 0, text: String, clearField: Bool = false, tapFieldBeforeTyping: Bool = true, tapSubmitButton: Bool = false, submitButtonText: String = "Done", timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) {

        let field = app.alerts.textFields.element(boundBy: fieldIndex)

        typeInField(field: field, text: text, clearField: clearField, tapFieldBeforeTypIng: tapFieldBeforeTyping, tapSubmitButon: tapSubmitButton, submitButtonText: submitButtonText, timeout: timeout, file: file, line: line)
    }

    func typeInField(field: XCUIElement, text: String, clearField: Bool = false, tapFieldBeforeTypIng: Bool = true, tapSubmitButon: Bool = false, submitButtonText: String = "Done", timeout: TimeInterval? = nil, file: StaticString = #filePath, line: UInt = #line) {

        if tapFieldBeforeTypIng {
            field.tap()
        }

        if clearField {
            if let stringValue = field.value as? String, !stringValue.isEmpty {
                let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
                field.typeText(deleteString)
            }
        }

        field.typeText(text)

        if tapSubmitButon {
            waitForElement(app.keyboards.buttons, id: submitButtonText, timeout: timeout, file: file, line: line).tap()
        }
    }
}

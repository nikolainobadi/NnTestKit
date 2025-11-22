//
//  BaseUITestCase+TextInput.swift
//
//
//  Created by Nikolai Nobadi on 5/22/24.
//

import XCTest

// MARK: - Text Input Actions
public extension BaseUITestCase {
    /// Types text into a field with the specified identifier.
    /// - Parameters:
    ///   - fieldId: The identifier of the field.
    ///   - isSecure: Whether the field is a secure text field. Default is false.
    ///   - text: The text to type.
    ///   - clearField: Whether to clear the field before typing. Default is false.
    ///   - tapFieldBeforeTyping: Whether to tap the field before typing. Default is true.
    ///   - tapDoneButton: Whether to tap the submit button on the keyboard after typing. Default is false.
    ///   - submitButtonText: The text of the submit buttton to type. Default is 'Done'.
    func typeInField(fieldId: String, isSecure: Bool = false, text: String, clearField: Bool = false, tapFieldBeforeTyping: Bool = true, tapSubmitButton: Bool = false, submitButtonText: String = "Done", file: StaticString = #filePath, line: UInt = #line) {
        let field = getField(fieldId: fieldId, isSecure: isSecure, file: file, line: line)

        typeInField(field: field, text: text, clearField: clearField, tapFieldBeforeTypIng: tapFieldBeforeTyping, tapSubmitButon: tapSubmitButton, submitButtonText: submitButtonText, file: file, line: line)
    }

    /// Types text into an alert's text field at the specified index.
    /// - Parameters:
    ///   - fieldIndex: The index of the text field in the alert. Default is 0.
    ///   - text: The text to type.
    ///   - clearField: Whether to clear the field before typing. Default is false.
    ///   - tapFieldBeforeTyping: Whether to tap the field before typing. Default is true.
    ///   - tapSubmitButton: Whether to tap the submit button on the keyboard after typing. Default is false.
    ///   - submitButtonText: The text of the submit button. Default is "Done".
    func typeInAlertField(fieldIndex: Int = 0, text: String, clearField: Bool = false, tapFieldBeforeTyping: Bool = true, tapSubmitButton: Bool = false, submitButtonText: String = "Done", file: StaticString = #filePath, line: UInt = #line) {

        let field = app.alerts.textFields.element(boundBy: fieldIndex)

        typeInField(field: field, text: text, clearField: clearField, tapFieldBeforeTypIng: tapFieldBeforeTyping, tapSubmitButon: tapSubmitButton, submitButtonText: submitButtonText, file: file, line: line)
    }

    /// Types text into a specified field element.
    /// - Parameters:
    ///   - field: The field element to type into.
    ///   - text: The text to type.
    ///   - clearField: Whether to clear the field before typing. Default is false.
    ///   - tapFieldBeforeTypIng: Whether to tap the field before typing. Default is true.
    ///   - tapSubmitButon: Whether to tap the submit button on the keyboard after typing. Default is false.
    ///   - submitButtonText: The text of the submit button. Default is "Done".
    func typeInField(field: XCUIElement, text: String, clearField: Bool = false, tapFieldBeforeTypIng: Bool = true, tapSubmitButon: Bool = false, submitButtonText: String = "Done", file: StaticString = #filePath, line: UInt = #line) {

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
            waitForElement(app.keyboards.buttons, id: submitButtonText, file: file, line: line).tap()
        }
    }
}

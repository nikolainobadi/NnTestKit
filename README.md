
# NnTestKit

[![Swift Version](https://img.shields.io/badge/Swift-5.10%2B-orange.svg)](https://swift.org)
![Platform](https://badgen.net/badge/platform/iOS%2015%2B%20%7C%20macOS%2012%2B/blue)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

NnTestKit is a Swift package that provides a collection of helper methods to simplify unit and UI testing in your iOS projects. It extends XCTest and Swift Testing frameworks to offer more convenient and powerful assertion methods, memory leak tracking with modern Swift macros, and UI testing utilities.

NOTE: All test helper methods are located in the NnTestHelpers library, which should only be included as a dependency in test targets. NnTestVariables is a much smaller library and only contains a few properties and extensions to assist with testing. The NnSwiftTestingHelpers and NnTestKitMacros libraries provide Swift Testing framework support with modern macro-based memory leak detection.

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
  - [Swift Testing Framework – Memory Leak Tracking](#swift-testing-framework--memory-leak-tracking)
    - [@LeakTracked Macro (Recommended)](#leaktracked-macro-recommended)
    - [TrackingMemoryLeaks Class (Legacy)](#trackingmemoryleaks-class-legacy)
  - [XCTestCase Extensions](#xctestcase-extensions)
    - [Memory Leak Tracking](#memory-leak-tracking)
    - [Property Assertions](#property-assertions)
  - [BaseUITestCase (UI Test Helpers)](#baseuittestcase)
    - [Setup Helpers](#setup-helpers)
    - [UI Element Helpers](#ui-element-helpers)
    - [UI Action Helpers](#ui-action-helpers)
- [Swift 6 Compatibility](#swift-6-compatibility)
- [Contributing](#contributing)
- [License](#license)

## Features
- Memory leak tracking with modern `@LeakTracked` macro (Swift 5.10+)
- Property and array assertions
- Error handling assertions (sync and async)
- Swift Testing framework support
- UI test case setup and helper methods
- Swift 6 concurrency compatibility

## Installation

To add `NnTestKit` to your Xcode project, add the following dependency to your `Package.swift` file:

```swift
.package(url: "https://github.com/nikolainobadi/NnTestKit", from: "1.4.0")
```

Then, add `NnTestKit` to your target dependencies:

```swift
dependencies: [
    .product(name: "NnTestHelpers", package: "NnTestKit"),
    .product(name: "NnTestVariables", package: "NnTestKit"),
    .product(name: "NnSwiftTestingHelpers", package: "NnTestKit")
]
```
## Usage

### Swift Testing Framework – Memory Leak Tracking

#### @LeakTracked Macro (Recommended)

For Swift 5.10+, use the modern `@LeakTracked` macro for memory leak detection without inheritance:

**Important Requirements:**
- The test suite **must be a class** (not a struct) as the macro injects a `deinit` method
- Import both `Testing` and `NnSwiftTestingHelpers` in your test file
- Most useful when testing **class instances** that need deallocation tracking
- Reference types (classes) are tracked; value types (structs) don't need leak tracking

**Basic Usage:**

```swift
import Testing
import NnSwiftTestingHelpers
@testable import MyModule

@LeakTracked
final class MyTestSuite {  // Must be a class, not a struct
    @Test("MyClass deallocates properly")
    func test_memoryLeakDetected() {
        let sut = makeSUT()
        // Test operations...
    }

    private func makeSUT(fileID: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column) -> MyClass {
        let service = MyService()  // Assuming MyService is a class
        let sut = MyClass(service: service)  // Assuming MyClass is a class
        trackForMemoryLeaks(service, fileID: fileID, filePath: filePath, line: line, column: column)
        trackForMemoryLeaks(sut, fileID: fileID, filePath: filePath, line: line, column: column)
        return sut
    }
}
```

**Behavior Modes:**

The macro supports three leak detection behaviors that can be specified when calling `trackForMemoryLeaks`:

- **`.failIfLeaked` (Default)** - Fails the test if a tracked object is not deallocated
- **`.warnIfLeaked`** - Logs a warning but doesn't fail the test
- **`.expectLeak`** - Fails if the object IS deallocated (useful for testing retain cycles)

```swift
private func makeSUT(fileID: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column) -> MyClass {
    let service = MyService()
    let sut = MyClass(service: service)

    // Default: fails on leak
    trackForMemoryLeaks(sut, fileID: fileID, filePath: filePath, line: line, column: column)

    // Warn only (doesn't fail test)
    trackForMemoryLeaks(service, behavior: .warnIfLeaked, fileID: fileID, filePath: filePath, line: line, column: column)

    // Expect the object to leak (fails if it deallocates)
    // trackForMemoryLeaks(sut, behavior: .expectLeak, fileID: fileID, filePath: filePath, line: line, column: column)

    return sut
}
```

**Tracking Multiple Objects:**

```swift
@LeakTracked
final class ViewModelTests {
    @Test("ViewModel and dependencies deallocate properly")
    func test_viewModelLifecycle() {
        let sut = makeSUT()
        // Test operations...
    }

    private func makeSUT(fileID: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column) -> ViewModel {
        let service = MockService()
        let repository = MockRepository()
        let sut = ViewModel(service: service, repository: repository)

        // Track all objects that should be deallocated
        trackForMemoryLeaks(service, fileID: fileID, filePath: filePath, line: line, column: column)
        trackForMemoryLeaks(repository, fileID: fileID, filePath: filePath, line: line, column: column)
        trackForMemoryLeaks(sut, fileID: fileID, filePath: filePath, line: line, column: column)

        return sut
    }
}
```

#### TrackingMemoryLeaks Class (Legacy)

**Deprecated**: For users still using the legacy approach, `NnTestKit` includes a `TrackingMemoryLeaks` class:

```swift
import Testing
import NnSwiftTestingHelpers
@testable import MyModule

final class MyClassSwiftTesting: TrackingMemoryLeaks {
    @Test("MyClass deallocates properly")
    func test_memoryLeakDetected() {
        let sut = makeSUT()
        // Test operations...
    }

    private func makeSUT(fileID: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column) -> MyClass {
        let service = MyService()
        let sut = MyClass(service: service)
        trackForMemoryLeaks(service, fileID: fileID, filePath: filePath, line: line, column: column)
        trackForMemoryLeaks(sut, fileID: fileID, filePath: filePath, line: line, column: column)
        return sut
    }
}
```

> Note: The `@LeakTracked` macro provides better Swift 6 concurrency support and eliminates the need for inheritance.

### XCTestCase Extensions

NnTestKit extends `XCTestCase` with several useful methods:

#### Memory Leak Tracking
Prevent memory leaks before they infect your code by passing the object you want to track into this method before running your unit tests. This method ensures the object in question is dellocated by the end of the test eles the test will fail.
```swift
import XCTest
import NnTestHelpers

final class MyTests: XCTestCase {
    func testMemoryLeak() {
        let instance = MyClass()
        trackForMemoryLeaks(instance)
        // Your test code here
    }
}
```

#### Property Assertions

##### Assert Optional Properties
Use this method when you want to ensure a propery is not nil, then make any extra assertions you may want to check.
```swift
import XCTest
import NnTestHelpers

final class MyTests: XCTestCase {
    func testProperty() {
        let sut = makeSUT()
        let value = sut.methodToCreateIntValue()

        assertProperty(value, name: "value") { XCTAssert($0 > 0) }
    }
}
```
If you just want to compare the optional value to an expected property, assertPropertyEquality does the trick.
```swift
import XCTest
import NnTestHelpers

final class MyTests: XCTestCase {
    func testPropertyEquality() {
        let sut = makeSUT()
        let value = sut.methodToCreateIntValue()

        assertPropertyEquality(value, expectedProperty: 5)
    }
}
```

##### Assert Array Contains Items
Easily check for the existence of any type or Equatable data.
```swift
import XCTest
import NnTestHelpers

final class MyTests: XCTestCase {
    func testArrayContainsItems() {
        let array = [1, 2, 3, 4, 5]
        assertArray(array, contains: [1, 2])
    }
}
```

##### Assert No Error Thrown
Yes, XCTAssertNoThrow alreAdy exists, but it doesn't allow you to pass in file: StaticString = #filePath, line: UInt = #line as arguments, which is kind of a dealbreaker for me. This method solves that problem, so using it nested in another helper method will still allow you to track the exact file/line where the error occurs. And there's an async-friendly version of this method as well.

```swift
import XCTest
import NnTestHelpers

final class MyTests: XCTestCase {
    func testNoErrorThrown() {
        assertNoErrorThrown {
            // Your test code here
        }
    }

    func testAsyncNoErrorThrown() async {
        await asyncAssertNoErrorThrown {
            // Your asynchronous test code here
        }
    }
}
```

##### Assert Thrown Error
Same as the previous method, this just accepts file: StaticString = #filePath, line: UInt = #line as optional arguments to better track the failures. And there's an async-friendly version of this method as well.

```swift
import XCTest
import NnTestHelpers

enum MyCustomError: Error {
    case invalidInput
}

final class MyTests: XCTestCase {
    func testErrorIsThrown() {
        assertThrownError(expectedError: MyCustomError.invalidInput) {
            // Your throwing test code here 
        }
    }

    func testAsyncErrorIsThrown() async {
        await asyncAssertThrownError(expectedError: MyCustomError.invalidInput) {
            // Your asynchronous throwing test code here 
        }
    }
}
```
### BaseUITestCase
UI Tests are extremely powerful, but the recording process is often diappointing. NnTestKit provides `BaseUITestCase` to help with common actions that can be performed.

#### Setup Helpers
Easily pass in any environment variables to be used in the app during UI tests. `IS_TRUE` is the default value, which simple sets the value of the passed in key to "true". `ProcessInfo` is extended to include a helper method to easily check for the existence of an `IS_TRUE` value within the environment.

When UI testing, the environment variable `IS_UI_TESTING` is automatically passed into the environment. Like `ProcessInfo.isTesting`, `ProcessInfo.isUITesting` can be access by importing the smaller libarary `NnTestVariables` so it won't cause too much bloat if used in production.

```swift
// App target 
import SwiftUI
import NnTestVariables

@main
struct AppLauncher {
    static func main() throws {
        if ProcessInfo.isTesting {
            if ProcessInfo.isUITesting {
                TestApp.main()
            } else {
                Text("Running unit tests")
            }
        } else {
            MyApp.main()
        }
    }
}
```
```swift
// UI Test target
import XCTest
import NnTestHelpers
import NnTestVariables

final class MyUITests: BaseUITestCase {
    func testEnvironmentSetup() {
        addKeyToENV("MY_KEY", value: "MY_VALUE")
        // Your test code here
    }
}
```

#### UI Element Helpers
BaseUITestCase already contains an instance of XCUIApplication for you to access, stored in the `app` property. Use it to easily launch the app or to compose the XCUIElementQuery needed to find a UI element.

```swift
import XCTest
import NnTestHelpers

final class MyUITests: BaseUITestCase {
    func testWaitForElement() {
        app.launch()

        let text = waitForElement(app.staticTexts, id: "myTextLabel").label
        // remainining test code
    }
}
```

#### UI Action Helpers

##### Date Picker Selection
Easily change the date on a date picker. Currently, this method supports only changing selected day, or changing both the selected month and the selected day.

```swift
import XCTest
import NnTestHelpers

final class MyUITests: BaseUITestCase {
    func testSelectDate_onlyChangeDay() {
        app.launch()
        let datePicker = waitForElement(app.datePickers, id: "myDatePicker")
        selectDate(picker: datePicker, dayNumberToSelect: 15)
    }
    
    func testSelectDate_changeMonthAndDay) {
        app.launch()
        selectDate(pickerId: "myDatePicker", currentMonth: "June", newMonth: "January", newDay: 15)
    }
}
```

##### Row Selection
Select a tableview/collectonView row (cell) based on the text it should contain.

```swift
import XCTest
import NnTestHelpers

final class MyUITests: BaseUITestCase {
    func testRowSelection() {
        app.launch()
        let row = getRowContainingText(parentViewId: "myCollectionView", text: "Row Text")
        XCTAssertTrue(row.exists)
    }
}
```

##### Row Deletion
Delete a tableview/collectionView row (cell) based on the text it should contain. If a confirmationDialgue is expected to display after attempting to delete the row, set withConfirmationAlert to true to tap the corresponding alertSheetButton.

NOTE: By default, "Delete" will be used as the alertSheetButtonId when the value is nil. If you need to tap a different button, simply set alertSheetButtonId to the id of the button you want to press in the alert sheet. 
```swift
import XCTest
import NnTestHelpers

final class MyUITests: BaseUITestCase {
    func testDeleteRow_noConfirmationAlert() {
        app.launch()
        let row = getRowContainingText(parentViewId: "myCollectionView", text: "Row Text")
        deleteRow(row: row)
    }
    
    func testDeleteRow_withConfirmationAlert() {
        app.launch()
        let row = getRowContainingText(parentViewId: "myCollectionView", text: "Row Text")
        deleteRow(row: row, swipeButtonId: "Delete", withConfirmationAlert: true, alertSheetButtonId: "ConfirmDelete")
    }
}
```
##### Third Party Alerts
I'm going to be honest, this method can be a bit flaky. Unfortunatley dealing with third party alerts isn't as reliable as dealing with native iOS alerts. Still, if you need to tap a button on an alert presented by a third party, this is the method to use. 

NOTE: Sometimes the app will need to be tapped in order to proceed. If you experience issues, toggle withAppTap and try again.
```swift
import XCTest
import NnTestHelpers

final class MyUITests: BaseUITestCase {
    func testWaitForThirdPartyAlert() {
        app.launch()
        waitForThirdPartyAlert(decription: ""“MyApp” Wants to Use “google.com” to Sign In"", button: "Cancel", withAppTap: true)
        // Perform actions that trigger the third-party alert
    }
}
```
##### Type in textfield
You can enter text in either a regular textfield or a secureField. You can clear the field text before typing, as well as tap the keyboard "Done" button when finished. 

NOTE: By default, this method will tap the textfield before taking any action. If you expect the field to already be in focus, it may be best to set shouldTapFieldBeforeTyping to false to avoid problems.

```swift
import XCTest
import NnTestHelpers

final class MyUITests: BaseUITestCase {
    func testTypeInField() {
        app.launch()
        typeInField(fieldId: "username", text: "testUser")
        
        // Type text into a secure text field and clear it first
        typeInField(fieldId: "password", isSecure: true, text: "password123", clearField: true)
        
        // Type text and tap the Done button after typing
        typeInField(fieldId: "search", text: "query", tapDoneButton: true)
    }
}
```

## Swift 6 Compatibility

NnTestKit is fully compatible with Swift 6's strict concurrency checking:
- `@MainActor` annotations on UI testing components
- `@preconcurrency` imports for Combine framework compatibility
- Thread-safe memory leak tracking implementation

## Contributing

I am open to contributions! If you have ideas, enhancements, or bug fixes, feel free to [open an issue](https://github.com/nikolainobadi/NnTestKit/issues/new). Please ensure that your code adheres to the existing coding standards and includes appropriate documentation and tests.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

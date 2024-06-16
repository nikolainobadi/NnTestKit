
# NnTestKit

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Swift Version](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)

NnTestKit is a Swift package that provides a collection of helper methods to simplify unit and UI testing in your iOS projects. It extends XCTest to offer more convenient and powerful assertion methods, memory leak tracking, and UI testing utilities.

NOTE: All test helper methods are located in the NnTestHelpers libary, which should only be included as a dependency in test targets. NnTestVariables is a much smaller library and only contains a few properties and extensions to assit with testing. The idea is that its significantly smaller size shouldn't cause any problems when added as a dependency in production targets.

## Features
- Memory leak tracking
- Property and array assertions
- Error handling assertions
- Date extensions for testing
- UI test case setup and helper methods

## Installation

To add NnTestKit to your Xcode project, add the following dependency to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/nikolainobadi/NnTestKit", branch: "main")
]
```

Then, add `NnTestKit` to your target dependencies:

```swift
.target(
    name: "YourTargetName",
    dependencies: ["NnTestKit"]
)
```
## Usage

### XCTestCase Extensions

NnTestKit extends `XCTestCase` with several useful methods:

#### Memory Leak Tracking
Prevent memory leaks before they infect your code by passing the object you want to track into this method before running your unit tests. This method ensures the object in question is dellocated by the end of the test eles the test will fail.
```swift
class MyTests: XCTestCase {
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
class MyTests: XCTestCase {
    func testProperty() {
        let sut = makeSUT()
        let value = sut.methodToCreateIntValue()

        assertProperty(value, name: "value") { XCTAssert($0 > 0) }
    }
}
```
If you just want to compare the optional value to an expected property, assertPropertyEquality does the trick.
```swift
class MyTests: XCTestCase {
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
class MyTests: XCTestCase {
    func testArrayContainsItems() {
        let array = [1, 2, 3, 4, 5]
        assertArray(array, contains: [1, 2])
    }
}
```

##### Assert No Error Thrown
Yes, XCTAssertNoThrow alreAdy exists, but it doesn't allow you to pass in file: StaticString = #filePath, line: UInt = #line as arguments, which is kind of a dealbreaker for me. This method solves that problem, so using it nested in another helper method will still allow you to track the exact file/line where the error occurs. And there's an async-friendly version of this method as well.

```swift
class MyTests: XCTestCase {
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
enum MyCustomError: Error {
    case invalidInput
}

class MyTests: XCTestCase {
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

```swift
// App target 
import SwiftUI
import NnTestVariables

@main
struct AppLauncher {
    static func main() throws {
        if ProcessInfo.isTesting {
            TestApp.main()
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

class MyUITests: BaseUITestCase {
    func testEnvironmentSetup() {
        addKeyToENV("MY_KEY", value: "MY_VALUE")
        // Your test code here
    }
}
```

#### UI Element Helpers
BaseUITestCase already contains an instance of XCUIApplication for you to access, stored in the `app` property. Use it to easily launch the app or to compose the XCUIElementQuery needed to find a UI element.

```swift
class MyUITests: BaseUITestCase {
    func testWaitForElement() {
        app.launch()

        let text = waitForElement(app.staticTexts, id: "myTextLabel").label
        // remainining test code
    }
}
```

#### UI Action Helpers

```swift
class MyUITests: BaseUITestCase {
    func testSelectDate() {
        app.launch()
        let datePicker = waitForElement(app.datePickers, id: "myDatePicker")
        selectDate(picker: datePicker, dayNumberToSelect: 15)
    }
}
```

## Contributing

I am a solo iOS developer and welcome any and all contributions. Feel free to fork the repository, make improvements, and submit a pull request.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contact

For questions or suggestions, feel free to reach out via [GitHub Issues](https://github.com/nikolainobadi/NnTestKit/issues).

---

Thank you for using NnTestKit! Your contributions and feedback are highly appreciated.

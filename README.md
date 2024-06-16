
# NnTestKit

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Swift Version](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)

NnTestKit is a Swift package that provides a collection of helper methods to simplify unit and UI testing in your iOS projects. It extends XCTest to offer more convenient and powerful assertion methods, memory leak tracking, and UI testing utilities.

## Features

- Asynchronous method waiting
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



## Contributing

I am a solo iOS developer and welcome any and all contributions. Feel free to fork the repository, make improvements, and submit a pull request.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contact

For questions or suggestions, feel free to reach out via [GitHub Issues](https://github.com/nikolainobadi/NnTestKit/issues).

---

Thank you for using NnTestKit! Your contributions and feedback are highly appreciated.

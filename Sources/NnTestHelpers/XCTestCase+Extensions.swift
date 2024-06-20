//
//  XCTestCase+Extensions.swift
//
//
//  Created by Nikolai Nobadi on 5/22/24.
//

import XCTest
import Combine

public extension XCTestCase {
    /// Pauses the execution of an asynchronous test for the specified duration.
    /// - Parameter nanoseconds: The number of nanoseconds to pause. Default is 0.1 seconds.
    func waitForAsyncMethod(nanoseconds: UInt64 = 0_100_000_000) async throws {
        try await Task.sleep(nanoseconds: nanoseconds)
    }
    
    /// Tracks the specified instance for memory leaks and fails the test if the instance is not deallocated.
    /// - Parameters:
    ///   - instance: The instance to track.
    ///   - file: The file name to be used in the assertion. Default is the current file.
    ///   - line: The line number to be used in the assertion. Default is the current line.
    func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            print("checking for \(String(describing: instance))")
            XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak.", file: file, line: line)
        }
    }
    
    /// Waits for a given Combine publisher to emit a value that satisfies a certain condition or until a timeout occurs.
    ///
    /// This function asynchronously waits for a publisher to emit a value that doesn't meet the `dropWhile` condition.
    /// It sets up an expectation that is fulfilled once the publisher emits a qualifying value or the timeout is reached.
    ///
    /// - Parameters:
    ///   - publisher: The Combine publisher to wait for.
    ///   - dropWhile: A closure that takes an output value from the publisher and returns a Boolean value indicating whether to drop the value.
    ///   - cancellables: A set to store any cancellables created within this method.
    ///   - timeout: The time interval in seconds to wait before the function times out. Default is 5 seconds.
    ///
    /// - Note: This method assumes that the publisher's failure type is `Never`.
    func waitForPublisher<P: Publisher>(publisher: P, dropWhile: @escaping (P.Output) -> Bool, cancellables: inout Set<AnyCancellable>, timeout: TimeInterval = 5) async where P.Failure == Never {
        
        // Create an expectation with a description for asynchronous waiting.
        let exp = expectation(description: "waiting for publisher")
        var didFinish = false

        // Subscribe to the publisher, dropping values while `dropWhile` returns true.
        publisher
            .drop(while: dropWhile)
            .sink { _ in
                // Fulfill the expectation if a qualifying value is received.
                if !didFinish {
                    didFinish = true
                    exp.fulfill()
                }
            }
            .store(in: &cancellables)

        // Wait for the expectation to be fulfilled or for the timeout to occur.
        await fulfillment(of: [exp], timeout: timeout)
    }
}

// MARK: - Assertion Helpers
public extension XCTestCase {
    /// Asserts that a property is not nil and performs a custom assertion on it.
    /// - Parameters:
    ///   - property: The property to assert.
    ///   - name: The name of the property for error messages. Default is nil.
    ///   - assertion: The custom assertion to perform.
    ///   - file: The file name to be used in the assertion. Default is the current file.
    ///   - line: The line number to be used in the assertion. Default is the current line.
    func assertProperty<T>(_ property: T?, name: String? = nil, assertion: (T) -> Void, file: StaticString = #filePath, line: UInt = #line) {
        guard let property else {
            XCTFail("expected \(name ?? "value") but found nil", file: file, line: line)
            return
        }
        assertion(property)
    }

    /// Asserts that a property equals an expected value.
    /// - Parameters:
    ///   - property: The property to assert.
    ///   - name: The name of the property for error messages. Default is nil.
    ///   - expectedProperty: The expected value of the property.
    ///   - file: The file name to be used in the assertion. Default is the current file.
    ///   - line: The line number to be used in the assertion. Default is the current line.
    func assertPropertyEquality<T: Equatable>(_ property: T?, name: String? = nil, expectedProperty: T, file: StaticString = #filePath, line: UInt = #line) {
        assertProperty(property, name: name, assertion: { receivedProperty in
            XCTAssertEqual(receivedProperty, expectedProperty, "\(receivedProperty) does not match expectation: \(expectedProperty)", file: file, line: line)
        }, file: file, line: line)
    }

    /// Asserts that an array contains the specified items.
    /// - Parameters:
    ///   - array: The array to assert.
    ///   - items: The items that the array should contain.
    ///   - file: The file name to be used in the assertion. Default is the current file.
    ///   - line: The line number to be used in the assertion. Default is the current line.
    func assertArray<T: Equatable>(_ array: [T], contains items: [T], file: StaticString = #filePath, line: UInt = #line) {
        items.forEach { XCTAssertTrue(array.contains($0), "missing value: \($0)", file: file, line: line) }
    }

    /// Asserts that an array does not contain the specified items.
    /// - Parameters:
    ///   - array: The array to assert.
    ///   - items: The items that the array should not contain.
    ///   - file: The file name to be used in the assertion. Default is the current file.
    ///   - line: The line number to be used in the assertion. Default is the current line.
    func assertArray<T: Equatable>(_ array: [T], doesNotContain items: [T], file: StaticString = #filePath, line: UInt = #line) {
        items.forEach { XCTAssertFalse(array.contains($0), "array should not contain \($0)", file: file, line: line) }
    }

    /// Asserts that no error is thrown during the execution of the specified action.
    /// - Parameters:
    ///   - action: The action to execute.
    ///   - message: The error message to be used if an error is thrown. Default is nil.
    ///   - file: The file name to be used in the assertion. Default is the current file.
    ///   - line: The line number to be used in the assertion. Default is the current line.
    func assertNoErrorThrown(action: @escaping () throws -> Void, _ message: String? = nil, file: StaticString = #filePath, line: UInt = #line) {
        do {
            try action()
        } catch {
            XCTFail(message ?? "unexpected error: \(error)", file: file, line: line)
        }
    }

    /// Asserts asynchronously that no error is thrown during the execution of the specified action.
    /// - Parameters:
    ///   - action: The asynchronous action to execute.
    ///   - message: The error message to be used if an error is thrown. Default is nil.
    ///   - file: The file name to be used in the assertion. Default is the current file.
    ///   - line: The line number to be used in the assertion. Default is the current line.
    func asyncAssertNoErrorThrown(action: @escaping () async throws -> Void, _ message: String? = nil, file: StaticString = #filePath, line: UInt = #line) async {
        do {
            try await action()
        } catch {
            XCTFail(message ?? "unexpected error: \(error)", file: file, line: line)
        }
    }

    /// Asserts that an expected error is thrown during the execution of the specified action.
    /// - Parameters:
    ///   - expectedError: The expected error to be thrown.
    ///   - action: The action to execute.
    ///   - file: The file name to be used in the assertion. Default is the current file.
    ///   - line: The line number to be used in the assertion. Default is the current line.
    func assertThrownError<ErrorType: Error & Equatable>(expectedError: ErrorType, action: @escaping () throws -> Void, file: StaticString = #filePath, line: UInt = #line) {
        do {
            try action()
            XCTFail("expected an error but none were thrown", file: file, line: line)
        } catch {
            handleError(error, expectedError: expectedError, file: file, line: line)
        }
    }

    /// Asserts asynchronously that an expected error is thrown during the execution of the specified action.
    /// - Parameters:
    ///   - expectedError: The expected error to be thrown.
    ///   - action: The asynchronous action to execute.
    ///   - file: The file name to be used in the assertion. Default is the current file.
    ///   - line: The line number to be used in the assertion. Default is the current line.
    func asyncAssertThrownError<ErrorType: Error & Equatable>(expectedError: ErrorType, action: @escaping () async throws -> Void, file: StaticString = #filePath, line: UInt = #line) async {
        do {
            try await action()
            XCTFail("expected an error but none were thrown", file: file, line: line)
        } catch {
            handleError(error, expectedError: expectedError, file: file, line: line)
        }
    }

    /// Handles errors during assertion, checking if the received error matches the expected error.
    /// - Parameters:
    ///   - error: The received error.
    ///   - expectedError: The expected error.
    ///   - file: The file name to be used in the assertion. Default is the current file.
    ///   - line: The line number to be used in the assertion. Default is the current line.
    func handleError<ErrorType: Error & Equatable>(_ error: Error, expectedError: ErrorType, file: StaticString, line: UInt) {
        guard let receivedError = error as? ErrorType else {
            XCTFail("unexpected error: \(error)", file: file, line: line)
            return
        }
        XCTAssertEqual(receivedError, expectedError, "\(receivedError) does not match expected error: \(expectedError)", file: file, line: line)
    }
}

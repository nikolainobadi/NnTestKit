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
    
    /// Pauses the execution of an asynchronous test for the specified duration.
    /// - Parameter seconds: The number of seconds to pause. Default is 0.1 seconds.
    func waitForAsyncMethod(seconds: Double = 0.1) async throws {
        try await waitForAsyncMethod(nanoseconds: .init(seconds * 1_000_000_000))
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
    
    /// Waits for a specific condition to be met from a publisher's output.
    /// - Parameters:
    ///   - publisher: The publisher to subscribe to.
    ///   - description: A description for the expectation. Default is "waiting for publisher".
    ///   - cancellables: A set of `AnyCancellable` to store the subscription.
    ///   - timeout: The time to wait for the condition to be met. Default is 3 seconds.
    ///   - condition: A closure that takes the publisher's output and returns `true` if the condition is met.
    ///
    /// # Example Usage:
    /// ```swift
    /// let publisher = Just(42).delay(for: .seconds(1), scheduler: RunLoop.main)
    /// var cancellables = Set<AnyCancellable>()
    ///
    /// waitForCondition(publisher: publisher, cancellables: &cancellables) { output in
    ///     return output == 42
    /// }
    /// ```
    /// In this example, the test waits for the `Just` publisher to emit the value `42`.
    /// The condition is met when the output is `42`, and the test will continue after this condition is fulfilled.
    func waitForCondition<P: Publisher>(
        publisher: P,
        description: String = "waiting for publisher",
        cancellables: inout Set<AnyCancellable>,
        timeout: TimeInterval = 3,
        condition: @escaping (P.Output) -> Bool
    ) {
        let expectation = XCTestExpectation(description: description)
        
        publisher
            .sink { completion in
                if case .failure(let error) = completion {
                    XCTFail("Publisher failed with error: \(error)")
                }
            } receiveValue: { newValue in
                if condition(newValue) {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: timeout)
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
    func assertProperty<T>(_ property: T?, name: String? = nil, assertion: ((T) -> Void)? = nil, file: StaticString = #filePath, line: UInt = #line) {
        guard let property else {
            XCTFail("expected \(name ?? "value") but found nil", file: file, line: line)
            return
        }
        
        assertion?(property)
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
    
    /// Asserts that an array contains the specified items based on their `id`.
    /// - Parameters:
    ///   - array: The array to assert.
    ///   - items: The items that the array should contain.
    ///   - file: The file name to be used in the assertion. Default is the current file.
    ///   - line: The line number to be used in the assertion. Default is the current line.
    func assertIdentifiableArray<T: Identifiable>(_ array: [T], contains items: [T], file: StaticString = #filePath, line: UInt = #line) {
        items.forEach { item in
            XCTAssertTrue(array.contains(where: { $0.id == item.id }), "missing item with id: \(item.id)", file: file, line: line)
        }
    }

    /// Asserts that an array does not contain the specified items based on their `id`.
    /// - Parameters:
    ///   - array: The array to assert.
    ///   - items: The items that the array should not contain.
    ///   - file: The file name to be used in the assertion. Default is the current file.
    ///   - line: The line number to be used in the assertion. Default is the current line.
    func assertIdentifiableArray<T: Identifiable>(_ array: [T], doesNotContain items: [T], file: StaticString = #filePath, line: UInt = #line) {
        items.forEach { item in
            XCTAssertFalse(array.contains(where: { $0.id == item.id }), "array should not contain item with id: \(item.id)", file: file, line: line)
        }
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
    func assertThrownError<ErrorType: Error & Equatable>(expectedError: ErrorType? = nil, action: @escaping () throws -> Void, file: StaticString = #filePath, line: UInt = #line) {
        do {
            try action()
            
            XCTFail("expected an error but none were thrown", file: file, line: line)
        } catch {
            if let expectedError {
                handleError(error, expectedError: expectedError, file: file, line: line)
            }
        }
    }

    /// Asserts asynchronously that an expected error is thrown during the execution of the specified action.
    /// - Parameters:
    ///   - expectedError: The expected error to be thrown.
    ///   - action: The asynchronous action to execute.
    ///   - file: The file name to be used in the assertion. Default is the current file.
    ///   - line: The line number to be used in the assertion. Default is the current line.
    func asyncAssertThrownError<ErrorType: Error & Equatable>(expectedError: ErrorType? = nil, action: @escaping () async throws -> Void, file: StaticString = #filePath, line: UInt = #line) async {
        do {
            try await action()
            
            XCTFail("expected an error but none were thrown", file: file, line: line)
        } catch {
            if let expectedError {
                handleError(error, expectedError: expectedError, file: file, line: line)
            }
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

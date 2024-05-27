//
//  XCTestCase+Extensions.swift
//
//
//  Created by Nikolai Nobadi on 5/22/24.
//

import XCTest

public extension XCTestCase {
    func waitForAsyncMethod() async throws {
        try await Task.sleep(nanoseconds: 0_010_000_000)
    }
    
    func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #filePath, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            print("checking for \(String(describing: instance))")
            XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak.", file: file, line: line)
        }
    }
}


// MARK: - Assertion Helpers
public extension XCTestCase {
    func assertProperty<T>(_ property: T?, name: String? = nil, assertion: (T) -> Void, file: StaticString = #filePath, line: UInt = #line) {
        guard let property else {
            XCTFail("expected \(name ?? "value") but found nil", file: file, line: line)
            return
        }
        
        assertion(property)
    }
    
    func assertPropertyEquality<T: Equatable>(_ property: T?, name: String? = nil, expectedProperty: T, file: StaticString = #filePath, line: UInt = #line) {
        assertProperty(property, name: name) { receivedProperty in
            XCTAssertEqual(receivedProperty, expectedProperty, "values don't match", file: file, line: line)
        }
    }
    
    func assertArray<T: Equatable>(_ array: [T], contains items: [T], file: StaticString = #filePath, line: UInt = #line) {
        
        items.forEach {
            XCTAssertTrue(array.contains($0), "missing value: \($0)", file: file, line: line)
        }
    }
    
    func assertArray<T: Equatable>(_ array: [T], doesNotContain items: [T], file: StaticString = #filePath, line: UInt = #line) {
        
        items.forEach {
            XCTAssertFalse(array.contains($0), "array should not contain \($0)", file: file, line: line)
        }
    }
    
    func assertNoErrorThrown(action: @escaping () throws -> Void, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertNoThrow(try action(), "unexpected error", file: file, line: line)
    }
    
    func assertThrownError<ErrorType: Error & Equatable>(expectedError: ErrorType, action: @escaping () throws -> Void, file: StaticString = #filePath, line: UInt = #line) {
        do {
            try action()
            XCTFail("expected an error but none were thrown", file: file, line: line)
        } catch {
            guard let receivedError = error as? ErrorType else {
                XCTFail("unexpected error", file: file, line: line)
                return
            }
            
            XCTAssertEqual(receivedError, expectedError, "received error does not match expected error", file: file, line: line)
        }
    }
}
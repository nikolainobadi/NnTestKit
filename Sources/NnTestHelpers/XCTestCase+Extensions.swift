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

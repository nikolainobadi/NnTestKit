//
//  BaseUITestCase+TestData.swift
//
//
//  Created by Nikolai Nobadi on 5/22/24.
//

import Foundation

// MARK: - TestData Helpers
public extension BaseUITestCase {
    /// Generates a random email address in the format `<randomNumber>tester<randomNumber><randomNumber>@gmail.com`.
    /// - Returns: A randomly generated email address as a `String`.
    func makeRandomEmail() -> String {
        return "\(getRandomNumber())tester\(getRandomNumber())\(getRandomNumber())@gmail.com"
    }

    /// Generates a random username in the format `tester<randomNumber><randomNumber><randomNumber>`.
    /// - Returns: A randomly generated username as a `String`.
    func makeRandomUsername() -> String {
        return "tester\(getRandomNumber())\(getRandomNumber())\(getRandomNumber())"
    }

    /// Generates a random single-digit number between 0 and 9.
    /// - Returns: A random integer between 0 and 9.
    func getRandomNumber() -> Int {
        return Int.random(in: 0...9)
    }
}

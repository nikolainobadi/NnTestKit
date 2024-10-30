//
//  Date+TestExtensions.swift
//  
//
//  Created by Nikolai Nobadi on 6/5/24.
//

import Foundation

public extension Date {
    /// Creates a `Date` object from the specified components.
    /// - Parameters:
    ///   - year: The year component.
    ///   - month: The month component.
    ///   - day: The day component.
    ///   - hour: The hour component. Default is 8.
    ///   - minute: The minute component. Default is 0.
    /// - Returns: A `Date` object representing the specified components.
    static func from(year: Int, month: Int, day: Int, hour: Int = 8, minute: Int = 0) -> Date {
        let dateComponents = DateComponents(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        )
        return Calendar(identifier: .gregorian).date(from: dateComponents)!
    }
    
    /// Converts the `Date` object to a string formatted for a date picker.
    /// - Returns: A `String` representing the date in "MMM d, yyyy" format.
    func asDatePickerString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: self)
    }
}

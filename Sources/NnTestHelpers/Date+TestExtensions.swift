//
//  Date+TestExtensions.swift
//  
//
//  Created by Nikolai Nobadi on 6/5/24.
//

import Foundation

public extension Date {
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
    
    func asDatePickerString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        
        return formatter.string(from: self)
    }
}

//
//  Date+Additions.swift
//  Workouts
//
//  Created by Axel Rivera on 1/31/21.
//

import Foundation

extension Date {
  
    func isWithinNumberOfDays(_ number: Int) -> Bool {
        let calendar = Calendar.current
        let currentNumberOfDays = calendar.dateComponents([.day], from: self, to: Date()).day ?? 0
        return currentNumberOfDays <= number
    }
    
}

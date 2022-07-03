//
//  WorkoutError.swift
//  Workouts
//
//  Created by Axel Rivera on 6/19/22.
//

import Foundation

struct WorkoutError: Error {
    let message: String
    
    init(_ message: String) {
        self.message = message
    }
}

extension WorkoutError: CustomStringConvertible {
    var description: String { message }
}

extension WorkoutError: LocalizedError {
    var errorDescription: String? { message }
}

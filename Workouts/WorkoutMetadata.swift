//
//  WorkoutMetadata.swift
//  Workouts
//
//  Created by Axel Rivera on 1/29/21.
//

import Foundation

protocol WorkoutMetadata {
    
    var avgTemperature: WorkoutImport.Value { get }
    var avgSpeed: WorkoutImport.Value { get }
    var maxSpeed: WorkoutImport.Value { get }
    var totalAscent: WorkoutImport.Value { get}
    var totalDescent: WorkoutImport.Value { get }
    
}


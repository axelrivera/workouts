//
//  WorkoutImageProvider.swift
//  Workouts
//
//  Created by Axel Rivera on 8/1/22.
//

import Foundation
import SwiftUI

struct WorkoutImageProvider {
    typealias WorkoutID = UUID
    
    func get(forID id: WorkoutID, scheme: ColorScheme) -> UIImage? {
        Self.get(forID: id, scheme: scheme)
    }
    
    static func get(forID id: WorkoutID, scheme: ColorScheme) -> UIImage? {
        let url = URL.cachedMapImageURL(id: id, scheme: scheme)
        return FileManager.localImage(at: url)
    }
    
    static func writeImageData(dark: Data, light: Data, workout: UUID) throws {
        try FileManager.writeWorkoutImageData(dark: dark, light: light, workout: workout)
    }
    
}

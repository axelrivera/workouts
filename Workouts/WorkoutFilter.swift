//
//  WorkoutFetchRequest.swift
//  Workouts
//
//  Created by Axel Rivera on 8/2/21.
//

import SwiftUI
import CoreData

struct WorkoutFilter<Content: View>: View {
    @FetchRequest<Workout>
    var workouts: FetchedResults<Workout>
    
    var content: (Workout) -> Content
    
    init(sport: Sport?, interval: DateInterval? = nil, content: @escaping (Workout) -> Content) {
        _workouts = DataProvider.fetchRequest(sport: sport, interval: interval)
        self.content = content
    }
    
    init(identifiers: [UUID], content: @escaping (Workout) -> Content) {
        _workouts = DataProvider.fetchRequest(for: identifiers)
        self.content = content
    }
    
    var body: some View {
        ForEach(workouts, id: \.objectID) { workout in
            content(workout)
        }
    }
    
}

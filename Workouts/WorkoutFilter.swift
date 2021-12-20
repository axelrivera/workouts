//
//  WorkoutFetchRequest.swift
//  Workouts
//
//  Created by Axel Rivera on 8/2/21.
//

import SwiftUI
import CoreData

struct WorkoutFilter<Content: View>: View {
    
    var fetchRequest: FetchRequest<Workout>
    var workouts: FetchedResults<Workout> { fetchRequest.wrappedValue }
    
    var content: (Workout) -> Content
    
    init(fetchRequest: FetchRequest<Workout>, @ViewBuilder content: @escaping (Workout) -> Content) {
        self.fetchRequest = fetchRequest
        self.content = content
    }
    
    init(sport: Sport?, interval: DateInterval? = nil, @ViewBuilder content: @escaping (Workout) -> Content) {
        fetchRequest = DataProvider.fetchRequest(sport: sport, interval: interval)
        self.content = content
    }
    
    init(identifiers: [UUID], @ViewBuilder content: @escaping (Workout) -> Content) {
        fetchRequest = DataProvider.fetchRequest(for: identifiers)
        self.content = content
    }

    var body: some View {
        ForEach(workouts, id: \.objectID) { workout in
            content(workout)
        }
    }
    
}

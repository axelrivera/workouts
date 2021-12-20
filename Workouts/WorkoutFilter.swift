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
    @Binding var isEmpty: Bool
    
    init(sport: Sport?, interval: DateInterval? = nil, isEmpty: Binding<Bool>, @ViewBuilder content: @escaping (Workout) -> Content) {
        _workouts = DataProvider.fetchRequest(sport: sport, interval: interval)
        self.content = content
        _isEmpty = isEmpty
    }
    
    init(identifiers: [UUID], isEmpty: Binding<Bool>, @ViewBuilder content: @escaping (Workout) -> Content) {
        _workouts = DataProvider.fetchRequest(for: identifiers)
        self.content = content
        _isEmpty = isEmpty
    }

    var body: some View {
        isEmpty = workouts.isEmpty
        return ForEach(workouts, id: \.objectID) { workout in
            content(workout)
        }
    }
    
}

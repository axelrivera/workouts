//
//  WorkoutsView.swift
//  Workouts
//
//  Created by Axel Rivera on 12/20/20.
//

import SwiftUI

struct WorkoutsView: View {
    enum ActiveSheet: Identifiable {
        case add
        var id: Int { hashValue }
    }
    
    @EnvironmentObject var workoutManager: WorkoutManager
    @State var activeSheet: ActiveSheet?
    
    var body: some View {
        NavigationView {
            ZStack {
                List {
                    ForEach(workoutManager.workouts) { workout in
                        NavigationLink(destination: DetailView(workout: workout)) {
                            VStack(alignment: .leading, spacing: 2.0) {
                                Text(formattedActivityTypeString(for: workout.activityType, indoor: workout.indoor))
                                
                                if let distance = workout.distance {
                                    Text(formattedDistanceString(for: distance))
                                        .font(.title)
                                        .foregroundColor(.distance)
                                } else {
                                    Text(formattedHoursMinutesDurationString(for: workout.elapsedTime))
                                        .font(.title)
                                        .foregroundColor(.time)
                                }
                                
                                HStack {
                                    Text(workout.source)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(formattedRelativeDateString(for: workout.startDate))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
                
                if workoutManager.state == .empty || workoutManager.state == .notAvailable {
                    Color.systemBackground
                        .ignoresSafeArea()
                    WorkoutEmptyView(workoutState: workoutManager.state)
                }
            }
            .navigationTitle("Workouts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { activeSheet = .add }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .fullScreenCover(item: $activeSheet) { item in
                switch item {
                case .add:
                    ImportView()
                        .environmentObject(ImportManager())
                }
            }
        }
    }
}

struct WorkoutsView_Previews: PreviewProvider {
    static var workoutManager: WorkoutManager = {
        let manager = WorkoutManager()
        //manager.state = .notAvailable
        manager.workouts = WorkoutManager.sampleWorkouts()
        return manager
    }()
    
    static var previews: some View {
        WorkoutsView()
            .environmentObject(workoutManager)
            .colorScheme(.dark)
    }
}

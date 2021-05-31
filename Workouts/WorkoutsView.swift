//
//  WorkoutsView.swift
//  Workouts
//
//  Created by Axel Rivera on 12/20/20.
//

import SwiftUI
import CoreData

struct WorkoutsView: View {
    enum ActiveSheet: Identifiable {
        case add
        var id: Int { hashValue }
    }
    
    @EnvironmentObject var workoutManager: WorkoutManager
    @State var activeSheet: ActiveSheet?
    
    static var fetchRequest: NSFetchRequest<Workout> = {
        let request = Workout.sortedFetchRequest
        request.fetchBatchSize = 20
        request.returnsObjectsAsFaults = false
        return request
    }()
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(fetchRequest: Self.fetchRequest, animation: .default)
    private var workouts: FetchedResults<Workout>
    
    var body: some View {
        NavigationView {
            ZStack {
                List {
                    ForEach(workouts) { workout in
                        NavigationLink(destination: DetailView(workout: workout, context: self.viewContext)) {
                            VStack(alignment: .leading, spacing: 2.0) {
                                Text(formattedActivityTypeString(for: workout.sport, indoor: workout.indoor))
                                
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
                                    Text(formattedRelativeDateString(for: workout.start))
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
        return manager
    }()
    
    static var previews: some View {
        WorkoutsView()
            .environment(\.managedObjectContext, StorageProvider.preview.persistentContainer.viewContext)
            .environmentObject(workoutManager)
            .colorScheme(.dark)
    }
}

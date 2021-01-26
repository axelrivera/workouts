//
//  WorkoutsView.swift
//  Workouts
//
//  Created by Axel Rivera on 12/20/20.
//

import SwiftUI

struct WorkoutsView: View {
    enum ActiveSheet: Identifiable {
        case add, document, settings
        var id: Int { hashValue }
    }
    
    @EnvironmentObject var workoutManager: WorkoutManager
    
    @State var activeSheet: ActiveSheet?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(workoutManager.workouts) { workout in
                    NavigationLink(destination: DetailView(workout: workout)) {
                        VStack(alignment: .leading) {
                            Text(workout.descriptionString)
                            Text(workout.distanceString)
                                .font(.title2)
                            HStack {
                                Text(workout.source)
                                Spacer()
                                Text(workout.dateString)
                                    .font(.subheadline)
                                    .foregroundColor(Color.secondaryLabel)
                            }
                        }
                    }
                }
            }
            .onAppear {
                workoutManager.fetchWorkouts()
            }
            .listStyle(PlainListStyle())
            .navigationTitle("Workouts")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {}) {
                        Text("All Workouts")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { activeSheet = .add }) {
                            Label("New Workout", systemImage: "plus.circle")
                        }
                        
                        Button(action: { activeSheet = .document }, label: {
                            Label("Import Workout", systemImage: "square.and.arrow.down")
                        })
                        
                        #if DEBUG
                        Button(action: { workoutManager.processSampleWorkout() }, label: {
                            Label("Import Sample Workout", systemImage: "bicycle.circle")
                        })
                        #endif
                        
                        Divider()
                        
                        Button(action: { activeSheet = .settings }) {
                            Label("Settings", systemImage: "gearshape")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(item: $activeSheet) { item in
                switch item {
                case .add:
                    AddView()
                case .document:
                    DocumentPicker(forOpeningContentTypes: [.fitDocument]) { urls in
                        workoutManager.importWorkous(at: urls)
                    }
                case .settings:
                    SettingsView()
                }
            }
        }
    }
}

struct WorkoutsView_Previews: PreviewProvider {
    static var workoutManager: WorkoutManager = {
       let manager = WorkoutManager()
        manager.generateSampleData()
        return manager
    }()
    
    static var previews: some View {
        WorkoutsView()
            .environmentObject(workoutManager)
    }
}

//
//  WorkoutsView.swift
//  Workouts
//
//  Created by Axel Rivera on 12/20/20.
//

import SwiftUI

struct WorkoutsView: View {
    enum ActiveSheet: Identifiable {
        case add, workoutImport, settings
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
                        // TODO: Enable Manual Workouts
//                        Button(action: { activeSheet = .add }) {
//                            Label("New Workout", systemImage: "plus.circle")
//                        }
                        
                        Button(action: { activeSheet = .workoutImport }) {
                            Label("Import Workouts", systemImage: "square.and.arrow.down")
                        }
                        
                        Divider()
                        
                        Button(action: { activeSheet = .settings }) {
                            Label("Settings", systemImage: "gearshape")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .imageScale(.large)
                    }
                }
            }
            .fullScreenCover(item: $activeSheet) { item in
                switch item {
                case .add:
                    AddView()
                case .workoutImport:
                    ImportView()
                        .environmentObject(ImportManager())
                case .settings:
                    SettingsView()
                }
            }
        }
    }
}

struct WorkoutsView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutsView()
            .environmentObject(WorkoutManager())
    }
}

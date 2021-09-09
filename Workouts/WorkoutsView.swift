//
//  WorkoutsView.swift
//  Workouts
//
//  Created by Axel Rivera on 12/20/20.
//

import SwiftUI
import CoreData

struct WorkoutsView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Binding var sport: Sport?
    
    @State private var selectedWorkout: UUID?
    @State private var isEmpty = false
        
    init(sport: Binding<Sport?>) {
        _sport = sport
    }
    
    func detailDestination(viewModel: WorkoutDetailViewModel) -> some View {
        DetailView(detailManager: DetailManager(viewModel: viewModel))
    }
            
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 0.0) {
                    WorkoutFilter(sport: sport, interval: nil, isEmpty: $isEmpty) { workout in
                        NavigationLink(
                            tag: workout.workoutIdentifier,
                            selection: $selectedWorkout,
                            destination: { detailDestination(viewModel: workout.detailViewModel) }) {
                            WorkoutMapCell(viewModel: workout.cellViewModel)
                                .padding()
                        }
                        .buttonStyle(WorkoutPlainButtonStyle())
                        Divider()
                    }
                }
            }
            .overlay(emptyOverlay())
            .navigationTitle("Workouts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            self.sport = nil
                        }, label: {
                            Text("All Workouts")
                        })

                        Divider()

                        ForEach(Sport.supportedSports) { sport in
                            Button(action: {
                                self.sport = sport
                            }, label: {
                                Text(sport.title)
                            })
                        }
                    } label: {
                        Text(sport?.title ?? "All Workouts")
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func emptyOverlay() -> some View {
        if isEmpty {
            VStack(spacing: 15.0) {
                Image(systemName: "heart.slash.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundColor(.red)
                
                Text("No Workouts")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Text("Better Workouts imports Health data stored by the Workout app on your Apple Watch.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.red)
                
                Text("Go to the Health app and give Better Workouts permission to read your workout data.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
}

struct WorkoutsView_Previews: PreviewProvider {
    static var viewContext = StorageProvider.preview.persistentContainer.viewContext
    static var workoutManager: WorkoutManager = {
        let manager = WorkoutManagerPreview.manager(context: viewContext)
        //manager.state = .notAvailable
        return manager
    }()
    
    @State static var sport: Sport?
    
    static var previews: some View {
        WorkoutsView(sport: $sport)
            .environment(\.managedObjectContext, viewContext)
            .environmentObject(workoutManager)
            .preferredColorScheme(.light)
    }
}

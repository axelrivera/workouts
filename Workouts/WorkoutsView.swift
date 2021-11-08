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
        case settings
        var id: Int { hashValue }
    }
    
    @Environment(\.managedObjectContext) var viewContext
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var purchaseManager: IAPManager
    @Binding var sport: Sport?
    
    @State private var activeSheet: ActiveSheet?
    @State private var selectedWorkout: UUID?
    @State private var isEmpty = false
        
    init(sport: Binding<Sport?>) {
        _sport = sport
    }
    
    func detailDestination(viewModel: WorkoutDetailViewModel) -> some View {
        DetailView(detailManager: DetailManager(viewModel: viewModel, context: viewContext))
    }
            
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 0.0) {
                    WorkoutFilter(sport: sport, interval: nil) { workout in
                        NavigationLink(
                            tag: workout.workoutIdentifier,
                            selection: $selectedWorkout,
                            destination: { detailDestination(viewModel: workout.detailViewModel) }) {
                                WorkoutMapCell(
                                    isFavorite: workout.isFavorite,
                                    viewModel: workout.cellViewModel
                                )
                                    .padding()
                        }
                        .buttonStyle(WorkoutPlainButtonStyle())
                        Divider()
                    }
                }
            }
            .onAppear { validateStatus() }
            .overlay(emptyOverlay())
            .navigationTitle("Workouts")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { activeSheet = .settings }) {
                       Image(systemName: "gearshape")
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
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
            .fullScreenCover(item: $activeSheet) { item in
                switch item {
                case .settings:
                    SettingsView()
                        .environmentObject(purchaseManager)
                }
            }
        }
    }
    
    func validateStatus() {
        isEmpty = workoutManager.totalWorkouts == 0
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
    
    static var purchaseManager = IAPManagerPreview.manager(isActive: true)
    
    @State static var sport: Sport?
    
    static var previews: some View {
        WorkoutsView(sport: $sport)
            .environment(\.managedObjectContext, viewContext)
            .environmentObject(workoutManager)
            .environmentObject(purchaseManager)
            .preferredColorScheme(.light)
    }
}

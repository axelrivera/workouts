//
//  WorkoutsView.swift
//  Workouts
//
//  Created by Axel Rivera on 12/20/20.
//

import SwiftUI
import CoreData

struct WorkoutsView: View {
    typealias FilterAction = (_ sport: Sport?) -> Void
    
    @EnvironmentObject var workoutManager: WorkoutManager
    
    @Binding var sport: Sport? {
        didSet {
            filterAction?(sport)
        }
    }
    
    var interval: DateInterval?
    var showFilter: Bool = true
    var filterAction: FilterAction?
    
    init(sport: Binding<Sport?>, interval: DateInterval? = nil, showFilter: Bool = true) {
        _sport = .constant(nil)
        self.interval = nil
        self.showFilter = true
    }
    
    func detailView(identifier: UUID) -> some View {
        DetailView(identifier: identifier)
    }
            
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0.0) {
                WorkoutFilter(sport: sport, interval: interval) { workout in
                    Group {
                        NavigationLink(destination: detailView(identifier: workout.remoteIdentifier!)) {
                            WorkoutMapCell(workout: workout.workoutData())
                                .padding()
                        }
                        .buttonStyle(WorkoutPlainButtonStyle())
                        Divider()
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if showFilter {
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
        NavigationView {
            WorkoutsView(sport: $sport)
                .navigationTitle("Workouts")
        }
        .environment(\.managedObjectContext, viewContext)
        .environmentObject(workoutManager)
        .preferredColorScheme(.dark)
    }
}

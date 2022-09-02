//
//  StatsContainer.swift
//  Workouts
//
//  Created by Axel Rivera on 3/2/22.
//

import SwiftUI

struct StatsContainer: View {
    enum ActiveCover: Identifiable {
        case settings
        var id: Int { hashValue }
    }
    
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var purchaseManager: IAPManager
    @EnvironmentObject var statsManager: StatsManager
    
    @State var activeCover: ActiveCover?
    
    var body: some View {
        NavigationView {
            ScrollView {
                StatsView()
            }
            .navigationTitle(NSLocalizedString("Progress", comment: "Screen title"))
            .navigationViewStyle(StackNavigationViewStyle())
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { activeCover = .settings }) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .fullScreenCover(item: $activeCover) { item in
                switch item {
                case .settings:
                    SettingsView()
                        .environmentObject(purchaseManager)
                }
            }
        }
    }
}

struct StatsContainer_Previews: PreviewProvider {
    static var viewContext = WorkoutsProvider.preview.container.viewContext
    static var purchaseManager = IAPManagerPreview.manager(isActive: true)
    static var workoutManager: WorkoutManager = {
        let manager = WorkoutManagerPreview.manager(context: viewContext)
        return manager
    }()
    
    static var previews: some View {
        StatsContainer()
            .colorScheme(.dark)
            .environment(\.managedObjectContext, viewContext)
            .environmentObject(StatsManager(context: viewContext))
            .environmentObject(purchaseManager)
            .environmentObject(workoutManager)
    }
}

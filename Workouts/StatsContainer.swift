//
//  StatsContainer.swift
//  Workouts
//
//  Created by Axel Rivera on 3/2/22.
//

import SwiftUI

struct StatsContainer: View {
    enum Page: String, Identifiable, CaseIterable {
        case summary, tags
        var id: String { rawValue }
    }
    
    enum ActiveCover: Identifiable {
        case settings
        var id: Int { hashValue }
    }
    
    @EnvironmentObject var workoutManager: WorkoutManager
    @EnvironmentObject var purchaseManager: IAPManager
    @EnvironmentObject var statsManager: StatsManager
    
    @State var activeCover: ActiveCover?
    @State var page: Page = .summary
    
    var body: some View {
        NavigationView {
            ScrollView {
                StatsView()
            }
            .navigationTitle("Progress")
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
    static var viewContext = StorageProvider.preview.persistentContainer.viewContext
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

//
//  WorkoutsFilterView.swift
//  Workouts
//
//  Created by Axel Rivera on 11/12/21.
//

import SwiftUI

struct WorkoutsFilterView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @EnvironmentObject var manager: WorkoutsFilterManager
    
    @FocusState private var isMinDistanceShowing: Bool
    @FocusState private var isMaxDistanceShowing: Bool
        
    var body: some View {
        NavigationView {
            Form {
                Section(header: header("Workout")) {
                    ForEach(manager.supportedSports) { sport in
                        Button(action: { manager.togggleSport(sport) }) {
                            Label(title: { Text(sport.altName) }) {
                                Image(systemName: manager.isSportSelected(sport) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(sport.color)
                            }
                            .foregroundColor(.primary)
                        }
                    }
                }
                .textCase(nil)
                
                Section {
                    Button(action: { manager.updateWorkoutLocation(for: .indoor) }) {
                        HStack {
                            Text("Indoor")
                                .foregroundColor(.primary)
                            
                            if manager.workoutLocation == .indoor {
                                Spacer()
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                    Button(action: { manager.updateWorkoutLocation(for: .outdoor) }) {
                        HStack {
                            Text("Outdoor")
                                .foregroundColor(.primary)
                            
                            if manager.workoutLocation == .outdoor {
                                Spacer()
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
                
                Section {
                    Toggle(isOn: $manager.showFavorites) {
                        Label("Favorites", systemImage: "heart.fill")
                    }
                    
                    Toggle(isOn: $manager.showDateRange.animation()) {
                        Label("Date Range", systemImage: "calendar")
                    }
                    
                    if manager.showDateRange {
                        DatePicker("Start", selection: $manager.startDate, in: manager.dateRange, displayedComponents: .date)
                        DatePicker("End", selection: $manager.endDate, in: manager.dateRange, displayedComponents: .date)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Distance")
                            .foregroundColor(.secondary)
                        HStack {
                            HStack(spacing: CGFloat(15.0)) {
                                Text("Min")
                                TextField(distanceUnitString(), text: $manager.minDistance)
                                    .focused($isMinDistanceShowing)
                                    .keyboardType(.numberPad)
                            }
                            
                            HStack(spacing: CGFloat(15.0)) {
                                Text("Max")
                                TextField(distanceUnitString(), text: $manager.maxDistance)
                                    .focused($isMaxDistanceShowing)
                                    .keyboardType(.numberPad)
                            }
                        }
                    }
                }
                .textCase(nil)
                
                if manager.tags.isPresent {
                    Section(header: header("Tags")) {
                        ForEach(manager.tags) { tag in
                            Button(action: { manager.toggleTag(tag) }) {
                                HStack(spacing: CGFloat(15.0)) {
                                    Image(systemName: manager.isTagSelected(tag) ? "checkmark.circle" : "circle")
                                        .foregroundColor(tag.color)
                                    Text(tag.name)
                                    Spacer()
                                    GearImage(gearType: tag.gearType)
                                        .foregroundColor(tag.color)
                                }
                                .foregroundColor(.primary)
                            }
                        }
                    }
                    .textCase(nil)
                }
            }
            .interactiveDismissDisabled()
            .onAppear { manager.reloadTags() }
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Reset", action: resetFilter)
                        .tint(.red)
                        .disabled(!manager.isFilterActive)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        NotificationCenter.default.post(name: .refreshWorkoutsFilter, object: nil)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done", action: dismissKeyboard)
                }
                
                ToolbarItem(placement: .status) {
                    Text("\(manager.count().formatted()) Results")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    @ViewBuilder
    func header(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.primary)
            .padding([.top, .bottom])
            .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
}

extension WorkoutsFilterView {
    
    func resetFilter() {
        withAnimation {
            manager.reset()
        }
    }
    
    func dismissKeyboard() {
        isMinDistanceShowing = false
        isMaxDistanceShowing = false
    }
    
}

struct WorkoutsFilterView_Previews: PreviewProvider {
    static let viewContext = StorageProvider.preview.persistentContainer.viewContext
    static let manager = WorkoutsFilterManager(context: viewContext)
    
    static var previews: some View {
        WorkoutsFilterView()
            .environmentObject(manager)
            .preferredColorScheme(.dark)
    }
}

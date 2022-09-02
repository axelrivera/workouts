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
                Section {
                    ForEach(manager.supportedSports) { sport in
                        Button(action: { manager.togggleSport(sport) }) {
                            Label(title: { Text(sport.altName) }) {
                                Image(systemName: manager.isSportSelected(sport) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(sport.color)
                            }
                            .foregroundColor(.primary)
                        }
                    }
                } header: {
                    header(LabelStrings.workout)
                }
                .textCase(nil)
                
                Section {
                    Toggle(isOn: $manager.showFavorites) {
                        Label(LabelStrings.favorites, systemImage: "heart.fill")
                    }
                    
                    Toggle(isOn: $manager.showDateRange.animation()) {
                        Label(LabelStrings.dateRange, systemImage: "calendar")
                    }
                    
                    if manager.showDateRange {
                        DatePicker(LabelStrings.start, selection: $manager.startDate, in: manager.dateRange, displayedComponents: .date)
                        DatePicker(LabelStrings.end, selection: $manager.endDate, in: manager.dateRange, displayedComponents: .date)
                    }
                    
                    VStack(alignment: .leading) {
                        Text(LabelStrings.distance)
                            .foregroundColor(.secondary)
                        HStack {
                            HStack(spacing: CGFloat(15.0)) {
                                Text(LabelStrings.min)
                                TextField(distanceUnitString(), text: $manager.minDistance)
                                    .focused($isMinDistanceShowing)
                                    .keyboardType(.numberPad)
                            }
                            
                            HStack(spacing: CGFloat(15.0)) {
                                Text(LabelStrings.max)
                                TextField(distanceUnitString(), text: $manager.maxDistance)
                                    .focused($isMaxDistanceShowing)
                                    .keyboardType(.numberPad)
                            }
                        }
                        .padding(.bottom, CGFloat(5.0))
                    }
                }
                .textCase(nil)
                
                Section {
                    Button(action: { manager.updateWorkoutLocation(for: .indoor) }) {
                        HStack {
                            Text(LabelStrings.indoor)
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
                            Text(LabelStrings.outdoor)
                                .foregroundColor(.primary)
                            
                            if manager.workoutLocation == .outdoor {
                                Spacer()
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                } header: {
                    header(LabelStrings.location)
                }
                .textCase(nil)
                
                Section {
                    Button(action: { manager.updateDayOfWeek(for: .weekday) }) {
                        HStack {
                            Text(LabelStrings.weekday)
                                .foregroundColor(.primary)
                            
                            if manager.dayOfWeek == .weekday {
                                Spacer()
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                    Button(action: { manager.updateDayOfWeek(for: .weekend) }) {
                        HStack {
                            Text(LabelStrings.weekend)
                                .foregroundColor(.primary)
                            
                            if manager.dayOfWeek == .weekend {
                                Spacer()
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                } header: {
                    header(LabelStrings.dayOfWeek)
                }
                .textCase(nil)
                
                if manager.tags.isPresent {
                    Section {
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
                    } header: {
                        header(LabelStrings.tags)
                    }
                    .textCase(nil)
                }
                
                Section {
                    ForEach(WorkoutsFilterManager.SortBy.allCases, id: \.self) { sort in
                        Button(action: { manager.toggleSort(sort) }) {
                            HStack(spacing: CGFloat(15.0)) {
                                Image(systemName: manager.sortBy == sort ? "checkmark.circle" : "circle")
                                    .foregroundColor(.accentColor)
                                Text(sort.title)
                                if manager.sortBy == sort {
                                    Spacer()
                                    Image(systemName: manager.sortAscending ? "chevron.up" : "chevron.down")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .foregroundColor(.primary)
                        }
                    }
                } header: {
                    header(LabelStrings.sortBy)
                }
                .textCase(nil)
            }
            .interactiveDismissDisabled()
            .onAppear {
                manager.loadSports()
                manager.reloadTags()
                AnalyticsManager.shared.logPage(.workoutsFilter)
            }
            .navigationTitle(LabelStrings.filter)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(ActionStrings.reset, action: resetFilter)
                        .tint(.red)
                        .disabled(!manager.isFilterActive)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(ActionStrings.done) {
                        NotificationCenter.default.post(name: .refreshWorkoutsFilter, object: nil)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(ActionStrings.done, action: dismissKeyboard)
                }
                
                ToolbarItem(placement: .status) {
                    Text(WorkoutStrings.resultsCount(for: manager.count()))
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
    static let viewContext = WorkoutsProvider.preview.container.viewContext
    static let manager = WorkoutsFilterManager(context: viewContext)
    
    static var previews: some View {
        WorkoutsFilterView()
            .environment(\.managedObjectContext, viewContext)
            .environmentObject(manager)
            .preferredColorScheme(.dark)
    }
}

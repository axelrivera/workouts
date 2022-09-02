//
//  DashboardFilterView.swift
//  Workouts
//
//  Created by Axel Rivera on 3/5/22.
//

import SwiftUI

struct DashboardFilterView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @EnvironmentObject var manager: DashboardViewManager
    
    @State private var selected: DashboardViewManager.IntervalType = .month
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker(LabelStrings.intervals, selection: $selected.animation()) {
                        ForEach(DashboardViewManager.IntervalType.allCases, id: \.self) { interval in
                            Text(interval.title)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                .textCase(nil)
                
                if selected == .range {
                    Section {
                        DatePicker(LabelStrings.start, selection: $startDate, in: manager.dateRange, displayedComponents: .date)
                        DatePicker(LabelStrings.end, selection: $endDate, in: manager.dateRange, displayedComponents: .date)
                    } header: {
                        Text(LabelStrings.dates)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding([.top, .bottom])
                            .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                    }
                    .textCase(nil)
                }
            }
            .onAppear {
                load()
                AnalyticsManager.shared.logPage(.dashboardFilter, properties: ["filter": selected.rawValue])
            }
            .navigationTitle(LabelStrings.selectTimeframe)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(ActionStrings.done, action: dismiss)
                }
            }
        }
    }
    
}

extension DashboardFilterView {
    
    func load() {
        selected = manager.currentInterval
        startDate = manager.startDate
        endDate = manager.endDate
    }
    
    func dismiss() {
        manager.currentInterval = selected
        manager.startDate = startDate
        manager.endDate = endDate
        presentationMode.wrappedValue.dismiss()
    }
    
}

struct DashboardFilterView_Previews: PreviewProvider {
    static var manager = DashboardViewManager()
    
    static var previews: some View {
        DashboardFilterView()
            .environmentObject(manager)
    }
}

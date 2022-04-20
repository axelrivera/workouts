//
//  DashboardFilterView.swift
//  Workouts
//
//  Created by Axel Rivera on 3/5/22.
//

import SwiftUI

struct DashboardFilterView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @Binding var selected: DashboardViewManager.IntervalType
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var dateRange: ClosedRange<Date>
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker("Intervals", selection: $selected.animation()) {
                        ForEach(DashboardViewManager.IntervalType.allCases, id: \.self) { interval in
                            Text(interval.title)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                .textCase(nil)
                
                if selected == .range {
                    Section(header: header("Dates")) {
                        DatePicker("Start", selection: $startDate, in: dateRange, displayedComponents: .date)
                        DatePicker("End", selection: $endDate, in: dateRange, displayedComponents: .date)
                    }
                    .textCase(nil)
                }
            }
            .onAppear {
                AnalyticsManager.shared.logPage(.dashboardFilter, properties: ["filter": selected.rawValue])
            }
            .navigationTitle("Select Timeframe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: {presentationMode.wrappedValue.dismiss() })
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

struct DashboardFilterView_Previews: PreviewProvider {
    static let dateRange = Date.distantPast...Date()
    static let interval = DateInterval.lastSixMonths()
    @State static var selected = DashboardViewManager.IntervalType.month
    
    static var previews: some View {
        DashboardFilterView(
            selected: $selected,
            startDate: .constant(interval.start),
            endDate: .constant(interval.end),
            dateRange: .constant(dateRange)
        )
    }
}

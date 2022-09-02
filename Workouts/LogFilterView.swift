//
//  LogFilterView.swift
//  Workouts
//
//  Created by Axel Rivera on 7/27/21.
//

import SwiftUI

struct LogFilterView: View {
    typealias DateFilter = LogManager.DateFilter
    
    @Environment(\.presentationMode) var presentationMode
    
    @Binding var availableSports: [Sport]
    @Binding var dateFilter: DateFilter
    @Binding var filterYear: String
    @Binding var years: [String]
    @Binding var sports: [Sport]
            
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker(LabelStrings.date, selection: $dateFilter.animation()) {
                        ForEach(DateFilter.allCases, id: \.self) { filter in
                            Text(filter.title)
                        }
                    }
                    
                    if dateFilter == .byYear {
                        Picker(LabelStrings.selectYear, selection: $filterYear) {
                            ForEach(years, id: \.self) { year in
                                Text(year)
                            }
                        }
                    }
                }
                
                Section {
                    ForEach(availableSports) { sport in
                        Button(action: { togggleSport(sport) }) {
                            Label(title: { Text(sport.altName) }) {
                                Image(systemName: isSportSelected(sport) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(sport.color)
                            }
                            .foregroundColor(.primary)
                        }
                    }
                } header: {
                    Text(LabelStrings.workout)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding([.top, .bottom])
                        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                }
                .textCase(nil)
            }
            .onAppear(perform: load)
            .navigationTitle(LabelStrings.filter)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(ActionStrings.reset, action: reset)
                        .tint(.red)
                        .disabled(isResetButtonDisabled)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(ActionStrings.done, action: { presentationMode.wrappedValue.dismiss() })
                }
            }
        }
    }
    
}

extension LogFilterView {
    
    func load() {
        AnalyticsManager.shared.logPage(.calendarFilter)
    }
    
    var isResetButtonDisabled: Bool {
        dateFilter == .recentMonths && sports.isEmpty
    }
    
    func reset() {
        withAnimation {
            dateFilter = .recentMonths
            filterYear = years.first ?? ""
            sports = []
        }
    }
    
    func isSportSelected(_ sport: Sport) -> Bool {
        sports.contains(sport)
    }
    
    func togggleSport(_ sport: Sport) {
        if let index = sports.firstIndex(of: sport) {
            sports.remove(at: index)
        } else {
            sports.append(sport)
        }
    }
    
}

struct LogFilterView_Previews: PreviewProvider {
    @State static var dateFilter = LogFilterView.DateFilter.recentMonths
    @State static var filterYear = "2021"
    @State static var years = ["2021", "2020", "2019", "2018", "2017"]
    @State static var availableSports: [Sport] = [.cycling, .running, .walking]
    @State static var sports: [Sport] = []
    
    static var previews: some View {
        LogFilterView(
            availableSports: $availableSports,
            dateFilter: $dateFilter,
            filterYear: $filterYear,
            years: $years,
            sports: $sports
        )
        .preferredColorScheme(.dark)
    }
}

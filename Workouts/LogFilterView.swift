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
    
    @Binding var dateFilter: DateFilter
    @Binding var filterYear: String
    @Binding var years: [String]
    @Binding var sports: [Sport]
        
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker("Date", selection: $dateFilter.animation()) {
                        ForEach(DateFilter.allCases, id: \.self) { filter in
                            Text(filter.title)
                        }
                    }
                    
                    if dateFilter == .byYear {
                        Picker("Select Year", selection: $filterYear) {
                            ForEach(years, id: \.self) { year in
                                Text(year)
                            }
                        }
                    }
                }
                
                Section(header: Text("Workout")) {
                    ForEach(Sport.supportedSports) { sport in
                        Button(action: { togggleSport(sport) }) {
                            Label(title: { Text(sport.altName) }) {
                                Image(systemName: isSportSelected(sport) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(sport.color)
                            }
                            .foregroundColor(.primary)
                        }
                    }
                }
            }
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done", action: { presentationMode.wrappedValue.dismiss() })
                }
            }
        }
    }
    
}

extension LogFilterView {
    
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
    @State static var sports: [Sport] = [.cycling, .running]
    
    static var previews: some View {
        LogFilterView(
            dateFilter: $dateFilter,
            filterYear: $filterYear,
            years: $years,
            sports: $sports
        )
        .preferredColorScheme(.dark)
    }
}

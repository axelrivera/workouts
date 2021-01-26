//
//  DetailView.swift
//  Workouts
//
//  Created by Axel Rivera on 12/20/20.
//

import SwiftUI
import MapKit

struct DetailView: View {
    @ObservedObject var workout: Workout
    
    var body: some View {
        Form {
            Section {
                TextRow(item: RowItem(text: "Date", detail: dateString))
                TextRow(item: RowItem(text: "Start", detail: startTimeString))
                TextRow(item: RowItem(text: "Moving Time", detail: "TODO"))
                TextRow(item: RowItem(text: "Elapsed Time", detail: elapsedTimeString))
            }
            Section(header: Text("Distance")) {
                TextRow(item: RowItem(text: "Distance", detail: workout.distanceString))
            }
            Section(header: Text("Speed")) {
                TextRow(item: RowItem(text: "Avg. Speed", detail: "10 MPH"))
                TextRow(item: RowItem(text: "Max. Speed", detail: "10 MPH"))
            }
            Section(header: Text("Heart Rate")) {
                TextRow(item: RowItem(text: "Avg. Heart Rate", detail: "130 BPM"))
                TextRow(item: RowItem(text: "Max Heart Rate", detail: "150 BPM"))
            }
        }
        .navigationTitle("Workout Detail")
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(InsetGroupedListStyle())
    }
}

extension DetailView {
    private static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
    
    private static var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    
    var dateString: String {
        Self.dateFormatter.string(from: workout.startDate)
    }
    
    var startTimeString: String {
        Self.timeFormatter.string(from: workout.startDate)
    }
    
    var elapsedTimeString: String {
        formattedTimer(for: Int(workout.elapsedTime))
    }
    
}

struct DetailView_Previews: PreviewProvider {
    static var workout = Workout.sample
    
    static var previews: some View {
        DetailView(workout: Workout.sample)
    }
}

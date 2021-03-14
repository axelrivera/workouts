//
//  DetailAnalysisView.swift
//  Workouts
//
//  Created by Axel Rivera on 3/1/21.
//

import SwiftUI

struct DetailAnalysisView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject var workout: Workout
    @ObservedObject var detailManager: DetailManager
    
    var avgSpeed: Double? {
        guard let avgSpeed = workout.avgSpeed else { return nil }
        return nativeSpeedToLocalizedUnit(for: avgSpeed)
    }
    
    var avgCadence: Double? {
        guard let avgCadence = workout.avgCyclingCadence else { return nil }
        return avgCadence
    }
    
    var workoutTitle: String {
        let distanceStr = formattedDistanceString(for: workout.distance)
        let titleStr = workout.title
        return String(format: "%@ %@", distanceStr, titleStr)
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    chart(
                        for: "Speed",
                        supportLabel1: "Average", supportValue1: formattedSpeedString(for: workout.avgSpeed),
                        supportLabel2: "Maximum", supportValue2: formattedSpeedString(for: workout.maxSpeed),
                        values: detailManager.speedValues, avgValue: avgSpeed,
                        accentColor: .speed
                    )
                    
                    rowForText(
                        "Total Time",
                        detail: formattedHoursMinutesDurationString(for: workout.elapsedTime, includeSeconds: true)
                    )
                    rowForText(
                        "Moving Time",
                        detail: formattedHoursMinutesDurationString(for: detailManager.movingTime, includeSeconds: true)
                    )
                }
                
                Section {
                    chart(
                        for: "Heart Rate",
                        supportLabel1: "Average", supportValue1: formattedHeartRateString(for: detailManager.avgHeartRate),
                        supportLabel2: "Maximum", supportValue2: formattedHeartRateString(for: detailManager.maxHeartRate),
                        values: detailManager.heartRateValues, avgValue: detailManager.avgHeartRate,
                        accentColor: .calories
                    )
                }
                
                if workout.isCadencePresent {
                    Section {
                        chart(
                            for: "Cadence",
                            supportLabel1: "Average", supportValue1: formattedCyclingCadenceString(for: workout.avgCyclingCadence),
                            supportLabel2: "Maximum", supportValue2: formattedCyclingCadenceString(for: workout.maxCyclingCadence),
                            values: detailManager.cyclingCadenceValues, avgValue: avgCadence,
                            accentColor: .cadence
                        )
                    }
                }
                
                Section {
                    chart(
                        for: "Elevation",
                        supportLabel1: "Minimum", supportValue1: formattedElevationString(for: detailManager.minElevation),
                        supportLabel2: "Maximum", supportValue2: formattedElevationString(for: detailManager.maxElevation),
                        values: detailManager.altitudeValues, avgValue: nil,
                        accentColor: .elevation
                    )
                    
                    rowForText("Elevation Gain", detail: formattedElevationString(for: workout.elevationAscended))
                    rowForText("Elevation Loss", detail: formattedElevationString(for: workout.elevationDescended))
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle(workoutTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Text("Done")
                    }
                }
            }
        }
    }
}

extension DetailAnalysisView {
    
    func chart(for title: String, supportLabel1: String, supportValue1: String, supportLabel2: String, supportValue2: String, values: [ChartValue], avgValue: Double?, accentColor: Color) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.title3)
                .padding([.top, .bottom], 8.0)
                                    
            HStack {
                VStack(spacing: 5.0) {
                    Text(supportLabel1)
                        .font(.callout)
                        .foregroundColor(.secondary)
                    Text(supportValue1)
                        .foregroundColor(accentColor)
                        .font(.title2)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                
                VStack(spacing: 5.0) {
                    Text(supportLabel2)
                        .font(.callout)
                        .foregroundColor(.secondary)
                    Text(supportValue2)
                        .font(.title2)
                        .foregroundColor(accentColor)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            
            lineChart(values: values, avg: avgValue, color: accentColor)
        }
    }

    func lineChart(values: [ChartValue], avg: Double?, color: Color) -> some View {
        LineChart(values: values, avgValue: avg, lineColor: color)
            .frame(maxWidth: .infinity, minHeight: 200.0)
    }
    
    func rowForText(_ text: String, detail: String) -> some View {
        HStack {
            Text(text)
            Spacer()
            Text(detail)
                .foregroundColor(.secondary)
        }
    }

}

struct DetailAnalysisView_Previews: PreviewProvider {
    static let workout = Workout.sample
    
    static let detailManager: DetailManager = {
        let manager = DetailManager(workoutID: workout.id)
        manager.speedValues = ChartValue.speedSamples
        manager.heartRateValues = ChartValue.heartRateSamples
        manager.cyclingCadenceValues = ChartValue.cyclingCadenceSamples
        manager.altitudeValues = ChartValue.cyclingCadenceSamples
        return manager
    }()
    
    static var previews: some View {
        DetailAnalysisView(workout: workout, detailManager: detailManager)
            .colorScheme(.dark)
        
    }
}

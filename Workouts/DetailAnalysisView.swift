//
//  DetailAnalysisView.swift
//  Workouts
//
//  Created by Axel Rivera on 3/1/21.
//

import SwiftUI
import Charts

struct DetailAnalysisView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var detailManager: DetailManager
    
    var localizedAvgSpeed: Double? {
        nativeSpeedToLocalizedUnit(for: workout.avgSpeed)
    }
    
    var workout: Workout {
        detailManager.workout
    }
    
    var workoutTitle: String {
        let distanceStr = formattedDistanceString(for: workout.distance)
        let titleStr = workout.title
        return String(format: "%@ %@", distanceStr, titleStr)
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Color.clear.frame(width: 0, height: 20.0)) {
                    rowForText("Total Time", detail: formattedHoursMinutesSecondsDurationString(for: workout.duration), detailColor: .time)
                    
                    if workout.movingTime > 0 && workout.movingTime < workout.duration {
                        rowForText("Moving Time", detail: formattedHoursMinutesSecondsDurationString(for: workout.movingTime), detailColor: .time)
                    }
                    
                    if workout.sport.isWalkingOrRunning && detailManager.avgPace > 0 {
                        rowForText("Avg Pace", detail: formattedRunningWalkingPaceString(for: detailManager.avgPace), detailColor: .cadence)
                    }
                }
                
                if workout.sport.isSpeedSport && workout.showMap && workout.avgSpeed > 0 {
                    Section(header: Text("Speed")) {
                        if detailManager.speedValues.isPresent {
                            chart(
                                supportLabel1: "Average", supportValue1: formattedSpeedString(for: workout.avgSpeed),
                                supportLabel2: "Maximum", supportValue2: formattedSpeedString(for: workout.maxSpeed),
                                values: detailManager.speedValues, avgValue: localizedAvgSpeed,
                                accentColor: .speed
                            )
                        } else {
                            rowForText("Avg Speed", detail: formattedSpeedString(for: workout.avgSpeed), detailColor: .speed)
                            
                            if workout.maxSpeed > 0 {
                                rowForText("Max Speed", detail: formattedSpeedString(for: workout.maxSpeed), detailColor: .speed)
                            }
                            
                        }
                        
                        if workout.avgMovingSpeed > 0 {
                            rowForText(
                                "Avg Moving Speed",
                                detail: formattedSpeedString(for: workout.avgMovingSpeed),
                                detailColor: .speed
                            )
                        }
                    }
                }
                
                if workout.avgHeartRate > 0 {
                    Section(header: Text("Heart Rate")) {
                        if detailManager.heartRateValues.isPresent {
                            chart(
                                supportLabel1: "Average", supportValue1: formattedHeartRateString(for: workout.avgHeartRate),
                                supportLabel2: "Maximum", supportValue2: formattedHeartRateString(for: workout.maxHeartRate),
                                values: detailManager.heartRateValues, avgValue: workout.avgHeartRate,
                                accentColor: .calories
                            )
                        } else {
                            rowForText("Avg Heart Rate", detail: formattedHeartRateString(for: workout.avgHeartRate), detailColor: .calories)
                            
                            if workout.maxHeartRate > 0 {
                                rowForText("Max Heart Rate", detail: formattedHeartRateString(for: workout.maxHeartRate), detailColor: .calories)
                            }
                        }
                    }
                }

                if workout.sport.isCycling && workout.avgCyclingCadence > 0 {
                    Section(header: Text("Cadence")) {
                        if detailManager.cyclingCadenceValues.isPresent {
                            chart(
                                supportLabel1: "Average", supportValue1: formattedCyclingCadenceString(for: workout.avgCyclingCadence),
                                supportLabel2: "Maximum", supportValue2: formattedCyclingCadenceString(for: workout.maxCyclingCadence),
                                values: detailManager.cyclingCadenceValues, avgValue: workout.avgCyclingCadence,
                                accentColor: .cadence
                            )
                        } else {
                            rowForText("Avg Cadence", detail: formattedCyclingCadenceString(for: workout.avgCyclingCadence), detailColor: .cadence)
                            
                            if workout.maxCyclingCadence > 0 {
                                rowForText("Max Cycling Cadence", detail: formattedCyclingCadenceString(for: workout.maxCyclingCadence), detailColor: .cadence)
                            }
                        }
                    }
                }

                if (detailManager.showMap && detailManager.altitudeValues.isPresent) || (workout.elevationAscended > 0 || workout.elevationDescended > 0) {
                    Section(header: Text("Elevation")) {
                        if detailManager.altitudeValues.isPresent {
                            chart(
                                supportLabel1: "Minimum", supportValue1: formattedElevationString(for: detailManager.minElevation),
                                supportLabel2: "Maximum", supportValue2: formattedElevationString(for: detailManager.maxElevation),
                                values: detailManager.altitudeValues, avgValue: nil,
                                accentColor: .elevation
                            )
                        }
                        
                        if abs(workout.elevationAscended) > 0 {
                            rowForText("Elevation Gain", detail: formattedElevationString(for: workout.elevationAscended), detailColor: .elevation)
                        }
                        
                        if abs(workout.elevationDescended) > 0 {
                            rowForText("Elevation Loss", detail: formattedElevationString(for: workout.elevationDescended), detailColor: .elevation)
                        }
                    }
                }
            }
            .listStyle(GroupedListStyle())
            .navigationTitle(workoutTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Text("Done")
                    }
                }
            }
            
        }
    }
}

extension DetailAnalysisView {
    
    func chart(supportLabel1: String, supportValue1: String, supportLabel2: String, supportValue2: String, values: [ChartInterval], avgValue: Double?, accentColor: Color, yAxisFormatter: AxisValueFormatter? = nil) -> some View {
        VStack(alignment: .leading) {
            if supportValue1.isPresent || supportValue2.isPresent {
                HStack {
                    if supportValue1.isPresent {
                        VStack(spacing: 5.0) {
                            Text(supportLabel1)
                                .font(.callout)
                                .foregroundColor(.secondary)
                            Text(supportValue1)
                                .foregroundColor(accentColor)
                                .font(.title2)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    
                    if supportValue2.isPresent {
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
                }
                .padding()
            }
            
            lineChart(values: values, avg: avgValue, color: accentColor, yAxisFormatter: yAxisFormatter)
        }
    }

    func lineChart(values: [ChartInterval], avg: Double?, color: Color, yAxisFormatter: AxisValueFormatter? = nil) -> some View {
        LineChart(values: values, avgValue: avg, lineColor: color, yAxisFormatter: yAxisFormatter)
            .frame(maxWidth: .infinity, minHeight: 200.0)
    }
    
    func rowForText(_ text: String, detail: String, detailColor: Color = .secondary) -> some View {
        HStack {
            Text(text)
            Spacer()
            Text(detail)
                .foregroundColor(detailColor)
        }
    }

}

struct DetailAnalysisView_Previews: PreviewProvider {
    static let workout = StorageProvider.sampleWorkout()
    
    static var previews: some View {
        DetailAnalysisView()
            .environmentObject(DetailManager(workout: workout))
            .colorScheme(.dark)
        
    }
}

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
    
    @ObservedObject var workout: Workout
    @ObservedObject var detailManager: DetailManager
    
    var localizedAvgSpeed: Double? {
        nativeSpeedToLocalizedUnit(for: workout.avgSpeed)
    }
    
    var workoutTitle: String {
        let distanceStr = formattedDistanceString(for: workout.distance)
        let titleStr = workout.title
        return String(format: "%@ %@", distanceStr, titleStr)
    }
    
    var isElevationPresent: Bool {
        detailManager.altitudeValues.isPresent
    }
    
    var isHeartRatePresent: Bool {
        detailManager.heartRateValues.isPresent
    }
    
    var isSpeedPresent: Bool {
        detailManager.speedValues.isPresent
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Text("Total Time")
                        Spacer()
                        Text(formattedHoursMinutesDurationString(for: workout.elapsedTime))
                            .foregroundColor(.time)
                    }
                    
                    if workout.movingTime > 0 {
                        HStack {
                            Text("Moving Time")
                            Spacer()
                            Text(formattedHoursMinutesDurationString(for: workout.movingTime))
                                .foregroundColor(.time)
                        }
                    }
                }
                
                if isSpeedPresent {
                    Section {
                        chart(
                            for: "Speed",
                            supportLabel1: "Average", supportValue1: formattedSpeedString(for: workout.avgSpeed),
                            supportLabel2: "Maximum", supportValue2: formattedSpeedString(for: workout.maxSpeed),
                            values: detailManager.speedValues, avgValue: localizedAvgSpeed,
                            accentColor: .speed
                        )
                        
//                        if detailManager.avgMovingSpeed > 0 {
//                            rowForText(
//                                "Avg Moving Speed",
//                                detail: formattedSpeedString(for: detailManager.avgMovingSpeed),
//                                detailColor: .speed
//                            )
//                        }
                    }
                }
                
//                if workout.isPacePresent {
//                    Section {
//                        chart(
//                            for: "Pace",
//                            supportLabel1: "Average", supportValue1: formattedRunningWalkingPaceString(for: workout.avgPace),
//                            supportLabel2: "Best", supportValue2: formattedRunningWalkingPaceString(for: detailManager.bestPace),
//                            values: detailManager.paceValues, avgValue: workout.avgPace,
//                            accentColor: .cadence,
//                            yAxisFormatter: PaceValueFormatter()
//                        )
//                    }
//                }
                
                if workout.avgHeartRate > 0 || workout.maxHeartRate > 0 {
                    Section {
                        chart(
                            for: "Heart Rate",
                            supportLabel1: "Average", supportValue1: formattedHeartRateString(for: workout.avgHeartRate),
                            supportLabel2: "Maximum", supportValue2: formattedHeartRateString(for: workout.maxHeartRate),
                            values: detailManager.heartRateValues, avgValue: workout.avgHeartRate,
                            accentColor: .calories
                        )
                    }
                }

                if workout.avgCyclingCadence > 0 || workout.maxCyclingCadence > 0 {
                    Section {
                        chart(
                            for: "Cadence",
                            supportLabel1: "Average", supportValue1: formattedCyclingCadenceString(for: workout.avgCyclingCadence),
                            supportLabel2: "Maximum", supportValue2: formattedCyclingCadenceString(for: workout.maxCyclingCadence),
                            values: detailManager.cyclingCadenceValues, avgValue: workout.avgCyclingCadence,
                            accentColor: .cadence
                        )
                    }
                }

                if isElevationPresent {
                    Section {
                        chart(
                            for: "Elevation",
                            supportLabel1: "Minimum", supportValue1: formattedElevationString(for: detailManager.minElevation),
                            supportLabel2: "Maximum", supportValue2: formattedElevationString(for: detailManager.maxElevation),
                            values: detailManager.altitudeValues, avgValue: nil,
                            accentColor: .elevation
                        )
                        
                        if let elevation = workout.elevationAscended {
                            rowForText("Elevation Gain", detail: formattedElevationString(for: elevation), detailColor: .elevation)
                        }
                        
                        if let elevation = workout.elevationDescended {
                            rowForText("Elevation Loss", detail: formattedElevationString(for: elevation), detailColor: .elevation)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
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
    
    func chart(for title: String, supportLabel1: String, supportValue1: String, supportLabel2: String, supportValue2: String, values: [ChartInterval], avgValue: Double?, accentColor: Color, yAxisFormatter: AxisValueFormatter? = nil) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.title3)
                .padding([.top, .bottom], 8.0)
            
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
            }
            
            if values.count > 5 {
                lineChart(values: values, avg: avgValue, color: accentColor, yAxisFormatter: yAxisFormatter)
            } else {
                Spacer()
                    .frame(maxWidth: .infinity, maxHeight: 10.0)
            }
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
    static let viewContext = StorageProvider.preview.persistentContainer.viewContext
    static let workout = Workout(context: viewContext)
    
    static let detailManager: DetailManager = {
        let manager = DetailManager(workout: workout, context: viewContext)
        return manager
    }()
    
    static var previews: some View {
        DetailAnalysisView(workout: workout, detailManager: detailManager)
            .colorScheme(.dark)
        
    }
}

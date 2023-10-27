//
//  DetailAnalysisView.swift
//  Workouts
//
//  Created by Axel Rivera on 3/1/21.
//

import SwiftUI
import DGCharts
import CoreData

struct AnalysisView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var detailManager: DetailManager
        
    var localizedAvgSpeed: Double? {
        nativeSpeedToLocalizedUnit(for: workout.avgMovingSpeed)
    }
    
    var workout: WorkoutDetailViewModel {
        detailManager.detail
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    rowForText(LabelStrings.totalTime, detail: formattedHoursMinutesSecondsDurationString(for: workout.duration), detailColor: .time)
                    
                    if workout.shouldUseMovingTime {
                        rowForText(LabelStrings.movingTime, detail: formattedHoursMinutesSecondsDurationString(for: workout.movingTime), detailColor: .time)
                        rowForText(LabelStrings.pausedTime, detail: formattedHoursMinutesSecondsDurationString(for: workout.pausedTime), detailColor: .time)
                    }
                }
                
                if workout.sport.isSpeedSport && workout.avgSpeed > 0 {
                    Section {
                        if detailManager.speedValues.isPresent {
                            chartArea(
                                valueType: .speed,
                                supportLabel1: LabelStrings.average, supportValue1: formattedSpeedString(for: workout.avgMovingSpeed),
                                supportLabel2: LabelStrings.maximum, supportValue2: formattedSpeedString(for: workout.maxSpeed),
                                values: detailManager.speedValues, avgValue: localizedAvgSpeed,
                                accentColor: .speed
                            )
                        } else {
                            rowForText(LabelStrings.avgSpeed, detail: formattedSpeedString(for: workout.avgMovingSpeed), detailColor: .speed)
                            
                            if workout.maxSpeed > 0 {
                                rowForText(LabelStrings.maxSpeed, detail: formattedSpeedString(for: workout.maxSpeed), detailColor: .speed)
                            }
                            
                        }
                    } header: {
                        Text(LabelStrings.speed)
                    }
                }
                
                if workout.sport.isWalkingOrRunning && workout.avgPace > 0 {
                    Section {
                        if detailManager.paceValues.isPresent {
                            chartArea(
                                valueType: .pace,
                                supportLabel1: LabelStrings.average, supportValue1: formattedRunningWalkingPaceString(for: workout.avgPace),
                                supportLabel2: LabelStrings.best, supportValue2: formattedRunningWalkingPaceString(for: detailManager.bestPace),
                                values: detailManager.paceValues, avgValue: workout.avgPace,
                                accentColor: .pace
                            )
                        } else {
                            rowForText(LabelStrings.avgPace, detail: formattedRunningWalkingPaceString(for: workout.avgPace), detailColor: .pace)
                        }
                    } header: {
                        Text(LabelStrings.pace)
                    }
                }
                
                if workout.avgHeartRate > 0 {
                    Section {
                        if detailManager.heartRateValues.isPresent {
                            chartArea(
                                valueType: .heartRate,
                                supportLabel1: LabelStrings.average, supportValue1: formattedHeartRateString(for: workout.avgHeartRate),
                                supportLabel2: LabelStrings.maximum, supportValue2: formattedHeartRateString(for: workout.maxHeartRate),
                                values: detailManager.heartRateValues, avgValue: workout.avgHeartRate,
                                accentColor: .calories
                            )
                        } else {
                            rowForText(LabelStrings.avgHeartRate, detail: formattedHeartRateString(for: workout.avgHeartRate), detailColor: .calories)
                            
                            if workout.maxHeartRate > 0 {
                                rowForText(LabelStrings.maxHeartRate, detail: formattedHeartRateString(for: workout.maxHeartRate), detailColor: .calories)
                            }
                        }
                    } header: {
                        Text(LabelStrings.heartRate)
                    }
                    
                    if detailManager.zones.isPresent {
                        Section {
                            HRZonesView(summaries: detailManager.zones)
                                .padding([.top, .bottom])
                        } header: {
                            Text(LabelStrings.heartRateZones)
                        }
                    }
                }

                if workout.sport.isCycling && workout.avgCyclingCadence > 0 {
                    Section {
                        if detailManager.cyclingCadenceValues.isPresent {
                            chartArea(
                                valueType: .cadence,
                                supportLabel1: LabelStrings.average, supportValue1: formattedCyclingCadenceString(for: workout.avgCyclingCadence),
                                supportLabel2: LabelStrings.maximum, supportValue2: formattedCyclingCadenceString(for: workout.maxCyclingCadence),
                                values: detailManager.cyclingCadenceValues, avgValue: workout.avgCyclingCadence,
                                accentColor: .cadence
                            )
                        } else {
                            rowForText(LabelStrings.avgCadence, detail: formattedCyclingCadenceString(for: workout.avgCyclingCadence), detailColor: .cadence)
                            
                            if workout.maxCyclingCadence > 0 {
                                rowForText(LabelStrings.maxCadence, detail: formattedCyclingCadenceString(for: workout.maxCyclingCadence), detailColor: .cadence)
                            }
                        }
                    } header: {
                        Text(LabelStrings.cadence)
                    }
                }

                if detailManager.includesLocation || (showElevationAscended || showElevationDescended) {
                    Section {
                        if detailManager.includesLocation {
                            chartArea(
                                valueType: .altitude,
                                supportLabel1: LabelStrings.minimum, supportValue1: formattedElevationString(for: detailManager.detail.minElevation),
                                supportLabel2: LabelStrings.maximum, supportValue2: formattedElevationString(for: detailManager.detail.maxElevation),
                                values: detailManager.altitudeValues, avgValue: nil,
                                accentColor: .elevation
                            )
                        }
                        
                        if showElevationAscended {
                            rowForText(LabelStrings.elevationGain, detail: formattedElevationString(for: workout.elevationAscended), detailColor: .elevation)
                        }
                        
                        if showElevationDescended {
                            rowForText(LabelStrings.elevationLoss, detail: formattedElevationString(for: workout.elevationDescended), detailColor: .elevation)
                        }
                    } header: {
                        Text(LabelStrings.elevation)
                    }
                }
            }
            .onAppear { AnalyticsManager.shared.logPage(.workoutAnalysis) }
            .loadingView(isVisible: detailManager.isProcessingAnalysis)
            .listStyle(GroupedListStyle())
            .navigationTitle(workout.analysisTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Text(ActionStrings.done)
                    }
                }
            }
        }
    }
}

extension AnalysisView {
    
    var showElevationAscended: Bool {
        abs(workout.elevationAscended) > 0
    }
    
    var showElevationDescended: Bool {
        abs(workout.elevationDescended) > 0
    }
    
    func chartArea(valueType: ChartInterval.ValueType, supportLabel1: String, supportValue1: String, supportLabel2: String, supportValue2: String, values: [ChartInterval], avgValue: Double?, accentColor: Color) -> some View {
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
            
            chart(
                valueType: valueType,
                values: values,
                avg: avgValue
            )
        }
    }

    @ViewBuilder
    func chart(valueType: ChartInterval.ValueType, values: [ChartInterval], avg: Double?) -> some View {
        if valueType == .cadence {
            ScatterChart(values: values, avgValue: avg, lineColor: .cadence, yAxisFormatter: nil)
                .frame(maxWidth: .infinity, minHeight: 200.0)
        } else {
            LineChart(valueType: valueType, values: values, avg: avg)
                .frame(maxWidth: .infinity, minHeight: 200.0)
        }
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
    static let viewContext = WorkoutsProvider.preview.container.viewContext
    static let workout = WorkoutsProvider.sampleWorkout(moc: viewContext)
    
    static var previews: some View {
        AnalysisView()
            .environment(\.managedObjectContext, viewContext)
            .environmentObject(DetailManager(id: workout.workoutIdentifier, context: viewContext))
            .colorScheme(.dark)
        
    }
}

//
//  LogBubbleRow.swift
//  Workouts
//
//  Created by Axel Rivera on 8/1/21.
//

import SwiftUI
import CoreData

struct TextCircleModifier: ViewModifier {
    let isToday: Bool
    var textColor: Color = .primary
    var color: Color = .systemFill
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(isToday ? textColor : .secondary)
            .padding(.all, 7.0)
            .background(isToday ? color : .clear)
            .clipShape(Circle())
    }
    
}

struct WorkoutLogIntervalStack: View {
    @Binding var displayType: LogDisplayType
    var interval: LogInterval
    let totalActivities: Int
    
    var isEmpty: Bool {
        totalActivities == 0
    }
    
    init(displayType: Binding<LogDisplayType>, interval: LogInterval) {
        _displayType = displayType
        self.interval = interval
        self.totalActivities = interval.totalActivities
    }
    
    var body: some View {
        HStack {
            ForEach(interval.days) { day in
                WorkoutLogItem(displayType: $displayType, day: day, hideBubble: isEmpty)
            }
        }
        .frame(height: 80)
        .overlay(overlayIfNeeded())
    }
    
    @ViewBuilder
    func overlayIfNeeded() -> some View {
        if isEmpty {
            Text("No Workouts")
                .offset(x: 0, y: -20.0)
                .foregroundColor(.secondary)
        }
    }
    
}

struct WorkoutLogIntervalRow: View {
    @Binding var displayType: LogDisplayType
    var interval: LogInterval
    let totalActivities: Int
    let showContent: Bool
    
    init(displayType: Binding<LogDisplayType>, interval: LogInterval, showContent: Bool = true) {
        _displayType = displayType
        self.interval = interval
        self.totalActivities = interval.totalActivities
        self.showContent = showContent
    }
    
    var body: some View {
        VStack {
            HStack {
                Text(interval.header).animation(.none)
                Spacer()
                Text(headerText(for: interval))
                    .animation(.none)
                    .foregroundColor(displayType.color)
            }
            .padding([.top, .bottom], 10.0)
            
            HStack {
                ForEach(interval.days) { day in
                    if showContent {
                        WorkoutLogItem(displayType: $displayType, day: day, hideBubble: false)
                    } else {
                        WorkoutLogItem(displayType: $displayType, day: LogDay.randomDay(date: day.date), hideBubble: false)
                    }
                }
            }
            .frame(height: 80)
        }
        .padding([.leading, .trailing], 15.0)
    }
    
    func headerText(for interval: LogInterval) -> String {
        switch displayType {
        case .load:
            let value = showContent ? interval.trimp : 0
            return value.formatted()
        case .distance:
            let value = showContent ? interval.distance : 0
            return formattedDistanceString(for: value, zeroPadding: true)
        case .time:
            let value = showContent ? interval.duration : 0
            return formattedHoursMinutesPrettyString(for: value)
        }
    }
    
}

struct WorkoutLogItem: View {
    let maxWidth: CGFloat = 50
    
    @Environment(\.managedObjectContext) var viewContext
    
    @Binding var displayType: LogDisplayType
    var day: LogDay
    var hideBubble: Bool = false
    let totalActivities: Int
    
    var isEmpty: Bool { totalActivities == 0 }
    
    init(displayType: Binding<LogDisplayType>, day: LogDay, hideBubble: Bool = false) {
        _displayType = displayType
        self.day = day
        self.hideBubble = hideBubble
        totalActivities = day.totalActivities
    }
    
    var body: some View {
        VStack(spacing: 5.0) {
            NavigationLink(destination: destinationView()) {
                LogBubble(color: day.color, scaleFactor: scaleFactor)
                    .overlay(bubbleOverlay())
                    .frame(idealWidth: maxWidth, idealHeight: maxWidth, alignment: .center)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isEmpty)
            .opacity(hideBubble ? 0.0 : 1.0)
            
            Text(day.label)
                .font(.footnote)
                .modifier(TextCircleModifier(isToday: day.date.isToday))
        }
    }
    
    @ViewBuilder
    func destinationView() -> some View {
        if let identifier = day.remoteIdentifiers.first, day.totalActivities == 1 {
            DetailView(workoutID: identifier)
        } else {
            StatsWorkoutsView(identifiers: day.remoteIdentifiers)
                .navigationTitle("Workouts")
        }
    }
}

extension WorkoutLogItem {
    
    @ViewBuilder
    func bubbleOverlay() -> some View {
        if displayType == .distance {
            if day.distance > 0 {
                Text(text)
                    .font(.system(size: 10))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.9)
                    .padding(3)
            }
        } else {
            if day.hasActivities {
                Text(text)
                    .font(.system(size: 10))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.9)
                    .padding(3)
            }
        }
    }
    
    var text: String {
        switch displayType {
        case .load:
            return day.trimp.formatted()
        case .distance:
            let measurement = Measurement<UnitLength>(value: day.distance, unit: .meters)
            let conversion = measurement.converted(to: Locale.isMetric() ? .kilometers : .miles)
            
            return String(format: "%0.1f", conversion.value)
        case .time:
            let duration = day.duration
            if duration > 0 {
                let (h, m, _) = secondsToHoursMinutesSeconds(seconds: Int(day.duration))
                return String(format: "%d:%02d", h, m)
            } else {
                return "0"
            }
        }
    }
    
    var value: CGFloat {
        switch displayType {
        case .load:
            return CGFloat(day.trimp)
        case .distance:
            return CGFloat(day.distance)
        case .time:
            return CGFloat(day.duration)
        }
    }
    
    var scaleFactor: CGFloat {
        guard day.hasActivities else { return 0.1 }
        
        if displayType == .distance && day.distance == 0 {
            return 0.3
        }
        
        let preferredSport = day.distancePreferredSport
        switch displayType {
        case .load:
            return CGFloat(logScaleFactorForLoad(day.trimp))
        case .distance where preferredSport == .cycling:
            return CGFloat(logScaleFactorForCyclingDistance(for: day.distance))
        case .distance where preferredSport == .running:
            return CGFloat(logScaleFactorForRunningDistance(for: day.distance))
        case .distance where preferredSport == .walking:
            return CGFloat(logScaleFactorForWalkingDistance(for: day.distance))
        case .time:
            return CGFloat(logScaleFactorForTime(day.duration))
        default:
            return 0.5
        }
    }
    
}

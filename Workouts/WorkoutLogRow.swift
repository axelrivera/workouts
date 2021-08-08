//
//  LogBubbleRow.swift
//  Workouts
//
//  Created by Axel Rivera on 8/1/21.
//

import SwiftUI

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
            Text("No Workouts this Week")
                .offset(x: 0, y: -20.0)
                .foregroundColor(.secondary)
        }
    }
    
}

struct WorkoutLogGridSection: View {
    @Binding var displayType: LogDisplayType
    var interval: LogInterval
    
    var body: some View {
        Section(header: header(interval: interval)) {
            Group {
                ForEach(interval.days, id: \.self) { day in
                    WorkoutLogItem(displayType: $displayType, day: day)
                }
            }
            .padding(.horizontal, 5.0)
        }
    }
    
    func header(interval: LogInterval) -> some View {
        HStack {
            Text(interval.header).animation(.none)
            Spacer()
            Text(headerText(for: interval))
                .animation(.none)
                .foregroundColor(displayType.color)
        }
        .padding(.all, 10.0)
        .background(Color.secondarySystemBackground)
    }
    
    func headerText(for interval: LogInterval) -> String {
        switch displayType {
        case .distance: return formattedDistanceString(for: interval.distance, zeroPadding: true)
        case .time: return formattedHoursMinutesPrettyString(for: interval.duration)
        }
    }
}

struct WorkoutLogItem: View {
    let maxWidth: CGFloat = 50
    
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
            DetailView(identifier: identifier)
        } else {
            List {
                WorkoutFilter(identifiers: day.remoteIdentifiers) { workout in
                    NavigationLink(destination: DetailView(identifier: workout.remoteIdentifier!)) {
                        WorkoutPlainCell(workout: workout)
                    }
                }
            }
            .listStyle(PlainListStyle())
            .navigationBarTitle("Workouts")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

extension WorkoutLogItem {
    
    @ViewBuilder
    func bubbleOverlay() -> some View {
        if day.hasActivities {
            Text(text)
                .font(.system(size: 10))
                .foregroundColor(.white)
                .minimumScaleFactor(0.9)
                .padding(3)
        }
    }
    
    var text: String {
        switch displayType {
        case .distance:
            let measurement = Measurement<UnitLength>(value: day.distance, unit: .meters)
            let conversion = measurement.converted(to: Locale.isMetric() ? .kilometers : .miles)
            
            return String(format: "%0.1f", conversion.value)
        case .time:
            let (h, m, _) = secondsToHoursMinutesSeconds(seconds: Int(day.duration))
            return String(format: "%d:%02d", h, m)
        }
    }
    
    var value: CGFloat {
        switch displayType {
        case .distance: return CGFloat(day.distance)
        case .time: return CGFloat(day.duration)
        }
    }
    
    var scaleFactor: CGFloat {
        guard day.hasActivities else { return 0.1 }
        
        let preferredSport = day.distancePreferredSport
        switch displayType {
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

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
    
    init(displayType: Binding<LogDisplayType>, interval: LogInterval) {
        _displayType = displayType
        self.interval = interval
        self.totalActivities = interval.totalActivities
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
                    WorkoutLogItem(displayType: $displayType, day: day, hideBubble: false, navigatable: true)
                }
            }
            .frame(height: 80)
        }
        .padding([.leading, .trailing], 15.0)
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
    
    @Environment(\.managedObjectContext) var viewContext
    
    @Binding var displayType: LogDisplayType
    var day: LogDay
    var hideBubble: Bool = false
    let totalActivities: Int
    var navigatable = false
    
    var isEmpty: Bool { totalActivities == 0 }
    
    init(displayType: Binding<LogDisplayType>, day: LogDay, hideBubble: Bool = false, navigatable: Bool = false) {
        _displayType = displayType
        self.day = day
        self.hideBubble = hideBubble
        totalActivities = day.totalActivities
        self.navigatable = navigatable
    }
    
    var body: some View {
        VStack(spacing: 5.0) {
            if navigatable {
                NavigationLink(destination: destinationView()) {
                    LogBubble(color: day.color, scaleFactor: scaleFactor)
                        .overlay(bubbleOverlay())
                        .frame(idealWidth: maxWidth, idealHeight: maxWidth, alignment: .center)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isEmpty)
                .opacity(hideBubble ? 0.0 : 1.0)
            } else {
                LogBubble(color: day.color, scaleFactor: scaleFactor)
                    .overlay(bubbleOverlay())
                    .frame(idealWidth: maxWidth, idealHeight: maxWidth, alignment: .center)
                    .opacity(hideBubble ? 0.0 : 1.0)
            }
            
            Text(day.label)
                .font(.footnote)
                .modifier(TextCircleModifier(isToday: day.date.isToday))
        }
    }
    
    @ViewBuilder
    func destinationView() -> some View {
        if let identifier = day.remoteIdentifiers.first, day.totalActivities == 1 {
            if let workout = Workout.find(using: identifier, in: viewContext) {
                DetailView(detailManager: DetailManager(viewModel: workout.detailViewModel, context: viewContext))
            } else {
                Text("No Workout")
            }
        } else {
            List {
                WorkoutFilter(identifiers: day.remoteIdentifiers) { workout in
                    NavigationLink(destination: DetailView(detailManager: DetailManager(viewModel: workout.detailViewModel, context: viewContext))) {
                        WorkoutPlainCell(viewModel: workout.detailViewModel)
                    }
                }
            }
            .listStyle(PlainListStyle())
            .navigationTitle("Workouts")
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
        case .distance:
            return CGFloat(day.distance)
        case .time:
            return CGFloat(day.duration)
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

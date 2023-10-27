//
//  TagSummaryCell.swift
//  Workouts
//
//  Created by Axel Rivera on 10/24/21.
//

import SwiftUI

extension SummaryCell {
    
    enum RowType {
        case header, row
    }
    
    struct Object: Identifiable, Hashable {
        var id = UUID().uuidString
        let text: String
        let color: Color
        
        init(text: String, color: Color = .primary) {
            self.text = text
            self.color = color
        }
    }
    
    struct Row: Identifiable, Hashable {
        typealias Object = SummaryCell.Object
        
        let id: String
        let rowType: RowType
        let objects: [Object]
        
        init(rowType: RowType, objects: [Object]) {
            self.id = objects.map({ $0.id }).joined(separator: "::")
            self.rowType = rowType
            self.objects = objects
        }
    }
    
}

struct SummaryCell: View {
    let viewModel: WorkoutSummary
    let rows: [Row]
    
    init(viewModel: WorkoutSummary, active: Bool) {
        self.viewModel = viewModel
        self.rows = SummaryCellProcessor(viewModel: viewModel, active: active).gridRows()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10.0) {
//            if let title = viewModel.title {
//                HStack {
//                    Text(title)
//                        .font(.title2)
//
//                    Spacer()
//
//                    if let gearType = viewModel.gearValue {
//                        GearImage(gearType: gearType)
//                    }
//
//                    Image(systemName: "chevron.right")
//                        .foregroundColor(.secondary)
//                }
//                .foregroundColor(viewModel.titleColor)
//            }
            
            VStack(alignment: .leading, spacing: 5.0) {
                ForEach(rows) { row in
                    HStack {
                        ForEach(row.objects) { object in
                            if object.text.isEmpty {
                                Color.clear
                            } else {
                                Text(object.text)
                                    .font(.fixedBody)
                                    .foregroundColor(object.color)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding([.bottom], row.rowType == .header ? 5.0 : 0.0)
                }
            }
        }
    }
}

struct SummaryCell_Previews: PreviewProvider {
    static let viewModel1: TagSummaryViewModel = TagSummaryViewModel.sample(name: "Tag 1", color: .red, gearType: .bike)
    
    static var previews: some View {
        Group {
            SummaryCell(viewModel: viewModel1, active: false)
                .frame(maxWidth: .infinity, maxHeight: 140, alignment: .leading)
        }
        .padding()
        .preferredColorScheme(.dark)
    }
}

struct SummaryCellProcessor {
    let viewModel: WorkoutSummary
    let active: Bool
}

extension SummaryCellProcessor {
    typealias Row = SummaryCell.Row
    typealias Object = SummaryCell.Object
    typealias Strings = Localization.Labels
    typealias WorkoutStrings = Localization.Workouts
        
    var showSpeed: Bool {
        if let gearType = viewModel.gearValue {
            return gearType == .bike
        } else if let sport = viewModel.sportValue {
            return sport.isSpeedSport
        } else {
            return false
        }
    }
    
    var showPace: Bool {
        if let gearType = viewModel.gearValue {
            return gearType == .shoes
        } else if let sport = viewModel.sportValue {
            return sport.isWalkingOrRunning
        } else {
            return false
        }
    }
    
    var activityLabel: String {
        if let gearType = viewModel.gearValue {
            switch gearType {
            case .bike: return Localization.Labels.rides
            default: return Localization.Labels.workouts
            }
        } else if let sport = viewModel.sportValue {
            switch sport {
            case .cycling: return Strings.rides
            case .running: return Strings.runs
            case .walking: return Strings.walks
            case .hiking: return Strings.hikes
            default: return Strings.workouts
            }
        } else {
            return Strings.workouts
        }
    }
    
    func headerObjects() -> [Object] {
        [
            .init(text: ""),
            .init(text: Strings.total, color: .secondary),
            .init(text: Strings.average, color: .secondary)
        ]
    }
    
    func activityObjects() -> [Object] {
        [
            .init(text: activityLabel),
            .init(text: viewModel.totalString, color: .secondary),
            .init(text: "")
        ]
    }
    
    func distanceObjects() -> [Object] {
        [
            .init(text: LabelStrings.distance),
            .init(text: active ? viewModel.distanceString : zeroDistance, color: .distance),
            .init(text: active ? viewModel.avgDistanceString : zeroDistance, color: .distance)
        ]
    }
    
    func timeObjects() -> [Object] {
        [
            .init(text: Strings.time),
            .init(text: active ? viewModel.durationString : zeroDuration, color: .time),
            .init(text: active ? viewModel.avgDurationString : zeroDuration, color: .time)
        ]
    }
    
    func calorieObjects() -> [Object] {
        [
            .init(text: LabelStrings.calories),
            .init(text: active ? viewModel.caloriesString : zeroCalories, color: .calories),
            .init(text: active ? viewModel.avgCaloriesString : zeroCalories, color: .calories)
        ]
    }
    
    func elevationObjects() -> [Object] {
        [
            .init(text: LabelStrings.elevation),
            .init(text: active ? viewModel.elevationString : zeroElevation, color: .elevation),
            .init(text: active ? viewModel.avgElevationString : zeroElevation, color: .elevation)
        ]
    }
    
    func speedObjects() -> [Object] {
        [
            .init(text: LabelStrings.speed),
            .init(text: ""),
            .init(text: active ? viewModel.avgSpeedString : zeroSpeed, color: .speed)
        ]
    }
    
    func paceObjects() -> [Object] {
        [
            .init(text: LabelStrings.pace),
            .init(text: ""),
            .init(text: active ? viewModel.avgPaceString : zeroPace, color: .pace)
        ]
    }
    
    var zeroDistance: String {
        formattedDistanceStringInTags(for: 0)
    }
    
    var zeroDuration: String {
        formattedHoursMinutesPrettyStringInTags(for: 0)
    }
    
    var zeroCalories: String {
        formattedCaloriesString(for: 0, zeroPadding: true)
    }
    
    var zeroElevation: String {
        formattedElevationString(for: 0, zeroPadding: true)
    }
    
    var zeroSpeed: String {
        formattedSpeedString(for: 0)
    }
    
    var zeroPace: String {
        formattedRunningWalkingPaceString(for: 0)
    }
    
    func gridRows() -> [Row] {
        var rows = [Row]()
        
        let header = Row(rowType: .header, objects: headerObjects())
        let activities = Row(rowType: .row, objects: activityObjects())
        let distance = Row(rowType: .row, objects: distanceObjects())
        let time = Row(rowType: .row, objects: timeObjects())
        let calories = Row(rowType: .row, objects: calorieObjects())
        let elevation = Row(rowType: .row, objects: elevationObjects())
        
        rows.append(contentsOf: [header, activities, distance, time, calories, elevation])
                
        if showSpeed {
            let speed = Row(rowType: .row, objects: speedObjects())
            rows.append(speed)
        }
        
        if showPace {
            let pace = Row(rowType: .row, objects: paceObjects())
            rows.append(pace)
        }
        
        return rows
    }
    
}

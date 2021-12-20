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
    
    init(viewModel: WorkoutSummary) {
        self.viewModel = viewModel
        self.rows = SummaryCellProcessor(viewModel: viewModel).gridRows()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10.0) {
            if let title = viewModel.title {
                HStack {
                    Text(title)
                        .font(.title2)
                    
                    Spacer()
                    
                    if let gearType = viewModel.gearValue {
                        GearImage(gearType: gearType)
                    }
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .foregroundColor(viewModel.titleColor)
            }
            
            VStack(alignment: .leading, spacing: 5.0) {
                ForEach(rows) { row in
                    HStack {
                        ForEach(row.objects) { object in
                            if object.text.isEmpty {
                                Color.clear
                            } else {
                                Text(object.text)
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
            SummaryCell(viewModel: viewModel1)
                .frame(maxWidth: .infinity, maxHeight: 140, alignment: .leading)
        }
        .padding()
        .preferredColorScheme(.dark)
    }
}

struct SummaryCellProcessor {
    let viewModel: WorkoutSummary
}

extension SummaryCellProcessor {
    typealias Row = SummaryCell.Row
    typealias Object = SummaryCell.Object
        
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
            case .bike: return "Rides"
            default: return "Workouts"
            }
        } else if let sport = viewModel.sportValue {
            switch sport {
            case .cycling: return "Rides"
            case .running: return "Runs"
            case .walking: return "Walks"
            case .hiking: return "Hikes"
            default: return "Workouts"
            }
        } else {
            return "Workouts"
        }
    }
    
    func headerObjects() -> [Object] {
        [
            .init(text: ""),
            .init(text: "Total", color: .secondary),
            .init(text: "Average", color: .secondary)
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
            .init(text: "Distance"),
            .init(text: viewModel.distanceString, color: .distance),
            .init(text: viewModel.avgDistanceString, color: .distance)
        ]
    }
    
    func timeObjects() -> [Object] {
        [
            .init(text: "Time"),
            .init(text: viewModel.durationString, color: .time),
            .init(text: viewModel.avgDurationString, color: .time)
        ]
    }
    
    func calorieObjects() -> [Object] {
        [
            .init(text: "Calories"),
            .init(text: viewModel.caloriesString, color: .calories),
            .init(text: viewModel.avgCaloriesString, color: .calories)
        ]
    }
    
    func elevationObjects() -> [Object] {
        [
            .init(text: "Elevation"),
            .init(text: viewModel.elevationString, color: .elevation),
            .init(text: viewModel.avgElevationString, color: .elevation)
        ]
    }
    
    func speedObjects() -> [Object] {
        [
            .init(text: "Speed"),
            .init(text: ""),
            .init(text: viewModel.avgSpeedString, color: .speed)
        ]
    }
    
    func paceObjects() -> [Object] {
        [
            .init(text: "Pace"),
            .init(text: ""),
            .init(text: viewModel.avgPaceString, color: .pace)
        ]
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

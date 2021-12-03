//
//  TagSummaryCell.swift
//  Workouts
//
//  Created by Axel Rivera on 10/24/21.
//

import SwiftUI

struct TagSummaryCell: View {
    let viewModel: TagSummaryViewModel
    private let rows: [TagSummaryViewModel.GridRow]
    
    init(viewModel: TagSummaryViewModel) {
        self.viewModel = viewModel
        self.rows = viewModel.gridRows()
    }
    
    let columns = [
        GridItem(spacing: 0),
        GridItem(spacing: 0),
        GridItem(spacing: 0)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10.0) {
            HStack {
                Text(viewModel.name)
                    .font(.title2)
                Spacer()
                GearImage(gearType: viewModel.gearType)
            }
            .foregroundColor(viewModel.color)
            
            LazyVGrid(columns: columns, alignment: .leading, spacing: 5.0) {
                ForEach(rows) { row in
                    Section {
                        ForEach(row.objects) { object in
                            TagSummaryGridItem(object: object)
                        }
                    }
                    .padding(.bottom, row.rowType == .header ? 5.0 : 0.0)
                }
            }
        }
        .padding([.leading, .trailing])
        .padding([.top, .bottom], CGFloat(10.0))
    }
}

struct TagSummaryCell_Previews: PreviewProvider {    
    static var previews: some View {
        Group {
            TagSummaryCell(viewModel: TagSummaryViewModel.sample(name: "Tag 1"))
                .previewLayout(PreviewLayout.sizeThatFits)
            TagSummaryCell(viewModel: TagSummaryViewModel.sample(name: "Tag 2"))
                .previewLayout(PreviewLayout.sizeThatFits)
        }
        .padding()
        .preferredColorScheme(.dark)
    }
}

struct TagSummaryGridItem: View {
    let object: TagSummaryViewModel.GridObject
    
    var body: some View {
        if object.text.isEmpty {
            Color.clear
        } else {
            Text(object.text)
                .foregroundColor(object.color)
        }
    }
    
}

extension TagSummaryViewModel {
    var activityLabel: String {
        switch gearType {
        case .bike:
            return "Rides"
        case .shoes:
            return "Workouts"
        default:
            return "Activities"
        }
    }
    
    enum GridRowType {
        case header, row
    }
    
    struct GridObject: Identifiable, Hashable {
        var id: String {
            String(format: "%@::%@::%@::%@", uuid.uuidString, row as NSNumber, column as NSNumber, text)
        }
        
        let uuid: UUID
        let row: Int
        let column: Int
        let text: String
        let color: Color
        
        init(uuid: UUID, row: Int, column: Int, text: String, color: Color = .primary) {
            self.uuid = uuid
            self.row = row
            self.column = column
            self.text = text
            self.color = color
        }
    }
    
    struct GridRow: Identifiable, Hashable {
        var id: String { "\(uuid)::\(rowNumber)"}
        
        let uuid: UUID
        let rowNumber: Int
        let rowType: GridRowType
        let objects: [GridObject]
    }
    
    func headerObjects(row: Int) -> [GridObject] {
        [
            .init(uuid: id, row: row, column: 0, text: ""),
            .init(uuid: id, row: row, column: 1, text: "Total", color: .secondary),
            .init(uuid: id, row: row, column: 2, text: "Average", color: .secondary)
        ]
    }
    
    func activityObjects(row: Int) -> [GridObject] {
        [
            .init(uuid: id, row: row, column: 0, text: activityLabel),
            .init(uuid: id, row: row, column: 1, text: totalString, color: .secondary),
            .init(uuid: id, row: row, column: 2, text: "")
        ]
    }
    
    func distanceObjects(row: Int) -> [GridObject] {
        [
            .init(uuid: id, row: row, column: 0, text: "Distance"),
            .init(uuid: id, row: row, column: 1, text: distanceString, color: .distance),
            .init(uuid: id, row: row, column: 2, text: avgDistanceString, color: .distance)
        ]
    }
    
    func timeObjects(row: Int) -> [GridObject] {
        [
            .init(uuid: id, row: row, column: 0, text: "Time"),
            .init(uuid: id, row: row, column: 1, text: durationString, color: .time),
            .init(uuid: id, row: row, column: 2, text: avgDurationString, color: .time)
        ]
    }
    
    func calorieObjects(row: Int) -> [GridObject] {
        [
            .init(uuid: id, row: row, column: 0, text: "Calories"),
            .init(uuid: id, row: row, column: 1, text: caloriesString, color: .calories),
            .init(uuid: id, row: row, column: 2, text: avgCaloriesString, color: .calories)
        ]
    }
    
    func elevationObjects(row: Int) -> [GridObject] {
        [
            .init(uuid: id, row: row, column: 0, text: "Elevation"),
            .init(uuid: id, row: row, column: 1, text: elevationString, color: .elevation),
            .init(uuid: id, row: row, column: 2, text: avgElevationString, color: .elevation)
        ]
    }
    
    func speedObjects(row: Int) -> [GridObject] {
        [
            .init(uuid: id, row: row, column: 0, text: "Speed"),
            .init(uuid: id, row: row, column: 1, text: ""),
            .init(uuid: id, row: row, column: 2, text: avgSpeedString, color: .speed)
        ]
    }
    
    func paceObjects(row: Int) -> [GridObject] {
        [
            .init(uuid: id, row: row, column: 0, text: "Pace"),
            .init(uuid: id, row: row, column: 1, text: ""),
            .init(uuid: id, row: row, column: 2, text: avgPaceString, color: .pace)
        ]
    }
    
    func gridRows() -> [GridRow] {
        let header = GridRow(uuid: id, rowNumber: 0, rowType: .header, objects: headerObjects(row: 0))
        let activities = GridRow(uuid: id, rowNumber: 1, rowType: .row, objects: activityObjects(row: 1))
        let distance = GridRow(uuid: id,rowNumber: 2,rowType: .row, objects: distanceObjects(row: 2))
        let time = GridRow(uuid: id, rowNumber: 3, rowType: .row, objects: timeObjects(row: 3))
        let calories = GridRow(uuid: id, rowNumber: 4, rowType: .row, objects: calorieObjects(row: 4))
        let elevation = GridRow(uuid: id, rowNumber: 5, rowType: .row, objects: elevationObjects(row: 5))
        
        var rows = [header, activities, distance, time, calories, elevation]
        
        if gearType == .bike {
            let speed = GridRow(uuid: id, rowNumber: 6, rowType: .row, objects: speedObjects(row: 6))
            rows.append(speed)
        } else if gearType == .shoes {
            let pace = GridRow(uuid: id, rowNumber: 7, rowType: .row, objects: paceObjects(row: 7))
            rows.append(pace)
        }
        return rows
    }
    
    
}

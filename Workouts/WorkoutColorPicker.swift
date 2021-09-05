//
//  WorkoutColorPicker.swift
//  WorkoutColorPicker
//
//  Created by Axel Rivera on 9/3/21.
//

import SwiftUI

struct WorkoutColorPicker: View {
    private static let width: Double = 50.0
    
    private let data = Color.workoutColors
    private let width: Double = Self.width

    private let rows = [
        GridItem(.fixed(Self.width))
    ]
    
    @Binding var selectedColor: Color
    var selectedAction: (_ color: Color) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHGrid(rows: rows, spacing: 20.0) {
                ForEach(data, id: \.self) { color in
                    Button(action: { selectColor(color) }) {
                        Rectangle()
                            .fill(color)
                            .frame(width: CGFloat(width), height: CGFloat(width))
                            .border(selectedColor == color ? .yellow : .white, width: 2.0)
                    }
                }
            }
        }
        .frame(maxHeight: CGFloat(width))
    }
    
    func selectColor(_ color: Color) {
        selectedColor = color
        selectedAction(color)
    }
}

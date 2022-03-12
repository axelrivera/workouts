//
//  WorkoutColorPicker.swift
//  WorkoutColorPicker
//
//  Created by Axel Rivera on 9/3/21.
//

import SwiftUI

struct WorkoutColorPicker: View {
    private let columns = Array(repeating: GridItem(.adaptive(minimum: 50.0, maximum: 75.0)), count: 6)
    
    var colors = Color.workoutColors
    @Binding var selectedColor: Color
    var selectedAction: (_ color: Color) -> Void

    var body: some View {
        LazyVGrid(columns: columns, alignment: .center, spacing: 20.0) {
            ForEach(colors, id: \.self) { color in
                Button(action: { selectColor(color) }) {
                    Circle()
                        .stroke(color == selectedColor ? Color.yellow : Color.colorPickerBorder, lineWidth: 3.0)
                        .background(Circle().fill(color))
                        .frame(minWidth: 30.0, maxWidth: .infinity, minHeight: 40.0, maxHeight: .infinity, alignment: .center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 100.0, maxHeight: 120.0)
    }
    
    func selectColor(_ color: Color) {
        selectedColor = color
        selectedAction(color)
    }
}

struct WorkoutColorPicker_Previews: PreviewProvider {
    @State static var selectedColor = Color.accentColor
    
    static var previews: some View {
        Form {
            WorkoutColorPicker(selectedColor: $selectedColor) { color in
                
            }
            .buttonStyle(PlainButtonStyle())
        }
        .preferredColorScheme(.dark)
    }
}

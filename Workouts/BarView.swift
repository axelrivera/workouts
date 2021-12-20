//
//  BarView.swift
//  Workouts
//
//  Created by Axel Rivera on 6/23/21.
//

import SwiftUI

struct BarView: View {
    private let cornerRadius: CGFloat = 2
    private let maxHeight: CGFloat = 5
    
    let value: Double
    let total: Double
    let barColor: Color
    
    init(value: Double, total: Double = 1.0, barColor: Color = .accentColor) {
        self.value = value
        self.total = total
        self.barColor = barColor
    }
    
    var body: some View {
        GeometryReader{ geometry in
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.systemFill)
                .frame(maxWidth: .infinity, maxHeight: maxHeight, alignment: .leading)
                .overlay(innerRectangle(width: geometry.size.width * widthFactor), alignment: .leading)
        }
        .frame(height: maxHeight)
    }
    
    var widthFactor: CGFloat {
        guard total > 0 else { return 0 }
        guard value <= total else { return 0 }
        return CGFloat(value / total)
    }
    
    func innerRectangle(width: CGFloat) -> some View {
        Rectangle()
            .fill(barColor)
            .frame(width: width, alignment: .trailing)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
    
}

struct BarView_Previews: PreviewProvider {
    static var previews: some View {
        BarView(value: 0.5)
            .padding()
    }
}

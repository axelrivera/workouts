//
//  LogWeekView.swift
//  Workouts
//
//  Created by Axel Rivera on 7/25/21.
//

import SwiftUI

struct LogWeekView: View {
    let distances: [CGFloat] = [0, 20, 30.5, 0, 10, 2.3, 0]
    let days = [
        NSLocalizedString("M", comment: "Monday"),
        NSLocalizedString("T", comment: "Tuesday"),
        NSLocalizedString("W", comment: "Wednesday"),
        NSLocalizedString("T", comment: "Thursday"),
        NSLocalizedString("F", comment: "Friday"),
        NSLocalizedString("S", comment: "Saturday"),
        NSLocalizedString("S", comment: "Sunday")
    ]
    
    var maxDistance: CGFloat {
        distances.max() ?? 0
    }
    
    var body: some View {
        VStack(alignment: .leading) {            
            HStack(spacing: 5) {
                ForEach(0 ..< distances.count, id: \.self) { index in
                    Button(action: {}) {
                        VStack {
                            LogBubble(color: .cycling, scaleFactor: 0.8)
                                .overlay(bubbleOverlay())
                                .frame(idealWidth: 50, idealHeight: 50, alignment: .center)
                            
                            Text(days[index])
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .frame(height: 80)
        }
    }
    
    @ViewBuilder
    func bubbleOverlay() -> some View {
        Text("0:00")
            .font(.system(size: 10))
            .foregroundColor(.white)
            .minimumScaleFactor(0.9)
            .padding(3)
    }
    
}

struct LogWeekView_Previews: PreviewProvider {
    
    static var previews: some View {
        LogWeekView()
            .preferredColorScheme(.dark)
    }
    
}



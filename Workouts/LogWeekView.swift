//
//  LogWeekView.swift
//  Workouts
//
//  Created by Axel Rivera on 7/25/21.
//

import SwiftUI

struct LogWeekView: View {
    
    let distances: [CGFloat] = [0, 20, 30.5, 0, 10, 2.3, 0]
    let days = ["M", "T", "W", "T", "F", "S", "S"]
    
    var maxDistance: CGFloat {
        distances.max() ?? 0
    }
    
    var body: some View {
        VStack(alignment: .leading) {            
            HStack(spacing: 5) {
                ForEach(0 ..< distances.count) { index in
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

//struct CircleView: View {
//    let distance: CGFloat
//    let maxDistance: CGFloat
//    let color: Color = .accentColor
//
//    var body: some View {
//        GeometryReader { proxy in
//            Color.clear
//                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .center)
//                .background(circle(diameter: diameter(for: proxy)))
//
//        }
//    }
//
//    func diameter(for proxy: GeometryProxy) -> CGFloat {
//        let factor = max(distance / maxDistance, 0.5)
//        let width = proxy.size.width * factor
//        return width
//    }
//
//    @ViewBuilder
//    func circle(diameter: CGFloat) -> some View {
//        if distance > 0 {
//            Circle()
//                .foregroundColor(color)
//                .overlay(
//                    Text(String(format: "%0.1f", distance))
//                        .font(.caption)
//                        .foregroundColor(.white)
//                        .minimumScaleFactor(0.01)
//                        .padding(.all, 2)
//                )
//                .frame(width: diameter, height: diameter, alignment: .center)
//        } else {
//            Text("•")
//                .foregroundColor(.secondary)
//        }
//    }
//
//}

struct LogWeekView_Previews: PreviewProvider {
    
    static var previews: some View {
        LogWeekView()
            .preferredColorScheme(.dark)
    }
    
}



//
//  LogBubble.swift
//  Workouts
//
//  Created by Axel Rivera on 7/27/21.
//

import SwiftUI

struct LogBubble: View {
    let color: Color
    let scaleFactor: CGFloat
    
    var body: some View {
        GeometryReader { proxy in
            VStack {
                Circle()
                    .fill(color)
                    .frame(width: width(for: proxy), height: height(for: proxy), alignment: .center)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
    
}

extension LogBubble {
    
    func width(for proxy: GeometryProxy) -> CGFloat {
        trunc(abs(proxy.size.width * scaleFactor))
    }
    
    func height(for proxy: GeometryProxy) -> CGFloat {
        trunc(abs(proxy.size.height * scaleFactor))
    }
    
}

struct LogBubble_Previews: PreviewProvider {
    static var text = "29.5"
    static var width: CGFloat = 50
    
    static var previews: some View {
        LogBubble(color: .accentColor, scaleFactor: 0.5)
            .overlay(
                Text(text)
                    .font(.system(size: 10))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.9)
                    .padding(3)
            )
            .frame(width: width, height: width, alignment: .center)
    }
}

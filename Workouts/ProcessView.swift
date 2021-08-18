//
//  LoadingView.swift
//  Workouts
//
//  Created by Axel Rivera on 6/2/21.
//

import SwiftUI

struct ProcessView: View {
    
    var title: String
    @Binding var value: Double
    
    @State private var isAnimating = false
    
    var foreverAnimation: Animation {
            Animation.linear(duration: 5.0)
                .repeatForever(autoreverses: false)
        }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 20.0) {
                Text(title)
                    .font(.title3)
                ProgressView(value: value)
            }
            .padding()
            .frame(width: geometry.size.width * 0.75, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
            .background(Color.secondarySystemBackground)
            .cornerRadius(12.0)
            .shadow(radius: 10)
            .padding()
            .position(x: geometry.size.width / 2.0, y: geometry.size.height / 2.0)
        }
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var title = "Fetching Workouts"
    
    static var previews: some View {
        ProcessView(title: title, value: .constant(0.5))
            .environment(\.colorScheme, .dark)
    }
}

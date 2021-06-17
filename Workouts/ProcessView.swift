//
//  LoadingView.swift
//  Workouts
//
//  Created by Axel Rivera on 6/2/21.
//

import SwiftUI

struct ProcessView: View {
    
    var text: String
    @Binding var value: Double
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                ProgressView(text, value: value)
                    .padding()
                    .frame(width: geometry.size.width * 0.75, height: 100.0, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                    .background(Color.secondarySystemBackground)
                    .cornerRadius(12.0)
                    .shadow(radius: 10)
                    .padding()
                    .position(x: geometry.size.width / 2.0, y: geometry.size.height / 2.0)
            }
        }
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        ProcessView(text: "Fetching Workouts...", value: .constant(0.5))
            .environment(\.colorScheme, .light)
    }
}

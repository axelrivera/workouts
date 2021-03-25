//
//  RoundButton.swift
//  Workouts
//
//  Created by Axel Rivera on 2/6/21.
//

import SwiftUI

struct RoundButton: View {
    var text: String
    var foregroundColor = Color.white
    var backgroundColor = Color.accentColor
    var action = {}
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .frame(minWidth: 0, maxWidth: .infinity)
                .padding()
                .foregroundColor(foregroundColor)
                .background(backgroundColor)
                .cornerRadius(12)
        }
    }
}

struct RoundButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20.0) {
            RoundButton(text: "Button Text", action: {})
            RoundButton(text: "Button Text", foregroundColor: .primary, backgroundColor: .gray, action: {})
        }
        .padding()
        .colorScheme(.dark)
    }
}

//
//  RoundButton.swift
//  Workouts
//
//  Created by Axel Rivera on 2/6/21.
//

import SwiftUI

struct RoundButton: View {
    var text: String
    var action = {}
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .frame(minWidth: 0, maxWidth: .infinity)
                .padding()
                .foregroundColor(.white)
                .background(Color.accentColor)
                .cornerRadius(12)
        }
    }
}

struct RoundButton_Previews: PreviewProvider {
    static var previews: some View {
        RoundButton(text: "Button Text", action: {})
    }
}

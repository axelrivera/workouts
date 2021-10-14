//
//  IntroViews.swift
//  Workouts
//
//  Created by Axel Rivera on 10/12/21.
//

import SwiftUI

struct WatchOnboarding: View {
    var action = {}
    
    var body: some View {
        VStack {
            VStack(spacing: 50.0) {
                VStack(spacing: 20.0) {
                    Text("Welcome to Better Workouts")
                        .minimumScaleFactor(0.5)
                        .font(.largeTitle)
                        .multilineTextAlignment(.center)
                    
                    Text("A simple yet powerful way to visualize your workouts!")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 280.0)
                }
                
                Image(systemName: "applewatch")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 256, height: 256)
                    .foregroundColor(.green)
                
                Text("Better Workouts reads the Health data stored by the Workout app from your Apple Watch.")
                    .multilineTextAlignment(.center)
                
            }
            .frame(maxHeight: .infinity)
            
            Button(action: action) {
                Text("Next")
                    .padding()
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .padding(.bottom, 50.0)
        
    }
}

struct WatchOnboarding_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WatchOnboarding()
        }
        .preferredColorScheme(.light)
    }
}

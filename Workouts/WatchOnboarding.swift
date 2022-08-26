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
        VStack(spacing: 25) {
            Text("Welcome to Better Workouts")
                .font(.largeTitle)
                .multilineTextAlignment(.center)
                .padding(.top)
            
            VStack(spacing: 40.0) {
                Text("A simple yet powerful app\nto visualize your workouts!")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Image(systemName: "applewatch")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 200)
                    .foregroundColor(.green)
            }
            .frame(maxHeight: .infinity)
            
            Text("Better Workouts reads Health data stored by the Workout app from your Apple Watch.")
                .font(.subheadline)
                .foregroundColor(.time)
                .multilineTextAlignment(.center)
            
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

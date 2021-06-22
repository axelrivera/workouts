//
//  OnboardingView.swift
//  Workouts
//
//  Created by Axel Rivera on 2/7/21.
//

import SwiftUI

struct OnboardingView: View {
    var action = {}
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 0.0) {
                VStack(spacing: 0.0) {
                    Text("Welcome to")
                        .font(.title)
                    Text("Better Workouts")
                        .font(.largeTitle)
                }
                .padding(.bottom, 50.0)
                
                Image(systemName: "heart.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100, alignment: .center)
                    .foregroundColor(.red)
                
                Text("The app needs your permission to read your workout data from the Apple Health app.")
                    .multilineTextAlignment(.center)
                    .padding(.top, 40.0)
            }
            
            Spacer()
                            
            RoundButton(text: "Request Permission", action: action)
        }
        .padding()
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
            .preferredColorScheme(.dark)
    }
}

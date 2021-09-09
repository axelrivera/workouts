//
//  OnboardingView.swift
//  Workouts
//
//  Created by Axel Rivera on 2/7/21.
//

import SwiftUI

struct OnboardingView: View {
    var action = {}
    
    @State private var isSelected = false
    
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
            
            Button(action: onButtopnPress) {
                if isSelected {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Text("Request Permission")
                }
            }
            .buttonStyle(RoundButtonStyle())
            .disabled(isSelected)
        }
        .padding()
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
    }
    
}

extension OnboardingView {
    
    func onButtopnPress() {
        isSelected = true
        action()
    }
    
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
            .preferredColorScheme(.dark)
    }
}

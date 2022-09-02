//
//  HealthOnboarding.swift
//  Workouts
//
//  Created by Axel Rivera on 10/12/21.
//

import SwiftUI

struct HealthOnboarding: View {
    var action = {}
    
    @State private var isSelected = false
    
    var body: some View {
        
        VStack(spacing: 25) {
            Text(NSLocalizedString("Health Permissions", comment: "health onboarding title"))
                .font(.largeTitle)
                .padding(.top)
            
            VStack {
                Image(systemName: "heart.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 200)
                    .foregroundColor(.red)
                                
                
            }
            .frame(maxHeight: .infinity)
            
            Text(
                NSLocalizedString(
                    "Better Workouts needs permission to read your workout data from the Apple Health app. Some profile data is also used to calculate heart rate zones and training load.",
                    comment: "Health onboarding line 1"
                )
            )
            .font(.subheadline)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            
            Text(NSLocalizedString("The data will always stay on your phone and never be uploaded to a server.", comment: "Health onboarding line 2"))
                .foregroundColor(.time)
                .multilineTextAlignment(.center)
            
            Button(action: onButtopnPress) {
                Group {
                    if isSelected {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text(NSLocalizedString("Request Permission", comment: "Action"))
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.accentColor)
            .disabled(isSelected)
        }
        .padding()
        .padding(.bottom, 50.0)
    }
    
}

extension HealthOnboarding {
    
    func onButtopnPress() {
        isSelected = true
        action()
    }
    
}

struct HealthOnboarding_Previews: PreviewProvider {
    static var previews: some View {
        HealthOnboarding()
            .preferredColorScheme(.dark)
    }
}

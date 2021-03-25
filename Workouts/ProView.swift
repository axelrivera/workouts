//
//  ProView.swift
//  Workouts
//
//  Created by Axel Rivera on 3/24/21.
//

import SwiftUI

struct ProView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.systemBackground
                .ignoresSafeArea()
            
            VStack(alignment: .center, spacing: 10.0) {
                Spacer()
                
                Image(systemName: "star.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.yellow)
                    .padding()
                
                Text("Better Workouts Pro")
                    .font(.largeTitle)
                    .padding()
                
                Text("Unlock all features for a one time payment.")
                    .foregroundColor(.secondary)
                
                VStack(spacing: 20.0) {
                    HStack(alignment: .center, spacing: 15.0) {
                        Image(systemName: "checkmark")
                            .foregroundColor(.green)
                        Text("Import external workout files from cycling computer or smartwatches.")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    HStack(alignment: .center, spacing: 15.0) {
                        Image(systemName: "checkmark")
                            .foregroundColor(.green)
                        Text("View detailed analysis for your workouts.")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    HStack(alignment: .center, spacing: 15.0) {
                        Image(systemName: "checkmark")
                            .foregroundColor(.green)
                        Text("Review your progress with detailed statistics.")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
                
                Spacer()
                
                Text("Purchasing supports with development of future updates.")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                
                Spacer()
                
                VStack(spacing: 20.0) {
                    RoundButton(text: "Upgrade for $6.99", action: {})
                    RoundButton(text: "Restore Purchase", foregroundColor: .primary, backgroundColor: .secondarySystemBackground)
                }
                .padding()
                
            }
            .padding()
        }
    }
}

struct ProView_Previews: PreviewProvider {
    static var previews: some View {
        ProView()
            .colorScheme(.dark)
    }
}

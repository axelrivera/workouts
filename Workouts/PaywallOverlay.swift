//
//  PaywallOverlay.swift
//  Workouts
//
//  Created by Axel Rivera on 7/7/21.
//

import SwiftUI

struct SampleLabel: View {
    var body: some View {
        VStack(spacing: 10.0) {
            Image(systemName: "lock.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 48, height: 48)
                .foregroundColor(.label)
            
            Text("PRO")
                .font(.system(size: 52, weight: .semibold, design: .monospaced))
                .foregroundColor(.label)
                .multilineTextAlignment(.center)
        }
        .padding(.all, 32)
        .overlay(Circle().stroke(lineWidth: 8.0))
    }
}

struct PaywallOverlay: View {
    var body: some View {
        VStack {
            SampleLabel()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PaywallOverlay_Previews: PreviewProvider {
    static var summaries = HRZoneSummary.samples()
    
    static var previews: some View {
        NavigationView {
            VStack {
                HRZonesView(summaries: summaries)
                    .padding()
                    .overlay(PaywallOverlay())
            }
            .navigationBarTitle("Overlay Example")
            .background(Color.secondarySystemBackground)
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
    }
}

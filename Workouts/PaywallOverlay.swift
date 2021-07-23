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
            Color.label
                .frame(width: 200, height: 5)
            
            Text("Sample")
                .font(.system(size: 60, weight: .semibold, design: .monospaced))
                .foregroundColor(.label)
            Color.label
                .frame(width: 200, height: 5)
        }
    }
}

struct PaywallOverlay: View {
    var body: some View {
        VStack {
            SampleLabel()
                .rotationEffect(Angle(degrees: -30))
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

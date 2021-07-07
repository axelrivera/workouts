//
//  HRZonesView.swift
//  Workouts
//
//  Created by Axel Rivera on 6/23/21.
//

import SwiftUI

struct HRZonesView: View {
    @Binding var summaries: [HRZoneSummary]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            ForEach(summaries) { summary in
                HRZonesViewRow(summary: summary)
            }
        }
    }
}

struct HRZones_Previews: PreviewProvider {
    @State static var summaries = HRZoneSummary.samples()
    
    static var previews: some View {
        HRZonesView(summaries: $summaries)
            .padding()
            .preferredColorScheme(.dark)
    }
}

struct HRZonesViewRow: View {
    let summary: HRZoneSummary
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 10.0) {
            VStack(alignment: .leading) {
                HStack(alignment: .firstTextBaseline, spacing: 10.0) {
                    Text(summary.name)
                        .foregroundColor(summary.color)
                    Text(summary.text)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                BarView(value: summary.percent, barColor: summary.color)
            }
            
            VStack(alignment: .trailing) {
                Text(NumberFormatter.percent.string(from: summary.percent as NSNumber) ?? "n/a")
                    .font(.subheadline)
                    .foregroundColor(summary.color)
                
                Text(formattedHoursMinutesSecondsDurationString(for: summary.duration))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(minWidth: 60.0, alignment: .trailing)
            }
        }
    }
}

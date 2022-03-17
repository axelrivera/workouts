//
//  DashboardInfoView.swift
//  Workouts
//
//  Created by Axel Rivera on 3/16/22.
//

import SwiftUI

struct DashboardMetricsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading) {
                    ForEach(DashboardMetric.allCases, id: \.self) { metric in
                        VStack(alignment: .leading) {
                            HStack {
                                Image(uiImage: metric.image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: CGFloat(20), height: CGFloat(20))
                                Text(metric.title)
                                    .font(.title2)
                            }
                            .foregroundColor(metric.color)
                            Text("Description goes here...")
                                .font(.subheadline)
                                .multilineTextAlignment(.leading)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Material.thinMaterial)
                        .cornerRadius(CGFloat(12))
                    }
                }
                .padding()
            }
            .navigationTitle("Health Metrics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: { presentationMode.wrappedValue.dismiss() })
                }
            }
        }
    }
}

struct DashboardInfoView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardMetricsView()
    }
}

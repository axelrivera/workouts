//
//  DashboardMetricsView.swift
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
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    Section {
                        VStack {
                            Text(DashboardStrings.metricsDescription)
                                .foregroundColor(.secondary)
                        }
                        .padding([.top, .bottom])
                        .padding([.leading, .trailing], CGFloat(10))
                            
                    }
                    Section {
                        ForEach(DashboardMetric.allCases, id: \.self) { metric in
                            HStack {
                                Image(uiImage: metric.image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: CGFloat(20), height: CGFloat(20))
                                    .foregroundColor(metric.color)
                                Text(metric.infoTitle)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.background)
                            Divider()
                        }
                    } header: {
                        Text(LabelStrings.supportedMetrics)
                            .font(.title2)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Material.bar)
                    }
                }
            }
            .navigationTitle(LabelStrings.metrics)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(ActionStrings.done, action: { presentationMode.wrappedValue.dismiss() })
                }
            }
        }
    }
}

struct DashboardMeetrics_Previews: PreviewProvider {
    static var previews: some View {
        DashboardMetricsView()
            .preferredColorScheme(.dark)
    }
}

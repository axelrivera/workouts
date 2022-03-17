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
                            Text("Dashboard metrics help you get a better picture of your fitness stats by displaying additional data stored in the Health app on your iPhone.")
                                .foregroundColor(.secondary)
                        }
                        .padding([.top, .bottom])
                        .padding([.leading, .trailing], CGFloat(10))
                            
                    }
                    Section(header: header(for: "Supported Metrics")) {
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
                    }
                }
            }
            .navigationTitle("Metrics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: { presentationMode.wrappedValue.dismiss() })
                }
            }
        }
    }
    
    @ViewBuilder
    func header(for text: String) -> some View {
        Text(text)
            .font(.title2)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Material.bar)
            
    }
}

struct DashboardMeetrics_Previews: PreviewProvider {
    static var previews: some View {
        DashboardMetricsView()
            .preferredColorScheme(.dark)
    }
}

//
//  ShareDetailView.swift
//  ShareDetailView
//
//  Created by Axel Rivera on 8/31/21.
//

import SwiftUI

struct ShareDetailView: View {
    typealias Metric = WorkoutCardViewModel.Metric
    typealias MapColor = ShareManager.MapColor
    
    @Environment(\.presentationMode) var presentationMode
    
    @EnvironmentObject var shareManager: ShareManager
        
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker("Display Metric", selection: $shareManager.selectedMetric) {
                        ForEach(allMetrics(), id: \.self) { metric in
                            Text(metric.title)
                        }
                    }
                }
                
                if shareManager.style == .map && shareManager.viewModel.includesLocation {
                    Section(header: Text("Map Color")) {
                        Picker("Map Background", selection: $shareManager.mapColor) {
                            ForEach(MapColor.allCases, id: \.self) { color in
                                Text(color.title)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding([.top, .bottom], CGFloat(5.0))
                    }
                    
                    Section {
                        Toggle("Show Title", isOn: $shareManager.showTitle)
                        Toggle("Show Date", isOn: $shareManager.showDate)
                    }
                } else {
                    Section(header: Text("Background Color")) {
                        WorkoutColorPicker(selectedColor: $shareManager.backgroundColor) { newColor in
                            Log.debug("selected color: \(newColor)")
                        }
                    }
                    
                    if shareManager.viewModel.includesLocation {
                        Section {
                            Toggle("Show Location", isOn: $shareManager.showLocation)
                            Toggle("Show Route Outline", isOn: $shareManager.showRoute)
                        }
                    }
                }
            }
            .navigationTitle("Sharing Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done", action: { presentationMode.wrappedValue.dismiss() })
                }
            }
        }
    }
}

extension ShareDetailView {
    
    var sport: Sport {
        shareManager.viewModel.sport
    }
    
    var isIndoor: Bool {
        shareManager.viewModel.indoor
    }
    
    func allMetrics() -> [Metric] {
        let sport = self.sport
        if sport.isCycling {
            if isIndoor {
                return Metric.indoorMetrics
            } else {
                return Metric.cyclingMetrics
            }
        } else if sport.isWalkingOrRunning {
            return Metric.runningMetrics
        } else {
            return []
        }
    }
    
}

struct ShareDetailView_Previews: PreviewProvider {
    static var manager: ShareManager = {
        let manager = ShareManager()
        manager.style = .color
        return manager
    }()
    
    static var previews: some View {
        ShareDetailView()
            .environmentObject(manager)
    }
}

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
                    Picker(NSLocalizedString("Display Metric 1", comment: "Metric label"), selection: $shareManager.selectedMetric1) {
                        ForEach(allMetrics(), id: \.self) { metric in
                            Text(metric.title)
                        }
                    }
                    
                    Picker(NSLocalizedString("Display Metric 2", comment: "Metric label"), selection: $shareManager.selectedMetric2) {
                        ForEach(allMetrics(), id: \.self) { metric in
                            Text(metric.title)
                        }
                    }
                }
                
                Section {
                    Toggle(NSLocalizedString("Show Title", comment: "Label"), isOn: $shareManager.showTitle)
                    Toggle(NSLocalizedString("Show Date", comment: "Label"), isOn: $shareManager.showDate)
                }
            }
            .navigationTitle(NSLocalizedString("Sharing Details", comment: "Screen title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(ActionStrings.done, action: { presentationMode.wrappedValue.dismiss() })
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
            return Metric.otherMetrics
        }
    }
    
}

struct ShareDetailView_Previews: PreviewProvider {
    static var manager: ShareManager = {
        let manager = ShareManager()
        manager.style = .photo
        return manager
    }()
    
    static var previews: some View {
        ShareDetailView()
            .environmentObject(manager)
    }
}

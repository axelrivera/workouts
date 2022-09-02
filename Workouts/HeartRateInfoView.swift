//
//  HeartRateInfoView.swift
//  Workouts
//
//  Created by Axel Rivera on 7/16/21.
//

import SwiftUI

struct HeartRateInfoView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                VStack(alignment: .leading, spacing: 10.0) {
                    Text(NSLocalizedString("What is heart rate training?", comment: "Text"))
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text(NSLocalizedString("Heart rate training uses heart rate to measure workout intensity while aiming for different heart rate zones depending on your fitness goals.", comment: "Text"))
                }
                
                ForEach(HRZone.allCases) { zone in
                    VStack(alignment: .leading, spacing: 10.0) {
                        HStack(alignment: .lastTextBaseline) {
                            Text("\(zone.zoneString) - \(zone.name)")
                                .font(.title2)
                                .foregroundColor(zone.color)
                            Spacer()
                            Text(zone.percentString)
                                .font(.subheadline)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(.secondary)
                        }
                        
                        Text(zone.explanation)
                    }
                }
                
                VStack(alignment: .leading, spacing: 10.0) {
                    Text(NSLocalizedString("80/20 Rule", comment: "Text"))
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text(NSLocalizedString("A training plan will designate precisely how much time you spend in each training zone. Research indicates that you should spend 80% of your time training at low intensity (Zones 1 and 2). You can spend the other 20% between moderate to high intensity training depending on your fitness goals.", comment: "Text"))
                }
            }
            .listStyle(.plain)
            .navigationTitle(NSLocalizedString("HR Zones Explained", comment: "Screen title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(ActionStrings.done, action: { presentationMode.wrappedValue.dismiss() })
                }
            }
        }
    }
}

struct HeartRateInfoView_Previews: PreviewProvider {
    static var previews: some View {
        HeartRateInfoView()
    }
}

//
//  HeartRateView.swift
//  Workouts
//
//  Created by Axel Rivera on 6/24/21.
//

import SwiftUI

struct HeartRateView: View {
    enum ActiveSheet: Identifiable {
        case edit, info, explanation
        var id: Int { hashValue }
    }
    
    enum ActiveAlert: Identifiable {
        case allConfirmation
        var id: Int { hashValue }
    }
    
    @Environment(\.managedObjectContext) var managedObjectContext
    @EnvironmentObject var purchaseManager: IAPManager
    
    @State private var activeSheet: ActiveSheet?
    @State private var activeAlert: ActiveAlert?
    
    @StateObject private var zoneManager = HRZoneManager()
        
    var body: some View {
        Form {
            Section(header: Color.clear.frame(height: 20)) {
                HStack {
                    Label(
                        title: { Text("Max Heart Rate") },
                        icon: { Image(systemName: "heart.fill").foregroundColor(.red) }
                    )
                    Spacer()
                    Text(zoneManager.maxHeartRateString)
                        .foregroundColor(.red)
                }
            }
            
            Section(header: Text("Curent Zones")) {
                ForEach(HRZone.allCases) { zone in
                    HRSectionRow(zone: zone)
                        .environmentObject(zoneManager)
                }
            }
            
            Section(header: Text("Help")) {
                Button(action: { activeSheet = .info }) {
                    Label("Learn More", systemImage: "info.circle")
                }
                
                Button(action: { activeSheet = .explanation }) {
                    Label("Heart Rate Zones Explained", systemImage: "lightbulb")
                }
            }
            
            Section(footer: Text("Updates Max Heart Rate and Current Zones for all workouts.")) {
                Button("Update All Workouts", action: { activeAlert = .allConfirmation })
            }
        }
        .navigationBarTitle("Heart Rate Zones")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") { activeSheet = .edit }
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .edit:
                HeartRateEditView(action: saveAction)
                    .environmentObject(HRZoneManager())
            case .info:
                SafariView(urlString: URLStrings.heartRateInfo)
            case .explanation:
                HeartRateInfoView()
            }
        }
        .alert(item: $activeAlert) { alert in
            switch alert {
            case .allConfirmation:
                let title = "Update All Workouts"
                let message = "This action will update all your existing workouts with your current Max Heart Rate and Current Zones."
                
                return Alert.contineWithTitle(title, message: message, action: applyAllAction)
            }
        }
    }
}

// MARK: - Actions

extension HeartRateView {
    
    func saveAction(heartRate: Int, values: [Int]) {
        zoneManager.maxHeartRate = Double(heartRate)
        zoneManager.values = values
        AppSettings.maxHeartRate = heartRate
        AppSettings.heartRateZones = values
        activeSheet = nil
    }
    
    func applyAllAction() {
        let heartRate = AppSettings.maxHeartRate
        let values = AppSettings.heartRateZones
        Workout.batchUpdateHeartRateZones(with: heartRate, values: values, in: managedObjectContext)
    }
    
}

struct HeartRateView_Previews: PreviewProvider {
    static var viewContext = StorageProvider.preview.persistentContainer.viewContext
    static var purchaseManager = IAPManager.preview(isActive: true)
    
    static var previews: some View {
        NavigationView {
            HeartRateView()
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(purchaseManager)
        }
        .preferredColorScheme(.dark)
    }
}

struct HRSectionRow: View {
    var zone: HRZone
    
    @Environment(\.isEnabled) var isEnabled
    @EnvironmentObject var zoneManager: HRZoneManager
    
    private let opacityValue = 0.5
    
    var zoneColor: Color {
        isEnabled ? zone.color : zone.color.opacity(opacityValue)
    }
    
    var primaryColor: Color {
        isEnabled ? .primary : .primary.opacity(opacityValue)
    }
    
    var secondaryColor: Color {
        isEnabled ? .secondary : .secondary.opacity(opacityValue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5.0) {
            HStack(alignment: .lastTextBaseline) {
                Text(zone.name)
                    .font(.title3)
                    .foregroundColor(zoneColor)
                
                Spacer()
                
                Text(zone.zoneString)
                    .font(.body)
                    .foregroundColor(zoneColor)
            }
            
            HStack {
                Text(HRZoneManager.stringForRange(range))
                    .font(.body)
                    .foregroundColor(primaryColor)
                Spacer()
                Text(HRZoneManager.stringForPercentRange(percentRange))
                    .font(.subheadline)
                    .foregroundColor(secondaryColor)
            }
        }
    }
    
    var range: HRZoneManager.ZoneRange {
        zoneManager.rangeForZone(zone)
    }
    
    var percentRange: HRZoneManager.ZonePercentRange {
        zoneManager.percentRangeForZone(zone)
    }
}

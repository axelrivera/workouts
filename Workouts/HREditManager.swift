//
//  HREditManager.swift
//  Workouts
//
//  Created by Axel Rivera on 6/19/22.
//

import SwiftUI

class HREditManager: ObservableObject {
    
    private let provider = HealthProvider.shared
    
    @Published var isDateOfBirthAvailable = false
    @Published var isRestingHeartRateAvailable = false
    
    @AppStorage(AppSettings.Keys.useFormulaMaxHeartRate)
    var useFormulaMaxHeartRate = true
    
    @AppStorage(AppSettings.Keys.maxHeartRate)
    var maxHeartRate: Int = HRZoneManager.Defaults.max
    
    @Published var maxHeartRateString = ""
    @Published var estimateMaxHeartRate: Int?
    
    @AppStorage(AppSettings.Keys.useHealthRestingHeartRate)
    var useHealthRestingHeartRate = true
    
    @AppStorage(AppSettings.Keys.restingHeartRate)
    var restingHeartRate: Int?
    
    @Published var restingHeartRateString = ""
    @Published var recentRestingHeartRate: Int?
    
    @Published var dateOfBirth: Date?
    @Published var age: Int?
    @Published var userGender: UserGender = .none
    
    init() {
        maxHeartRateString = "\(maxHeartRate)"
    }
    
}

extension HREditManager {
    
    var estimateMaxHeartRateString: String {
        formattedHeartRateString(for: Double(estimateMaxHeartRate ?? 0))
    }
    
    var recentRestingHeartRateString: String {
        formattedHeartRateString(for: Double(recentRestingHeartRate ?? 0))
    }
    
    func isMaxHeartRateFormulaDisabled() -> Bool {
        dateOfBirth == nil
    }
    
    func isRecentHealthRestingHeartRateDisabled() -> Bool {
        recentRestingHeartRate == nil
    }
    
    func loadValues() {
        Task {
            let data: (dateOfBirth: Date, age: Int)? = try? provider.dateOfBirthAndAge()
            let gender = provider.userGender()
            let estimateMaxHeartRate = try? await provider.estimateHeartRate()
            let recentRestingHeartRate = await provider.fetchRecentRestingHeartRate()
                            
            DispatchQueue.main.async {
                self.dateOfBirth = data?.dateOfBirth
                self.age = data?.age
                self.userGender = gender
                self.estimateMaxHeartRate = estimateMaxHeartRate
                self.recentRestingHeartRate = recentRestingHeartRate
            }
        }
    }
    
}

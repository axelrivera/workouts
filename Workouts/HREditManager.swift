//
//  HREditManager.swift
//  Workouts
//
//  Created by Axel Rivera on 6/19/22.
//

import SwiftUI

class HREditManager: ObservableObject {
    private let provider = HealthProvider.shared
    
    @Published var useFormulaMaxHeartRate = true
    @Published var maxHeartRate: Int = 0
    @Published var estimateMaxHeartRate: Int?
    
    @Published var useHealthRestingHeartRate = true
    @Published var restingHeartRate: Int = 0
    @Published var recentRestingHeartRate: Int?
    
    @Published var dateOfBirth: Date?
    @Published var age: Int?
    @Published var userGender: UserGender = .none
}

extension HREditManager {
    
    var isMaxHeartRateValid: Bool {
        if useFormulaMaxHeartRate {
            return true
        } else {
            return maxHeartRate > 0
        }
    }
    
    var isRestingHeartRateValid: Bool {
        if useHealthRestingHeartRate {
            return true
        } else {
            return restingHeartRate > 0
        }
    }
    
    func save() throws {
        guard isMaxHeartRateValid && isRestingHeartRateValid else {
            throw WorkoutError("validation error")
        }
        
        AppSettings.useFormulaMaxHeartRate = useFormulaMaxHeartRate
        AppSettings.maxHeartRate = maxHeartRate
        AppSettings.useHealthRestingHeartRate = useHealthRestingHeartRate
        AppSettings.restingHeartRate = restingHeartRate
        
        load()
    }
    
    func load() {
        Task {
            await load()
        }
    }
    
    func load() async {
        let useFormulaMaxHeartRate = AppSettings.useFormulaMaxHeartRate
        let maxHeartRate = AppSettings.maxHeartRate
        let useHealthRestingHeartRate = AppSettings.useHealthRestingHeartRate
        let restingHeartRate = AppSettings.restingHeartRate
        
        let data: (dateOfBirth: Date, age: Int)? = try? provider.dateOfBirthAndAge()
        
        let dateOfBirth = data?.dateOfBirth
        let age = data?.age
        let gender = provider.userGender()
        let estimateMaxHeartRate = try? provider.estimateHeartRate()
        let recentRestingHeartRate = await provider.fetchRecentRestingHeartRate()
                        
        DispatchQueue.main.async {
            self.useFormulaMaxHeartRate = useFormulaMaxHeartRate
            self.maxHeartRate = maxHeartRate
            self.estimateMaxHeartRate = estimateMaxHeartRate
            
            self.useHealthRestingHeartRate = useHealthRestingHeartRate
            self.restingHeartRate = restingHeartRate
            self.recentRestingHeartRate = recentRestingHeartRate
            
            self.dateOfBirth = dateOfBirth
            self.age = age
            self.userGender = gender
        }
    }
    
}

// MARK: - Formatting

extension HREditManager {
    
    var formattedMaxHeartRate: String {
        let value: Int
        if useFormulaMaxHeartRate {
            value = estimateMaxHeartRate ?? AppSettings.DEFAULT_MAX_HEART_RATE
        } else {
            value = maxHeartRate
        }
        return formattedHeartRateString(for: Double(value))
    }
    
    var formattedRestingHeartRate: String {
        let value: Int
        if useHealthRestingHeartRate {
            value = recentRestingHeartRate ?? AppSettings.DEFAULT_RESTING_HEART_RATE
        } else {
            value = restingHeartRate
        }
        return formattedHeartRateString(for: Double(value))
    }
    
}

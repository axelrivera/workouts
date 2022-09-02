//
//  ProfileDataStore.swift
//  Workouts
//
//  Created by Axel Rivera on 2/10/21.
//

import Foundation
import HealthKit

enum UserGender: String {
    case male, female, none
    
    init(sex: HKBiologicalSex) {
        switch sex {
        case .male:
            self = UserGender.male
        case .female:
            self = UserGender.female
        default:
            self = UserGender.none
        }
    }
    
    var isAvailable: Bool {
        switch self {
        case .male, .female:
            return true
        default:
            return false
        }
    }
    
    var title: String {
        switch self {
        case .male: return Localization.Labels.male
        case .female: return Localization.Labels.female
        case .none: return Localization.Labels.notAvailable
        }
    }
}

extension HealthProvider {
    
    func maxHeartRate() -> Int {
        if AppSettings.useFormulaMaxHeartRate {
            return (try? estimateHeartRate()) ?? AppSettings.DEFAULT_MAX_HEART_RATE
        } else {
            return AppSettings.maxHeartRate
        }
    }
    
    func restingHeartRate() async -> Int {
        do {
            guard AppSettings.useHealthRestingHeartRate else {
                throw WorkoutError("should use manual resting heart rate")
            }
            
            guard let restingHeartRate = await fetchRecentRestingHeartRate() else {
                throw WorkoutError("no recent heart rate found")
            }
            
            return restingHeartRate
        } catch {
            return AppSettings.restingHeartRate
        }
    }
    
    func heartRateZonesPercents() -> [Int] {
        var percents = AppSettings.heartRateZonePercents
        if percents.count == HRZonesCalculator.TOTAL_ZONES {
            return percents
        }
        
        let values = AppSettings.heartRateZones
        
        Log.debug("BACKUP PLAN")
        Log.debug("values: \(values)")
        
        percents = HRZonesCalculator.percents(values: values, maxHeartRate: maxHeartRate())
        Log.debug("percents: \(percents)")
        
        if percents.count != HRZonesCalculator.TOTAL_ZONES {
            percents = HRZonesCalculator.DEFAULT_PERCENTS
        }
        
        AppSettings.heartRateZonePercents = percents
        return percents
    }
    
    func heartRateZones() -> [Int] {
        let percents = heartRateZonesPercents()
        return HRZonesCalculator.values(for: percents, maxHeartRate: maxHeartRate())
    }
    
    func heartRateZonesCalculator() -> HRZonesCalculator {
        HRZonesCalculator(maxHeartRate: maxHeartRate(), values: heartRateZones())
    }
    
    func dateOfBirth() -> Date? {
        guard HKHealthStore.isHealthDataAvailable() else { return nil }
        
        do {
            let components = try healthStore.dateOfBirthComponents()
            return components.date
        } catch {
            return nil
        }
    }
    
    func dateOfBirthAndAge() throws -> (Date, Int) {
        guard let dateOfBirth = self.dateOfBirth() else { throw WorkoutError("missing dob") }
        
        let components = Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date())
        guard let years = components.year else { throw WorkoutError("invalid age") }
        
        return (dateOfBirth, years)
        
    }
    
    func estimateHeartRate() throws -> Int {
        let (_, age) = try self.dateOfBirthAndAge()
        let max = 211.0 - (0.64 * Double(age))
        return Int(max)
    }
    
    func userGender() -> UserGender {
        guard HKHealthStore.isHealthDataAvailable() else { return .none }
        
        do {
            let sex = try healthStore.biologicalSex().biologicalSex
            return UserGender(sex: sex)
        } catch {
            return .none
        }
    }
    
}

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
    
    var supported: Bool {
        switch self {
        case .male:
            fallthrough
        case .female:
            return true
        default:
            return false
        }
    }
    
    var title: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        case .none: return "n/a"
        }
    }
}

extension HealthProvider {
    
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
    
    func estimateHeartRate() async throws -> Int {
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
    
    func profileMaxHeartRate() async -> Int {
        do {
            guard AppSettings.useFormulaMaxHeartRate else {
                throw WorkoutError("should use manual max heart rate")
            }
            
            return try await estimateHeartRate()
        } catch {
            return AppSettings.maxHeartRate
        }
    }
    
    func profileRestingHeartRate() async -> Int {
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
    
}

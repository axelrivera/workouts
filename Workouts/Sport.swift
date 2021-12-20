//
//  Sport.swift
//  Workouts
//
//  Created by Axel Rivera on 2/10/21.
//

import SwiftUI
import HealthKit

enum Sport: String, Identifiable, CaseIterable {
    case cycling, running, walking, other
    case hiking, yoga, pilates
    case tennis
    case coreTraining, mixedCardio, highIntensityIntervalTraining, traditionalStrengthTraining, elliptical
    case crossTraining, functionalStrengthTraining
    
    var id: String { rawValue }
    
    init(string: String) {
        self = Sport(rawValue: string) ?? .other
    }
    
    var isSupported: Bool {
        Self.supportedSports.contains(self)
    }
    
    var isImportSupported: Bool {
        Self.importSupportedSports.contains(self)
    }
    
    var hasDistanceSamples: Bool {
        Self.distanceSports.contains(self)
    }
    
    var isWalkingOrRunning: Bool {
        Self.walkingAndRunningSports.contains(self)
    }
    
    var isCycling: Bool {
        self == .cycling
    }
    
    var isRunning: Bool {
        self == .running
    }
    
    var isWalking: Bool {
        self == .walking
    }
    
    var isSpeedSport: Bool {
        Self.speedSports.contains(self)
    }
    
    var supportsSplits: Bool {
        Self.splitSports.contains(self)
    }
    
    var normalizedDistanceValue: Double {
        switch self {
        case .cycling:
            return 3
        default:
            return 3
        }
    }
    
    var usesBikeGear: Bool {
        isCycling
    }
    
    var usesShoeGear: Bool {
        isWalkingOrRunning
    }
    
    var defaultGearTypes: [Tag.GearType] {
        switch self {
        case .cycling:
            return [.bike, .none]
        case .running, .walking, .hiking:
            return [.shoes, .none]
        default:
            return [.none]
        }
    }
    
    var defaultDistanceValue: Double {
        switch self {
        case .cycling:
            return 100
        default:
            return 3
        }
    }
    
    static let paceDistanceValue: Double = 100
    
    var color: Color {
        switch self {
        case .cycling:
            return .cycling
        case .running:
            return .running
        case .walking, .hiking:
            return .walking
        case .yoga, .pilates, .coreTraining:
            return .brown
        case .tennis:
            return .green
        case .mixedCardio, .highIntensityIntervalTraining, .crossTraining:
            return .pink
        case .functionalStrengthTraining, .traditionalStrengthTraining, .elliptical:
            return .purple
        default: return .sport
        }
    }
    
    var activityName: String {
        activityType.name
    }
    
    var name: String {
        switch self {
        case .cycling:
            return "Cycle"
        case .running:
            return "Run"
        case .walking:
            return "Walk"
        case .hiking:
            return "Hike"
        case .other:
            return "Other Activity"
        default:
            return activityType.name
        }
    }
    
    var altName: String {
        switch self {
        case .cycling:
            return "Ride"
        case .running:
            return "Run"
        case .walking:
            return "Walk"
        case .hiking:
            return "Hike"
        case .other:
            return "Other Activity"
        default:
            return activityType.name
        }
    }
    
    var activityType: HKWorkoutActivityType {
        switch self {
        case .cycling:
            return .cycling
        case .running:
            return .running
        case .walking:
            return .walking
        case .hiking:
            return .hiking
        case .yoga:
            return .yoga
        case .pilates:
            return .pilates
        case .tennis:
            return .tennis
        case .coreTraining:
            return .coreTraining
        case .mixedCardio:
            return .mixedCardio
        case .highIntensityIntervalTraining:
            return .highIntensityIntervalTraining
        case .traditionalStrengthTraining:
            return .traditionalStrengthTraining
        case .elliptical:
            return .elliptical
        case .crossTraining:
            return .crossTraining
        case .functionalStrengthTraining:
            return .functionalStrengthTraining
        case .other:
            return .other
        }
    }
    
    static let supportedSports: [Sport] = [
        .cycling,
        .running,
        .walking,
        .hiking,
        .yoga,
        .pilates,
        .tennis,
        .coreTraining,
        .mixedCardio,
        .highIntensityIntervalTraining,
        .traditionalStrengthTraining,
        .elliptical,
        .crossTraining,
        .functionalStrengthTraining
    ]
    
    static let indoorOutdoorList: [Sport] = [.running, .cycling, .walking]
    static let importSupportedSports: [Sport] = [.cycling, .running, .walking]
    static let distanceSports: [Sport] = [.cycling, .walking, .running, .hiking]
    static let walkingAndRunningSports: [Sport] = [.walking, .running, .hiking]
    static let speedSports: [Sport] = [.cycling]
    static let splitSports: [Sport] = [.cycling, .walking, .running, .hiking]
}

extension HKWorkoutActivityType {
    
    static let availableActivityTypes: [HKWorkoutActivityType] = [
        .cycling,
        .running,
        .walking,
        .hiking,
        .yoga,
        .pilates,
        .tennis,
        .coreTraining,
        .mixedCardio,
        .highIntensityIntervalTraining,
        .traditionalStrengthTraining,
        .elliptical,
        .crossTraining,
        .functionalStrengthTraining
    ]
    
    func sport() -> Sport {
        switch self {
        case .cycling:
            return .cycling
        case .running:
            return .running
        case .walking:
            return .walking
        case .hiking:
            return .hiking
        case .yoga:
            return .yoga
        case .pilates:
            return .pilates
        case .tennis:
            return .tennis
        case .coreTraining:
            return .coreTraining
        case .mixedCardio:
            return .mixedCardio
        case .highIntensityIntervalTraining:
            return .highIntensityIntervalTraining
        case .traditionalStrengthTraining:
            return .traditionalStrengthTraining
        case .elliptical:
            return .elliptical
        case .crossTraining:
            return .crossTraining
        case .functionalStrengthTraining:
            return .functionalStrengthTraining
        default:
            return .other
        }
    }
    
    var isCycling: Bool {
        self == .cycling
    }
    
    var isRunningWalking: Bool {
        Self.runninWalkingActivities.contains(self)
    }
    
    static let runninWalkingActivities: [HKWorkoutActivityType] = [.running, .walking, .hiking]
    
}

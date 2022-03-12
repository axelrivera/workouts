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
    case hiking, yoga, pilates, mindAndBody, cooldown
    case tennis, pickleball, squash
    case traditionalStrengthTraining, functionalStrengthTraining
    case coreTraining, mixedCardio, highIntensityIntervalTraining, elliptical, rowing
    case crossTraining
    case socialDance, dance, danceInspiredTraining, cardioDance
    
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
    
    var isOther: Bool {
        !isCycling && !isWalkingOrRunning
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
        case .yoga, .pilates, .coreTraining, .mindAndBody, .cooldown:
            return .brown
        case .tennis, .pickleball, .squash:
            return Color(.systemOrange)
        case .mixedCardio, .highIntensityIntervalTraining, .crossTraining, .cardioDance:
            return .pink
        case .functionalStrengthTraining, .traditionalStrengthTraining, .elliptical, .rowing:
            return .purple
        case .socialDance, .dance, .danceInspiredTraining:
            return Color(.systemIndigo)
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
        case .cycling: return .cycling
        case .running: return .running
        case .walking: return .walking
        case .hiking: return .hiking
        case .yoga: return .yoga
        case .pilates: return .pilates
        case .mindAndBody: return .mindAndBody
        case .cooldown: return .cooldown
        case .tennis: return .tennis
        case .pickleball: return .pickleball
        case .squash: return .squash
        case .coreTraining: return .coreTraining
        case .mixedCardio: return .mixedCardio
        case .highIntensityIntervalTraining: return .highIntensityIntervalTraining
        case .traditionalStrengthTraining: return .traditionalStrengthTraining
        case .elliptical: return .elliptical
        case .rowing: return .rowing
        case .socialDance: return .socialDance
        case .dance: return .socialDance
        case .danceInspiredTraining: return .socialDance
        case .cardioDance: return .cardioDance
        case .crossTraining: return .crossTraining
        case .functionalStrengthTraining: return .functionalStrengthTraining
        case .other: return .other
        }
    }
    
    static let supportedSports: [Sport] = [
        .cycling,
        .running,
        .walking,
        .hiking,
        .yoga,
        .pilates,
        .mindAndBody,
        .cooldown,
        .tennis,
        .pickleball,
        .squash,
        .traditionalStrengthTraining,
        .functionalStrengthTraining,
        .coreTraining,
        .mixedCardio,
        .highIntensityIntervalTraining,
        .elliptical,
        .rowing,
        .crossTraining,
        .socialDance,
        .dance,
        .danceInspiredTraining,
        .cardioDance
    ]
    
    static let indoorOutdoorList: [Sport] = [.running, .cycling, .walking]
    static let importSupportedSports: [Sport] = [.cycling, .running, .walking]
    static let distanceSports: [Sport] = [.cycling, .walking, .running, .hiking]
    static let walkingAndRunningSports: [Sport] = [.walking, .running, .hiking]
    static let speedSports: [Sport] = [.cycling]
    static let splitSports: [Sport] = [.cycling, .walking, .running, .hiking]
}

extension HKWorkoutActivityType {
    
    static var availableActivityTypes: [HKWorkoutActivityType] = {
        Sport.supportedSports.map({ $0.activityType })
    }()
    
    func sport() -> Sport {
        switch self {
        case .cycling: return .cycling
        case .running: return .running
        case .walking: return .walking
        case .hiking: return .hiking
        case .yoga: return .yoga
        case .pilates: return .pilates
        case .mindAndBody: return .mindAndBody
        case .cooldown: return .cooldown
        case .tennis: return .tennis
        case .pickleball: return .pickleball
        case .squash: return .squash
        case .coreTraining: return .coreTraining
        case .mixedCardio: return .mixedCardio
        case .highIntensityIntervalTraining: return .highIntensityIntervalTraining
        case .traditionalStrengthTraining: return .traditionalStrengthTraining
        case .elliptical: return .elliptical
        case .rowing: return .rowing
        case .socialDance: return .socialDance
        case .dance: return .socialDance
        case .danceInspiredTraining: return .socialDance
        case .cardioDance: return .cardioDance
        case .crossTraining: return .crossTraining
        case .functionalStrengthTraining: return .functionalStrengthTraining
        default: return .other
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

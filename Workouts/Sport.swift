//
//  Sport.swift
//  Workouts
//
//  Created by Axel Rivera on 2/10/21.
//

import SwiftUI

enum Sport: String, Identifiable, CaseIterable {
    case cycling, running, walking, other
    var id: String { rawValue }
    
    init(string: String) {
        self = Sport(rawValue: string) ?? .other
    }
    
    var isSupported: Bool {
        Self.supportedSports.contains(self)
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
    
    var title: String {
        self.rawValue.capitalized
    }
    
    var normalizedDistanceValue: Double {
        switch self {
        case .cycling:
            return 3
        default:
            return 3
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
    
    var color: Color {
        switch self {
        case .cycling: return .cycling
        case .running: return .running
        case .walking: return .walking
        default: return .sport
        }
    }
    
    var name: String {
        switch self {
        case .cycling: return "Cycle"
        case .running: return "Run"
        case .walking: return "Walk"
        default: return "Generic Activity"
        }
    }
    
    var altName: String {
        switch self {
        case .cycling: return "Ride"
        case .running: return "Run"
        case .walking: return "Walk"
        default: return "Generic Activity"
        }
    }
    
    static let indoorOutdoorList: [Sport] = [.running, .cycling, .walking]
    static let supportedSports: [Sport] = [.cycling, .running, .walking]
    static let distanceSports: [Sport] = [.cycling, .walking, .running]
    static let walkingAndRunningSports: [Sport] = [.walking, .running]
    static let speedSports: [Sport] = [.cycling]
}

//
//  Sport.swift
//  Workouts
//
//  Created by Axel Rivera on 2/10/21.
//

import Foundation

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
    
    var title: String {
        self.rawValue.capitalized
    }
    
    var name: String {
        switch self {
        case .cycling:
            return "Cycle"
        case .running:
            return "Run"
        case .walking:
            return "Walk"
        default:
            return "Generic Activity"
        }
    }
    
    static let supportedSports: [Sport] = [.cycling]
    static let distanceSports: [Sport] = [.cycling, .walking, .running]
    static let walkingAndRunningSports: [Sport] = [.walking, .running]
}

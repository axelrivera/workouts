//
//  DataProvider.swift
//  Workouts
//
//  Created by Axel Rivera on 5/31/21.
//

import Foundation
import CoreData
import SwiftUI

final class DataProvider {
    let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
}

// MARK: - Requests

extension DataProvider {
    
    static func fetchRequest(for identifiers: [UUID]) -> FetchRequest<Workout> {
        let request = Workout.defaultFetchRequest()
        request.predicate = Workout.predicateForIdentifiers(identifiers)
        request.sortDescriptors = [Workout.sortedByDateDescriptor()]
        request.returnsObjectsAsFaults = false
        
        return FetchRequest(fetchRequest: request, animation: .default)
        
    }
    
    static func fetchRequest(sport: Sport?, interval: DateInterval?) -> FetchRequest<Workout> {
        let request = Workout.defaultFetchRequest()
        request.predicate = Workout.activePredicate(sport: sport, interval: interval)
        request.sortDescriptors = [Workout.sortedByDateDescriptor()]
        
        return FetchRequest(fetchRequest: request, animation: .default)
    }
    
}

// MARK: - Predicates

extension DataProvider {
    
    enum DataError: Error {
        case missingPropertyDictionary
    }
    
    static func fetchRequestForSport(sport: Sport?, interval: DateInterval?) -> NSFetchRequest<NSFetchRequestResult> {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: Workout.entityName)
        request.returnsObjectsAsFaults = false
        request.predicate = Workout.activePredicate(sport: sport, interval: interval)
        return request
    }
    
}

// MARK: - Summary

extension DataProvider {
    
    var totalWorkouts: Int {
        let request = Workout.sortedFetchRequest
        do {
            return try context.count(for: request)
        } catch {
            return 0
        }
    }
    
    func fetchStatsSummary(sport: Sport?, interval: DateInterval) throws -> [String: Any] {
        let distanceDesc = expressionDescription(for: .distance, function: .sum)
        let durationDesc = expressionDescription(for: .duration, function: .sum)
        let elevationDesc = expressionDescription(for: .elevation, function: .sum)
        let energyDesc = expressionDescription(for: .energyBurned, function: .sum)
        let maxDistanceDesc = expressionDescription(for: .longestDistance, function: .max)
        let maxElevationDesc = expressionDescription(for: .highestElevation, function: .max)
        
        let request = Self.fetchRequestForSport(sport: sport, interval: interval)
        request.resultType = .dictionaryResultType
        request.propertiesToFetch = [
            distanceDesc, durationDesc, elevationDesc, energyDesc, maxDistanceDesc, maxElevationDesc
        ]
        
        do {
            let count = try context.count(for: request)
            let results = try context.fetch(request)
            guard let first = results.first, let dictionary = first as? [String: Double] else {
                throw DataError.missingPropertyDictionary
            }
            
            var newDictionary: [String: Any] = dictionary
            newDictionary[Name.count.key] = count
            return newDictionary
        } catch {
            throw error
        }
    }
    
}

// MARK: - Samples

extension DataProvider {
    
    struct Function: RawRepresentable {
        typealias RawValue = String
        let rawValue: String
        
        static let sum = Function(rawValue: "sum:")
        static let max = Function(rawValue: "max:")
    }
    
    struct Name: RawRepresentable, Equatable {
        typealias RawValue = String
        let rawValue: String
        
        static let count = Name(rawValue: "count")
        static let distance = Name(rawValue: "distance")
        static let duration = Name(rawValue: "movingTime")
        static let elevation = Name(rawValue: "elevation")
        static let energyBurned = Name(rawValue: "energyBurned")
        static let longestDistance = Name(rawValue: "longestDistance")
        static let highestElevation = Name(rawValue: "highestElevation")
        
        var key: String {
            return rawValue
        }
        
        var property: String {
            switch self {
            case .elevation, .highestElevation:
                return "elevationAscended"
            case .longestDistance:
                return "distance"
            default:
                return rawValue
            }
        }
    }
    
    private func expressionDescription(for name: Name, function: Function) -> NSExpressionDescription {
        let expressionDesc = NSExpressionDescription()
        expressionDesc.name = name.key
        expressionDesc.expression = NSExpression(
            forFunction: function.rawValue,
            arguments: [NSExpression(forKeyPath: name.property)]
        )
        expressionDesc.expressionResultType = .doubleAttributeType
        return expressionDesc
    }
    
}

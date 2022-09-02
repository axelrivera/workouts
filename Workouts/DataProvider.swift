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
    
    static func fetchRequest(sports: [Sport]) -> FetchRequest<Workout> {
        let request = Workout.defaultFetchRequest()
        request.predicate = Workout.activePredicate(sports: sports, interval: nil)
        request.sortDescriptors = [Workout.sortedByDateDescriptor()]
        request.fetchBatchSize = 10
        return FetchRequest(fetchRequest: request, animation: .default)
    }
    
    static func fetchRequest(sport: Sport?, interval: DateInterval?, identifiers: [UUID] = []) -> FetchRequest<Workout> {
        let request = Workout.defaultFetchRequest()
        request.predicate = Workout.activePredicate(sport: sport, interval: interval, identifiers: identifiers)
        request.sortDescriptors = [Workout.sortedByDateDescriptor()]
        request.fetchBatchSize = 10
        
        return FetchRequest(fetchRequest: request, animation: .default)
    }
    
    static func fetchFetquest(for predicate: NSPredicate) -> FetchRequest<Workout> {
        let request = Workout.defaultFetchRequest()
        request.predicate = predicate
        request.sortDescriptors = [Workout.sortedByDateDescriptor()]
        request.fetchBatchSize = 10
        
        return FetchRequest(fetchRequest: request, animation: .default)
    }
    
    func totalWorkouts(sport: Sport?, interval: DateInterval?) -> Int {
        do {
            let request = Workout.defaultFetchRequest()
            request.predicate = Workout.activePredicate(sport: sport, interval: interval)
            return try context.count(for: request)
        } catch {
            return 0
        }
    }
    
}

// MARK: - Workouts

extension DataProvider {
    
    func workoutIdentifiers(for predicate: NSPredicate) -> [UUID] {
        context.performAndWait {
            do {
                let request = NSFetchRequest<NSDictionary>(entityName: Workout.entityName)
                request.predicate = predicate
                request.resultType = .dictionaryResultType
                request.propertiesToFetch = ["remoteIdentifier"]
                request.returnsObjectsAsFaults = false
                
                return try context.fetch(request).compactMap { dictionary in
                    dictionary["remoteIdentifier"] as? UUID
                }
            } catch {
                return []
            }
        }
    }
    
}

// MARK: - Predicates

extension DataProvider {
    
    enum DataError: Error {
        case missingPropertyDictionary
        case failure
    }
    
    static func fetchRequest(for identifiers: [UUID]) -> NSFetchRequest<NSFetchRequestResult> {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: Workout.entityName)
        request.returnsObjectsAsFaults = false
        request.predicate = Workout.predicateForIdentifiers(identifiers)
        return request
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
        context.performAndWait {
            let request = Workout.sortedFetchRequest
            do {
                return try context.count(for: request)
            } catch {
                return 0
            }
        }
    }
    
    func dateIntervalForActiveWorkouts() -> DateInterval {
        context.performAndWait {
            let request = Workout.defaultFetchRequest()
            request.predicate = Workout.activePredicate(sport: nil, interval: nil)
            request.sortDescriptors = [Workout.sortedByDateDescriptor(ascending: true)]
            
            do {
                let workouts = try context.fetch(request)
                let start = workouts.first?.start ?? Date()
                let end = workouts.last?.start ?? start
                return DateInterval(start: start, end: end)
            } catch {
                let date = Date()
                return DateInterval(start: date.startOfDay, end: date.endOfDay)
            }
        }
    }
    
    func fetchTotalDistanceAndDuration(for predicate: NSPredicate) -> (total: Int, distance: Double, duration: Double) {
        context.performAndWait {
            let distance = expressionDescription(for: .distance, function: .sum)
            let duration = expressionDescription(for: .duration, function: .sum)
            
            let countRequest = Workout.defaultFetchRequest()
            countRequest.predicate = predicate

            let request = NSFetchRequest<NSFetchRequestResult>(entityName: Workout.entityName)
            request.returnsObjectsAsFaults = false
            request.resultType = .dictionaryResultType
            request.predicate = predicate
            request.propertiesToFetch = [distance, duration]
            
            do {
                let count = try context.count(for: countRequest)
                let results = try context.fetch(request)
                guard let first = results.first, let dictionary = first as? [String: Double] else {
                    throw DataError.missingPropertyDictionary
                }
                
                let distance: Double = dictionary[Name.distance.key] ?? 0
                let duration: Double = dictionary[Name.duration.key] ?? 0
                return (count, distance, duration)
            } catch {
                return (0, 0, 0)
            }
        }
    }
    
    func fetchStatsSummary(for identifiers: [UUID]) throws -> [String: Any] {
        try fetchStatsSummary(for: Workout.predicateForIdentifiers(identifiers))
    }
    
    func fetchStatsSummary(for predicate: NSPredicate) throws -> [String: Any] {
        try context.performAndWait {
            let distance = expressionDescription(for: .distance, function: .sum)
            let avgDistance = expressionDescription(for: .avgDistance, function: .avg)
            let duration = expressionDescription(for: .duration, function: .sum)
            let avgDuration = expressionDescription(for: .avgDuration, function: .avg)
            let elevation = expressionDescription(for: .elevation, function: .sum)
            let avgElevation = expressionDescription(for: .avgElevation, function: .avg)
            let energy = expressionDescription(for: .energyBurned, function: .sum)
            let avgEnergy = expressionDescription(for: .avgEnergyBurned, function: .avg)
            
            let countRequest = Workout.defaultFetchRequest()
            countRequest.predicate = predicate
            
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: Workout.entityName)
            request.returnsObjectsAsFaults = false
            request.resultType = .dictionaryResultType
            request.predicate = predicate
            
            request.propertiesToFetch = [
                distance, avgDistance, duration, avgDuration, elevation, avgElevation, energy, avgEnergy
            ]
            
            var resultDictionary = [String: Any]()
            
            do {
                let count = try context.count(for: countRequest)
                let results = try context.fetch(request)
                guard let first = results.first, let dictionary = first as? [String: Double] else {
                    throw DataError.missingPropertyDictionary
                }
                
                resultDictionary = dictionary
                resultDictionary[Name.count.key] = count
            } catch {
                resultDictionary = [String: Any]()
            }
            
            if resultDictionary.isEmpty {
                throw DataError.missingPropertyDictionary
            } else {
                return resultDictionary
            }
        }
    }
    
}

// MARK: - Helper Methods

typealias StatsProperties = DataProvider.Name

extension DataProvider {
    
    struct Function: RawRepresentable {
        typealias RawValue = String
        let rawValue: String
        
        static let sum = Function(rawValue: "sum:")
        static let max = Function(rawValue: "max:")
        static let avg = Function(rawValue: "average:")
    }
    
    struct Name: RawRepresentable, Equatable {
        typealias RawValue = String
        let rawValue: String
        
        static let count = Name(rawValue: "count")
        static let distance = Name(rawValue: "distance")
        static let avgDistance = Name(rawValue: "avgDistance")
        static let duration = Name(rawValue: "movingTime")
        static let avgDuration = Name(rawValue: "avgDuration")
        static let elevation = Name(rawValue: "elevation")
        static let avgElevation = Name(rawValue: "avgElevation")
        static let energyBurned = Name(rawValue: "energyBurned")
        static let avgEnergyBurned = Name(rawValue: "avgEnergyBurned")
        
        var key: String {
            return rawValue
        }
        
        var property: String {
            switch self {
            case .elevation, .avgElevation:
                return "elevationAscended"
            case .avgDistance:
                return "distance"
            case .avgDuration:
                return "movingTime"
            case .avgEnergyBurned:
                return "energyBurned"
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

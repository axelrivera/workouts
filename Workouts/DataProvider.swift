//
//  DataProvider.swift
//  Workouts
//
//  Created by Axel Rivera on 5/31/21.
//

import Foundation
import CoreData

private let StartDateKey = "start"
private let EndDateKey = "end"

final class DataProvider {
    let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
}

// MARK: - Predicates

extension DataProvider {
    
    enum DataError: Error {
        case missingPropertyDictionary
    }
    
    static func datePredicateFor(start: Date, end: Date) -> NSPredicate {
        NSPredicate(
            format: "%K >= %@ AND %K <= %@",
            EndDateKey, start as NSDate,
            StartDateKey, end as NSDate
        )
    }
    
    static func fetchRequestForSport(sport: Sport, timeframe: StatsSummary.Timeframe) -> NSFetchRequest<NSFetchRequestResult> {
        let (start, end) = timeframe.interval
        
        let sportPredicate = Workout.predicateForSport(sport)
        let visiblePredicate = Workout.notMarkedForLocalDeletionPredicate
        let datePredicate = datePredicateFor(start: start, end: end)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [sportPredicate, visiblePredicate, datePredicate])
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Workout")
        request.returnsObjectsAsFaults = false
        request.predicate = predicate
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
    
    func fetchStatsSummary(sport: Sport, timeframe: StatsSummary.Timeframe) throws -> StatsSummary {
        let distanceDesc = expressionDescriptionForProperty(.distance, function: .sum)
        let durationDesc = expressionDescriptionForProperty(.duration, function: .sum)
        let elevationDesc = expressionDescriptionForProperty(.elevation, function: .sum)
        let energyDesc = expressionDescriptionForProperty(.energyBurned, function: .sum)
        let maxDistanceDesc = expressionDescriptionForProperty(.distance, function: .max)
        let maxElevationDesc = expressionDescriptionForProperty(.elevation, function: .max)
        
        let request = Self.fetchRequestForSport(sport: sport, timeframe: timeframe)
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
            
            var summary = StatsSummary(sport: sport, timeframe: timeframe)
            summary.count = count
            summary.distance = dictionary[Property.distance.nameFor(function: .sum)] ?? 0
            summary.duration = dictionary[Property.duration.nameFor(function: .sum)] ?? 0
            summary.elevation = dictionary[Property.elevation.nameFor(function: .sum)] ?? 0
            summary.energyBurned = dictionary[Property.energyBurned.nameFor(function: .sum)] ?? 0
            summary.longestDistance = dictionary[Property.distance.nameFor(function: .max)] ?? 0
            summary.highestElevation = dictionary[Property.elevation.nameFor(function: .max)] ?? 0
            return summary
        } catch {
            throw error
        }
    }
    
}

// MARK: - Samples

extension DataProvider {
    
    enum ExpressionFunction: String {
        case sum, max
        
        var value: String {
            switch self {
            case .sum:
                return "sum:"
            case .max:
                return "max:"
            }
            
        }
    }
    
    enum Property: String {
        case distance, duration, energyBurned, elevation
        
        var name: String {
            switch self {
            case .elevation:
                return "elevationAscended"
            default:
                return rawValue
            }
        }
        
        func nameFor(function: ExpressionFunction) -> String {
            name + function.rawValue.firstCapitalized
        }
    }
    
    private func expressionDescriptionForProperty(_ property: Property, function: ExpressionFunction) -> NSExpressionDescription {
        let expressionDesc = NSExpressionDescription()
        expressionDesc.name = property.nameFor(function: function)
        expressionDesc.expression = NSExpression(
            forFunction: function.value,
            arguments: [NSExpression(forKeyPath: property.name)]
        )
        expressionDesc.expressionResultType = .doubleAttributeType
        return expressionDesc
    }
    
}

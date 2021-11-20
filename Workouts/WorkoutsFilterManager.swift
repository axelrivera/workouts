//
//  WorkoutsFilter.swift
//  Workouts
//
//  Created by Axel Rivera on 11/13/21.
//

import Foundation
import Combine
import CoreData
import SwiftUI

final class WorkoutsFilterManager: ObservableObject {
    static private let nonDecimalCharacters = CharacterSet.decimalDigits.inverted
    
    @Published var sports = Set<Sport>()
    
    @Published var showFavorites = false
    @Published var showDateRange = false
    
    @Published var startDate: Date = Date()
    @Published var endDate: Date = Date()
    @Published var minDistance: String = ""
    @Published var maxDistance: String = ""
    
    @Published var total: Int = 0
    @Published var distance: Double = 0
    @Published var duration: Double = 0
        
    private let context: NSManagedObjectContext
    private let dataProvider: DataProvider
    
    init(context: NSManagedObjectContext) {
//        sports = [.cycling]
        
        self.context = context
        self.dataProvider = DataProvider(context: context)
    }
    
}

extension WorkoutsFilterManager {
    
    func count() -> Int {
        let request = Workout.defaultFetchRequest()
        request.predicate = filterPredicate()
        
        do {
            return try context.count(for: request)
        } catch {
            return 0
        }
    }
    
    func updateTotals() {
        let (total, distance, duration) = dataProvider.fetchTotalDistanceAndDuration(for: filterPredicate())
        DispatchQueue.main.async {
            self.total = total
            self.distance = distance
            self.duration = duration
        }
    }
    
    var isFilterActive: Bool {
        if sports.isPresent { return true }
        if showFavorites { return true }
        if showDateRange { return true }
        if let _ = minDistanceValue { return true }
        if let _ = maxdistanceValue { return true }
        return false
    }
    
    func reset() {
        sports = Set<Sport>()
        showFavorites = false
        showDateRange = false
        startDate = Date()
        endDate = Date()
        maxDistance = ""
        minDistance = ""
    }
    
    func isSportSelected(_ sport: Sport) -> Bool {
        sports.contains(sport)
    }
    
    func togggleSport(_ sport: Sport) {
        withAnimation {
            if isSportSelected(sport) {
                sports.remove(sport)
            } else {
                sports.insert(sport)
            }
        }
    }
    
}

extension WorkoutsFilterManager {
    
    var totalString: String {
        "\(total.formatted()) Workouts"
    }
    
    var distanceString: String {
        formattedDistanceString(for: distance, zeroPadding: true)
    }
    
    var durationString: String {
        formattedHoursMinutesPrettyString(for: duration)
    }
    
}

// MARK: - Core Data

extension WorkoutsFilterManager {
    
    var isUsingIdentifiers: Bool {
        showFavorites
    }
    
    func filterPredicate() -> NSPredicate {
        var predicates = [Workout.notMarkedForLocalDeletionPredicate]
        
        var ids = Set<UUID>()
        
        if showFavorites {
            let favorites = WorkoutMetadata.favorites(in: context)
            ids.formUnion(favorites)
        }
        
        // query should be false if validating by identifiers and there are no identifiers present
        if isUsingIdentifiers && ids.isEmpty {
            return Workout.distantFuturePredicate()
        }
        
        if ids.isPresent {
            predicates.append(Workout.predicateForIdentifiers(Array(ids)))
        }
        
        if showDateRange {
            let start = startDate.startOfDay
            let end = endDate.endOfDay
            
            let interval = DateInterval(start: start, end: end)
            predicates.append(Workout.predicateForInterval(interval))
        }
        
        if sports.isPresent {
            predicates.append(Workout.predicateForSports(Array(sports)))
        }
        
        if let distance = minDistanceValue {
            predicates.append(Workout.predicateForMinDistance(distance))
        }
        
        if let distance = maxdistanceValue {
            predicates.append(Workout.predicateForMaxDistance(distance))
        }
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
    
    private var minDistanceValue: Double? {
        guard let distance = Double(minDistance.removingCharacters(in: Self.nonDecimalCharacters)) else { return nil }
        return localizedDistanceToMeters(for: distance)
    }
    
    private var maxdistanceValue: Double? {
        guard let distance = Double(maxDistance.removingCharacters(in: Self.nonDecimalCharacters)) else { return nil }
        return localizedDistanceToMeters(for: distance)
    }
    
}

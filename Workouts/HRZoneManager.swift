//
//  HRZoneManager.swift
//  Workouts
//
//  Created by Axel Rivera on 6/25/21.
//

import CoreData

class HRZoneManager: ObservableObject {
    struct Defaults {
        static let max: Int = 200
        static let percents: [Double] = [0.7, 0.8, 0.9, 1]
    }
    
    @Published var maxHeartRate: Int {
        didSet {
            AppSettings.maxHeartRate = maxHeartRate
        }
    }
    
    // Don't update values directly, use helper method
    @Published var values: [Int]
     
    init(maxHeartRate: Int, zoneValues: [Int]) {
        if maxHeartRate > 0 && zoneValues.isPresent {
            self.maxHeartRate = maxHeartRate
            values = zoneValues
        } else {
            self.maxHeartRate = AppSettings.maxHeartRate
            values = AppSettings.heartRateZones
        }
    }
    
    convenience init() {
        self.init(maxHeartRate: AppSettings.maxHeartRate, zoneValues: AppSettings.heartRateZones)
    }
    
}

extension HRZoneManager {
    
    func autoCalculate() {
        values = Self.calculateDefaultZones(for: Double(maxHeartRate), percentZones: Defaults.percents)
        AppSettings.heartRateZones = values
    }
    
    func incrementZone(_ zone: HRZone) {
        if zone == .zone1 { return }
        let index = indexForZone(zone)
        let (_, max) = rangeForZone(zone)
         
        
        let value = values[index]
        let futureValue = value + 1
        let maxValue = max > 0 ? max : maxHeartRate + 1
        
        if futureValue < maxValue {
            updateValue(futureValue, at: index)
        }
    }
    
    func decrementZone(_ zone: HRZone) {
        if zone == .zone1 { return }
        let index = indexForZone(zone)
        let (min, _) = prevRangeForZone(zone)
        
        let value = values[index]
        let futureValue = value - 1
        let minValue = min + 1
        
        if futureValue > minValue {
            updateValue(futureValue, at: index)
        }
    }
    
    private func updateValue(_ value: Int, at index: Int) {
        guard index < values.count else {
            assertionFailure("invalid index")
            return
        }
        values[index] = value
        AppSettings.heartRateZones = values
    }
        
    private func indexForZone(_ zone: HRZone) -> Int {
        switch zone {
        case .zone2: return 0
        case .zone3: return 1
        case .zone4: return 2
        case .zone5: return 3
        default: fatalError("invalid index")
        }
    }
    
    private func prevRangeForZone(_ zone: HRZone) -> ZoneRange {
        switch zone {
        case .zone2: return zone1Range
        case .zone3: return zone2Range
        case .zone4: return zone3Range
        case .zone5: return zone4Range
        default: fatalError("invalid zone")
        }
    }
    
    func rangeForZone(_ zone: HRZone) -> ZoneRange {
        switch zone {
        case .zone1: return zone1Range
        case .zone2: return zone2Range
        case .zone3: return zone3Range
        case .zone4: return zone4Range
        case .zone5: return zone5Range
        }
    }
    
    func percentRangeForZone(_ zone: HRZone) -> ZonePercentRange {
        switch zone {
        case .zone1: return zone1PercentRange
        case .zone2: return zone2PercentRange
        case .zone3: return zone3PercentRange
        case .zone4: return zone4PercentRange
        case .zone5: return zone5PercentRange
        }
    }
    
}

extension HRZoneManager {
    
    typealias ZoneRange = (low: Int, high: Int)
    typealias ZonePercentRange = (low: Double, high: Double)
    
    
    // MARK: Ranges
    
    var zone1Range: ZoneRange {
        (0, values[0] - 1)
    }
    
    var zone2Range: ZoneRange {
        (values[0], values[1] - 1)
    }
    
    var zone3Range: ZoneRange {
        (values[1], values[2] - 1)
    }
    
    var zone4Range: ZoneRange {
        (values[2], values[3] - 1)
    }
    
    var zone5Range: ZoneRange {
        (values[3], 0)
    }
    
    // MARK: Percents
    
    var zone1PercentRange: ZonePercentRange {
        percentRange(for: zone1Range)
    }
    
    var zone2PercentRange: ZonePercentRange {
        percentRange(for: zone2Range)
    }
    
    var zone3PercentRange: ZonePercentRange {
        percentRange(for: zone3Range)
    }
    
    var zone4PercentRange: ZonePercentRange {
        percentRange(for: zone4Range)
    }
    
    var zone5PercentRange: ZonePercentRange {
        percentRange(for: zone5Range)
    }
    
    private func percentRange(for range: ZoneRange) -> ZonePercentRange {
        (percent(for: range.low), percent(for: range.high))
    }
    
    private func percent(for value: Int) -> Double {
        guard maxHeartRate > 0 else { return 0 }
        return (Double(value) / Double(maxHeartRate)) * 100
    }
    
}

// MARK: - Formatting Methods

extension HRZoneManager {
    
    static func stringForPercentRange(_ range: ZonePercentRange) -> String {
        if range.low == 0 && range.high > 0 {
            return String(format: "< %.0f%% of HR max", range.high)
        }
        
        if range.low > 0 && range.high == 0 {
            return String(format: "> %.0f%% of HR max", range.low)
        }
        
        return String(format: "%.0f - %.0f%% of HR max", range.low, range.high)
    }
    
    static func stringForRange(_ range: ZoneRange) -> String {
        if range.low > 0 && range.high == 0 {
            return String(format: "%d - ∞ bpm", range.low)
        }
        
        return String(format: "%d - %d bpm", range.low, range.high)
    }
    
    static func calculateDefaultZones(for maxHeartRate: Double, percentZones: [Double]) -> [Int] {
        percentZones.map { Int(ceil($0 * Double(maxHeartRate))) }
    }
    
}

// MARK: Core Data

extension HRZoneManager {
    
    enum DataError: Error {
        case database
        case missingZone
    }
    
    func fetchZones(for workout: Workout, context: NSManagedObjectContext) throws -> [HRZoneSummary] {
        let total = try heartRateSamplesDuration(for: nil, workout: workout, context: context)
        
        var summaries = [HRZoneSummary]()
        for zone in HRZone.allCases {
            let range = rangeForZone(zone)
            let duration = try heartRateSamplesDuration(for: range, workout: workout, context: context)
            let text = Self.stringForRange(range)
            let summary = HRZoneSummary(name: zone.name, color: zone.color, text: text, duration: duration, totalDuration: total)
            summaries.append(summary)
        }
        
        guard summaries.count == HRZone.allCases.count else { throw DataError.missingZone }
        return summaries
    }
    
    static func fetchRequestForHeartRateSamples(workout: Workout, range: HRZoneManager.ZoneRange?) -> NSFetchRequest<NSFetchRequestResult> {
        let predicate = Sample.heartRatePredicateForWorkout(workout, range: range)
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: Sample.entityName)
        request.returnsObjectsAsFaults = false
        request.predicate = predicate
        return request
    }
    
    private func heartRateSamplesDuration(for range: ZoneRange?, workout: Workout, context: NSManagedObjectContext) throws -> Double {
        let request = Self.fetchRequestForHeartRateSamples(workout: workout, range: range)
        do {
            let result = try context.count(for: request)
            return Double(result)
        } catch {
            throw error
        }
        
    }
    
}

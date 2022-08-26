//
//  HRZonesCalculator.swift
//  Workouts
//
//  Created by Axel Rivera on 7/31/22.
//

import Foundation
import HealthKit

final class HRZonesCalculator {
    static let DEFAULT_PERCENTS: [Int] = [50, 60, 70, 80, 90]
    static let TOTAL_ZONES: Int = 5
    static let CONVERSION_FACTOR: Double = 100
    
    typealias ZoneRange = (low: Int, high: Int)
    typealias ZonePercentRange = (low: Int, high: Int)
    
    let maxHeartRate: Int
    private(set) var values: [Int]
    
    init(maxHeartRate: Int, values: [Int]) {
        self.maxHeartRate = maxHeartRate
        
        if values.isEmpty {
            self.values = Self.defaultValues(for: maxHeartRate)
        } else {
            self.values = values
        }
    }
    
    func updateValues(_ values: [Int]) {
        guard values.count == Self.TOTAL_ZONES  else {
            assertionFailure("there should be 5 values")
            return
        }
        self.values = values
    }
    
    var percentValues: [Int] {
        values.map { percent(for: $0) }
    }
    
}

// MARK: - Methods

extension HRZonesCalculator {
    
    static func empty() -> HRZonesCalculator {
        let maxHeartRate = AppSettings.DEFAULT_MAX_HEART_RATE
        let values = values(for: DEFAULT_PERCENTS, maxHeartRate: maxHeartRate)
        return HRZonesCalculator(maxHeartRate: maxHeartRate, values: values)
    }
    
    static func percentForValue(_ value: Int, maxHeartRate: Int) -> Int {
        guard maxHeartRate > 0 else { return 0 }
        
        let max = Double(maxHeartRate)
        let doubleValue = Double(value)
        let result = (doubleValue / max) * CONVERSION_FACTOR
        return Int(round(result))
    }
    
    static func percents(values: [Int], maxHeartRate: Int) -> [Int] {
        values.map { percentForValue($0, maxHeartRate: maxHeartRate) }
    }
    
    static func values(for percents: [Int], maxHeartRate: Int) -> [Int] {
        return percents.map { percent in
            let fraction = Double(percent) / CONVERSION_FACTOR
            let result = Double(maxHeartRate) * fraction
            return Int(round(result))
        }
    }
    
    static func defaultValues(for maxHeartRate: Int) -> [Int] {
        values(for: DEFAULT_PERCENTS, maxHeartRate: maxHeartRate)
    }
    
    func defaultValues() -> [Int] {
        Self.defaultValues(for: maxHeartRate)
    }
    
    func forEach(_ handler: ((_ zone: HRZone, _ range: ZoneRange) -> Void)) {
        for zone in HRZone.allCases {
            let range = rangeForZone(zone)
            handler(zone, range)
        }
    }
    
    func summaries(for quantities: [Quantity]) throws -> [HRZoneSummary] {
        let total = quantities.count
        var summaries = [HRZoneSummary]()
        
        forEach { zone, range in
            let duration = quantities.filteredByZoneRange(range).count
            let text = Self.stringForRange(range)
            let summary = HRZoneSummary(name: zone.name, color: zone.color, text: text, duration: Double(duration), totalDuration: Double(total))
            summaries.append(summary)
        }
        
        guard summaries.count == HRZone.allCases.count else { throw WorkoutError("missing zone") }
        return summaries
    }
    
}

// MARK: - Updating

extension HRZonesCalculator {
    
    func incrementZone(_ zone: HRZone) {
        let index = indexForZone(zone)
        let (_, max) = rangeForZone(zone)
         
        let value = values[index]
        let futureValue = value + 1
        let maxValue = max > 0 ? max : Int(maxHeartRate) + 1
                
        if futureValue < maxValue {
            updateValue(futureValue, at: index)
        }
    }
    
    func decrementZone(_ zone: HRZone) {
        let index = indexForZone(zone)
        let (min, _) = prevRangeForZone(zone) ?? (0, 0)
        
        let value = values[index]
        let futureValue = value - 1
        let minValue = min > 0 ? min + 1 : 0
                
        if futureValue > minValue {
            updateValue(futureValue, at: index)
        }
    }
    
    private func updateValue(_ value: Int, at index: Int) {
        guard index < values.count else {
            assertionFailure("invalid index")
            return
        }
        
        self.values[index] = value
    }
    
}

// MARK: - Ranges

extension HRZonesCalculator {
    
    func rangeForZone(_ zone: HRZone) -> ZoneRange {
        switch zone {
        case .zone1:
            return zone1Range
        case .zone2:
            return zone2Range
        case .zone3:
            return zone3Range
        case .zone4:
            return zone4Range
        case .zone5:
            return zone5Range
        }
    }
    
    var zone1Range: ZoneRange {
        (values[0], values[1] - 1)
    }
    
    var zone2Range: ZoneRange {
        (values[1], values[2] - 1)
    }
    
    var zone3Range: ZoneRange {
        (values[2], values[3] - 1)
    }
    
    var zone4Range: ZoneRange {
        (values[3], values[4] - 1)
    }
    
    var zone5Range: ZoneRange {
        (values[4], 0)
    }
    
    func indexForZone(_ zone: HRZone) -> Int {
        switch zone {
        case .zone1:
            return 0
        case .zone2:
            return 1
        case .zone3:
            return 2
        case .zone4:
            return 3
        case .zone5:
            return 4
        }
    }
    
    func prevRangeForZone(_ zone: HRZone) -> ZoneRange? {
        switch zone {
        case .zone1:
            return nil
        case .zone2:
            return zone1Range
        case .zone3:
            return zone2Range
        case .zone4:
            return zone3Range
        case .zone5:
            return zone4Range
        }
    }
    
    static func stringForRange(_ range: ZoneRange) -> String {
        if range.low > 0 && range.high == 0 {
            return String(format: "%d - ∞ bpm", range.low)
        }
        
        return String(format: "%d - %d bpm", range.low, range.high)
    }
    
}

// MARK: Percents

extension HRZonesCalculator {
    
    func percentRangeForZone(_ zone: HRZone) -> ZonePercentRange {
        switch zone {
        case .zone1: return percentRange(for: zone1Range)
        case .zone2: return percentRange(for: zone2Range)
        case .zone3: return percentRange(for: zone3Range)
        case .zone4: return percentRange(for: zone4Range)
        case .zone5: return percentRange(for: zone5Range)
        }
    }
    
    private func percentRange(for range: ZoneRange) -> ZonePercentRange {
        (percent(for: range.low), percent(for: range.high))
    }
    
    private func percent(for value: Int) -> Int {
        Self.percentForValue(value, maxHeartRate: maxHeartRate)
    }
    
    static func stringForPercentRange(_ range: ZonePercentRange) -> String {
        let low = Double(range.low)
        let high = Double(range.high)
        
        if low > 0 && high == 0 {
            return String(format: "> %.0f%% of HR max", low)
        }
        
        return String(format: "%.0f - %.0f%% of HR max", low, high)
    }
    
}

extension Sequence where Iterator.Element == Quantity {
    
    func filteredByZoneRange(_ range: HRZonesCalculator.ZoneRange?) -> [Quantity] {
        if let range = range {
            if range.low == 0 && range.high > 0 {
                return filter({ $0.value > 0 && $0.value <= Double(range.high) })
            } else if range.low > 0 && range.high == 0 {
                return filter({ $0.value >= Double(range.low) })
            } else {
                return filter({ $0.value >= Double(range.low) && $0.value <= Double(range.high) })
            }
        } else {
            return Array(self)
        }
    }
    
}

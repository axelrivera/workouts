//
//  Quantity.swift
//  Workouts
//
//  Created by Axel Rivera on 3/18/21.
//

import Foundation

struct Quantity: Identifiable, Hashable {
    var id: DateInterval { interval }
    
    let start: Date
    let end: Date
    let value: Double
    
    var timestamp: Date { start }
    
    var duration: Double {
        interval.duration
    }
    
    var interval: DateInterval {
        DateInterval(start: start, end: end)
    }
}

extension Collection where Element == Quantity {
    
    func quantityValues() -> [Double] {
        map { $0.value }
    }
    
    func maxValue() -> Double {
        quantityValues().max() ?? 0
    }
    
    func minValue() -> Double {
        quantityValues().min() ?? 0
    }
    
    func sumValues() -> Double {
        quantityValues().reduce(0, +)
    }
    
    func avgValue(excludeZeros: Bool = false) -> Double {
        if isEmpty { return 0 }
        
        if excludeZeros {
            let samples = filter({ $0.value > 0 })
            if samples.isEmpty {
                return 0
            } else {
                return samples.sumValues() / Double(samples.count)
            }
        } else {
            return sumValues() / Double(count)
        }
    }
    
}

extension Quantity {
    
    func fitsDistance(_ distance: Double) -> Bool {
        value <= distance
    }
    
    func canDistanceBeSplitByMultiples(_ distance: Double) -> Bool {
        let factor = value / distance
        return factor <= duration
    }
    
    func splitInMultiples(_ distance: Double) -> [Quantity] {
        guard canDistanceBeSplitByMultiples(distance) else { return [self] }
        
        let distanceFactor = value / distance
        let remainingDistance = distance * distanceFactor.truncatingRemainder(dividingBy: 1.0)
        let timeStep = trunc(duration / Double(distanceFactor))
        
        var partial = [Quantity]()
        if remainingDistance > 0.0 {
            let times = Int(ceil(distanceFactor))
            var startDate = start
            for idx in 0 ..< times {
                let isLast = idx == times - 1
                
                let endDate: Date
                let distanceValue: Double
                if isLast { // last
                    endDate = end
                    distanceValue = remainingDistance
                } else {
                    endDate = startDate.addingTimeInterval(timeStep)
                    distanceValue = distance
                }
                
                let quantity = Quantity(start: startDate, end: endDate, value: distanceValue)
                partial.append(quantity)
                
                let nextDate = Calendar.current.date(byAdding: .second, value: 1, to: endDate)!
                if nextDate > end {
                    startDate = end
                } else {
                    startDate = nextDate
                }
            }
        } else {
            let times = Int(trunc(distanceFactor))
            var startDate = start
            for idx in 0 ..< times {
                let isLast = idx == times - 1
                
                let endDate: Date
                if isLast { // last
                    endDate = end
                } else {
                    endDate = startDate.addingTimeInterval(timeStep)
                }
                
                let quantity = Quantity(start: startDate, end: endDate, value: distance)
                partial.append(quantity)
                
                let nextDate = Calendar.current.date(byAdding: .second, value: 1, to: endDate)!
                if nextDate > end {
                    startDate = end
                } else {
                    startDate = nextDate
                }
            }
        }
        
        return partial
    }
        
    func canDistanceBeSplitByTwo() -> Bool {
        duration >= 2
    }
    
    func splitInTwo() -> [Quantity] {
        guard canDistanceBeSplitByTwo() else { return [self] }
        let distanceValue = value / 2.0
        let timeStep = trunc(duration / 2.0)
        
        let quantity1End = start.addingTimeInterval(timeStep)
        let quantity1 = Quantity(start: start, end: quantity1End, value: distanceValue)
        
        let quantity2Start = Calendar.current.date(byAdding: .second, value: 1, to: quantity1End)!
        let quantity2 = Quantity(start: quantity2Start, end: end, value: distanceValue)
        return [quantity1, quantity2]
    }
    
}

extension Array where Element == Quantity {
    
    func sortedByStartDate() -> [Quantity] {
        sorted(by: { $0.start < $1.start })
    }
    
    func normalizedByInterval() -> [Quantity] {
        let sorted = sortedByStartDate()
        let total = sorted.count
                
        var samples = [Quantity]()
        for index in 0 ..< total {
            let current = sorted[index]
            
            let nextIndex = index + 1
            var next: Quantity?
            if nextIndex < total {
                next = sorted[nextIndex]
            }
            
            if let next = next, current.end == next.start, current.duration > 0 {
                let end = Calendar.current.date(byAdding: .second, value: -1, to: current.end)!
                samples.append(Quantity(start: current.start, end: end, value: current.value))
            } else {
                samples.append(current)
            }
        }
                
        return samples
    }
    
    func normalizedByDistance(sport: Sport) -> [Quantity] {        
        let normalizedDistance = sport.normalizedDistanceValue
        
        var samples = [Quantity]()
        for sample in self {
            if sample.fitsDistance(normalizedDistance) {
                samples.append(sample)
            } else {
                if sample.canDistanceBeSplitByMultiples(normalizedDistance) {
                    samples.append(contentsOf: sample.splitInMultiples(normalizedDistance))
                } else if sample.canDistanceBeSplitByTwo() {
                    samples.append(contentsOf: sample.splitInTwo())
                } else {
                    samples.append(sample)
                }
            }
        }
                
        return samples.sortedByStartDate()
    }
    
}

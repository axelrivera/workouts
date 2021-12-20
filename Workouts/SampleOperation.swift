//
//  SampleOperation.swift
//  Workouts
//
//  Created by Axel Rivera on 8/9/21.
//

import HealthKit

class SampleOperation: SyncOperation {
    private(set) var quantityType: HKQuantityType
    private(set) var unit: HKUnit
    private(set) var interval: DateInterval
    private(set) var source: HKSource?
    
    fileprivate(set) var samples = [Quantity]()
    fileprivate var provider = HealthProvider.shared
    
    init(quantityType: HKQuantityType, unit: HKUnit, interval: DateInterval, source: HKSource?) {
        self.quantityType = quantityType
        self.unit = unit
        self.interval = interval
        self.source = source
    }
    
}

final class MaxSampleOperation: SampleOperation {
    
    override func start() {
        super.start()
        
//        provider.fetchMaxSamples(quantityType: quantityType, unit: unit, interval: interval, source: source) { [weak self] result in
//            guard let self = self else { return }
//            do {
//                self.samples = try result.get()
//                Log.debug("found samples for \(self.quantityType), total: \(self.samples.count)")
//            } catch {
//                Log.debug("fetching samples for \(self.quantityType) failed: \(error.localizedDescription)")
//            }
//            self.finish()
//        }
    }
    
}

final class DistanceSampleOperation: SampleOperation {
    
    override func start() {
        super.start()
        
//        provider.fetchDistanceSamples(distanceType: quantityType, unit: unit, interval: interval) { [weak self] result in
//            guard let self = self else { return }
//            do {
//                self.samples = try result.get()
//                Log.debug("found samples for \(self.quantityType), total: \(self.samples.count)")
//            } catch {
//                Log.debug("fetching samples for \(self.quantityType) failed: \(error.localizedDescription)")
//            }
//            self.finish()
//        }
    }
    
}

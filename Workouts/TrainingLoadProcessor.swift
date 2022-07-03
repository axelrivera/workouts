//
//  TrainingLoadProcessor.swift
//  Workouts
//
//  Created by Axel Rivera on 6/27/22.
//

import Foundation

extension TrainingLoadProcessor {
    
    struct Input {
        let heartRate: Int
        let duration: Int
        
        var durationInMinutes: Double {
            Double(duration) / 60.0
        }
    }
    
}

struct TrainingLoadProcessor {
    // D is the duration in minutes at a particular Heart Rate
    // %HRR = (HR - HR_REST) / (HR_MAX - HR_REST)
    // y is the %HRR, multiplied by 1.92 for men and 1.67 for women.
    //
    // TRIMP = SUM(D x %HRR x 0.64e ^ y)
    //
    // A worked example would be a male athlete with a HRmax=200 and HRrest=40 training for 30 min. at 130 BPM. The TRIMPexp is therefore:
    //
    // TRIMP = 30 x (130-40) / (200-40) x 0.64e ^ (1.92 x (130-40) / (200-40))
    // TRIMP = 30 x 0.56 x 0.64e ^ (1.92 x 0.56)
    // TRIMP = 32 (rounded)
    
    let gender: UserGender
    let maxHeartRate: Int
    let restingHeartRate: Int
    let paddedHeartRateSamples: [Quantity]
    
    func trimp() -> Int {
        let inputValues = Self.inputValues(for: paddedHeartRateSamples)
        let values = inputValues.map({ value(for: $0) })
        return values.reduce(0, +)
    }
    
    private func value(for input: Input) -> Int {
        let hrFactor = percentHeartRateReserve(for: input.heartRate)
        let genderFactor = genderFactor()
        let y = genderFactor * hrFactor
        let value = input.durationInMinutes * hrFactor * (0.64 * exp(y))
        return Int(round(value))
    }
    
    func percentHeartRateReserve(for heartRate: Int) -> Double {
        let upper = heartRate - restingHeartRate
        let lower = maxHeartRate - restingHeartRate
        guard lower > 0 else { return 0 }
        return Double(upper) / Double(lower)
    }
    
    private func genderFactor() -> Double {
        switch gender {
        case .male: return 1.92
        case .female: return 1.67
        case .none: return 0.0
        }
    }
    
    static func inputValues(for quantities: [Quantity]) -> [TrainingLoadProcessor.Input] {
        var dictionary = [Int: Int]()
        
        for quantity in quantities {
            let intValue = Int(quantity.value)
            if let value = dictionary[intValue] {
                dictionary[intValue] = value + 1
            } else {
                dictionary[intValue] = 1
            }
        }
        
        return dictionary.map { (key, value) in
            Input(heartRate: key, duration: value)
        }
    }
    
}

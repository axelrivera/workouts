//
//  TimeAxisValue.swift
//  Workouts
//
//  Created by Axel Rivera on 3/16/21.
//

import Foundation

struct TimeAxisValue {
    let duration: TimeInterval
    let value: Double
}

extension TimeAxisValue {
    
    static var speedSamples = samplesForRange(10...20)
    static var heartRateSamples = samplesForRange(120...180)
    static var cyclingCadenceSamples = samplesForRange(60...100)
    static var altitudeSamples = samplesForRange(0...1000)
    
    static func samplesForRange(_ range: ClosedRange<Int>) -> [TimeAxisValue] {
        let now = Date()
        let secondsInMinute: Double = 60
        let twoHoursInSeconds: Double = 60 * 60 * 2
        
        let from = now.addingTimeInterval(-twoHoursInSeconds)
        let to = now
                
        let values = stride(from: from.timeIntervalSince1970, to: to.timeIntervalSince1970, by: secondsInMinute).map { (x) -> TimeAxisValue in
            return TimeAxisValue(duration: x, value: Double(Int.random(in: range)))
        }
        return values
    }
    
}


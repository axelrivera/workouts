//
//  Interpolator.swift
//  Workouts
//
//  Created by Axel Rivera on 5/28/21.
//

import Foundation

protocol Interpolator {
    associatedtype Value
    
    var points: [Value] { get }
    func interpolate(_ t: Float) -> Value
}

extension Interpolator {
    
    func resample(interval: Float) -> [Value] {
        let count = Int(floor(Float(points.count) / interval))
        return Array(0..<count).map { interpolate(Float($0) * interval) }
    }
    
}

extension Interpolator where Value == Float {
    
    func getClippedInput(_ i: Int) -> Value {
        return points[max(0, min(i, points.count - 1))]
    }
    
}

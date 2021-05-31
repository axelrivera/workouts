//
//  LinearInterpolator.swift
//  Workouts
//
//  Created by Axel Rivera on 5/28/21.
//

import Foundation

class LinearInterpolator: Interpolator {
    typealias Value = Float
    
    let points: [Value]

    required init(points: [Value]) {
        self.points = points
    }

    func interpolate(_ t: Float) -> Value {
        let k = Int(floor(t))
        let t2 = t - Float(k)
        return (1 - t2) * getClippedInput(k) + (t2) * getClippedInput(k + 1)
    }
    
}

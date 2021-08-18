//
//  CLLocation+Array.swift
//  CLLocation+Array
//
//  Created by Axel Rivera on 8/14/21.
//

import Foundation
import CoreLocation

extension Sequence where Iterator.Element: CLLocation {
    
    func speedValues() -> [Double] {
        map { $0.speed }
    }
    
    func hasSpeedValues() -> Bool {
        !speedValues().filter({ $0 > 0 }).isEmpty
    }
    
    func altitudeValues() -> [Double] {
        map { $0.altitude }
    }
    
    func hasAltitudeValues() -> Bool {
        !altitudeValues().filter({ $0 > 0 }).isEmpty
    }
    
}

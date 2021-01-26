//
//  GarminUtils.swift
//  Workouts
//
//  Created by Axel Rivera on 1/22/21.
//

import Foundation

private let GARMIN_EPOCH: Double = 631065600

func GarminDate(for timeInterval: TimeInterval) -> Date {
    Date(timeIntervalSince1970: GARMIN_EPOCH).addingTimeInterval(timeInterval)
}

func SemicircleToDegree(_ value: Double) -> Double {
    value * 180.0 / 2147483648.0 
}

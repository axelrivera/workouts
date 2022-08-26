//
//  TimestampUtils.swift
//  Workouts
//
//  Created by Axel Rivera on 6/24/22.
//

import Foundation

func KeyForTimestamp(_ timestamp: Date) -> Int {
    Int(truncating: timestamp.timeIntervalSince1970 as NSNumber)
}

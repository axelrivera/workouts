//
//  TimeHelper.swift
//  Workouts
//
//  Created by Axel Rivera on 1/11/21.
//

import Foundation

func secondsToHoursMinutesSeconds(seconds: Int) -> (Int, Int, Int) {
    (seconds / 3600, ((seconds % 3600) / 60), (seconds % 3600) % 60)
}

func secondsToHoursMinutes(seconds: Int) -> (Int, Int) {
    (seconds / 3600, ((seconds % 3600) / 60))
}

func formattedTimer(for seconds: Int) -> String {
    let (h, m, s) = secondsToHoursMinutesSeconds(seconds: seconds)
    return String(format: "%d:%02d:%02d", h, m, s)
}

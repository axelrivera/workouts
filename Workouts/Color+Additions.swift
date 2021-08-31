//
//  Color+Additions.swift
//  Workouts
//
//  Created by Axel Rivera on 12/20/20.
//

import SwiftUI

extension Color {
    static let lightText = Color(UIColor.lightText)
    static let darkText = Color(UIColor.darkText)

    static let label = Color(UIColor.label)
    static let secondaryLabel = Color(UIColor.secondaryLabel)
    static let tertiaryLabel = Color(UIColor.tertiaryLabel)
    static let quaternaryLabel = Color(UIColor.quaternaryLabel)

    static let systemBackground = Color(UIColor.systemBackground)
    static let secondarySystemBackground = Color(UIColor.secondarySystemBackground)
    static let tertiarySystemBackground = Color(UIColor.tertiarySystemBackground)
    static let divider = Color(UIColor.separator)
    static let selectedCell = divider
    
    static let systemFill = Color(UIColor.systemFill)
    static let darkGray = Color(UIColor.darkGray)
    static let lightGray = Color(UIColor.lightGray)
    static let systemYellow = Color(UIColor.systemYellow)
}

// MARK: Asset Colors

extension Color {
    static let distance = Color("DistanceColor")
    static let time = Color("TimeColor")
    static let calories = Color("CaloriesColor")
    static let elevation = Color("ElevationColor")
    static let speed = Color("SpeedColor")
    static let cadence = Color("CadenceColor")
    static let chartBackground = Color("ChartBackgroundColor")
    
    // Sport
    static let sport = Color("SportColor")
    static let cycling = Color("CyclingColor")
    static let running = Color("RunningColor")
    static let walking = Color("WalkingColor")
    
    // Workout Cards
    static let ruby = Color(hex: "E02020")
    static let amber = Color(hex: "FA6400")
    static let citrine = Color(hex: "F7B500")
    static let emerald = Color(hex: "6DD400")
    static let amazonite = Color(hex: "44D7B6")
    static let apatite = Color(hex: "32C5FF")
    static let saphire = Color(hex: "0091FF")
    static let lolite = Color(hex: "6236FF")
    static let amethyst = Color(hex: "B620E0")
    static let graphite = Color(hex: "6D7278")
    static let obsidian = Color(hex: "000000")
    
    static var workoutColors: [Color] = {
        [.accentColor, .ruby, .amber, .citrine, .emerald, .amazonite, apatite, saphire, lolite, .amethyst, .graphite, .obsidian]
    }()
    
}

extension Color {

    init(hex: String) {
        let scanner = Scanner(string: hex)
        scanner.currentIndex = .init(utf16Offset: 0, in: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)

        let r = (rgbValue & 0xff0000) >> 16
        let g = (rgbValue & 0xff00) >> 8
        let b = rgbValue & 0xff

        self.init(
            red: Double(r) / 0xff,
            green: Double(g) / 0xff,
            blue: Double(b) / 0xff,
            opacity: 1
        )
    }

}

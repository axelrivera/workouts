//
//  WorkoutsTests.swift
//  WorkoutsTests
//
//  Created by Axel Rivera on 1/22/21.
//

import XCTest
import FitFileParser
import CoreLocation

class GarminFitTests: XCTestCase {
    private var cycling: WorkoutImport!

    override func setUpWithError() throws {
        let url = Bundle(for: GarminFitTests.self).url(forResource: "cycling_example.fit", withExtension: nil)!
        let fitFile = FitFile(file: url)!
        cycling = WorkoutImport(fit: fitFile)
    }

    override func tearDownWithError() throws {
        cycling = nil
    }

    func testGarminCyclingFile() throws {
        XCTAssertEqual(cycling.timestamp.dateValue, Cycling.timestamp)
        XCTAssertEqual(cycling.startDate, Cycling.startTime)
        XCTAssertEqual(cycling.totalElapsedTime.timeValue, Cycling.totalElapsedTime)
        XCTAssertEqual(cycling.totalTimerTime.timeValue, Cycling.totalTimerTime)
        
        let coordinate = cycling.startPosition.coordinateValue
        XCTAssertEqual(coordinate?.latitude, Cycling.startPositionLat)
        XCTAssertEqual(coordinate?.longitude, Cycling.startPositionLong)
        
        XCTAssertEqual(cycling.totalDistance.distanceValue, Cycling.totalDistance)
        XCTAssertEqual(cycling.avgSpeed.speedValue, Cycling.avgSpeed)
        XCTAssertEqual(cycling.maxSpeed.speedValue, Cycling.maxSpeed)
        
        XCTAssertEqual(cycling.avgHeartRate.heartRateValue, Cycling.avgHeartRate)
        XCTAssertEqual(cycling.maxHeartRate.heartRateValue, Cycling.maxHeartRate)
        
        XCTAssertEqual(cycling.avgCadence.cadenceValue, Cycling.avgCadence)
        XCTAssertEqual(cycling.maxCadence.cadenceValue, Cycling.maxCadence)
        
        XCTAssertEqual(cycling.avgTemperature.temperatureValue, Cycling.avgTemp)
        XCTAssertEqual(cycling.maxTemperature.temperatureValue, Cycling.maxTemp)
        
        // Intervals
        let intervals = cycling.intervals
        
        var startDates = [Date]()
        var endDates = [Date]()
        var distances = [Double]()
        var heartRates = [Double]()
        var calories = [Double]()
        
        for interval in intervals {
            if let start = interval.startDate { startDates.append(start) }
            if let end = interval.endDate { endDates.append(end) }
            if let distance = interval.distance { distances.append(distance) }
            if let heartRate = interval.energyBurned { heartRates.append(heartRate) }
            if let energyBurned = interval.energyBurned { calories.append(energyBurned) }
        }
        
        XCTAssertFalse(startDates.isEmpty)
        XCTAssertFalse(endDates.isEmpty)
        XCTAssertFalse(distances.isEmpty)
        XCTAssertFalse(heartRates.isEmpty)
        XCTAssertFalse(calories.isEmpty)
    }

}

private extension GarminFitTests {
    
    struct Cycling {
        // Time
        static let timestamp = GarminDate(for: 979075230)
        static let startTime = GarminDate(for: 979073076)
        static let totalElapsedTime: Double = 2142.629
        static let totalTimerTime: Double = 2071.631
        
        // Location
        static let startPositionLat: Double = SemicircleToDegree(340925137)
        static let startPositionLong: Double = SemicircleToDegree(-970272087)
        
        // Distance & Speed
        static let totalDistance: Double = 12800.65
        static let avgSpeed: Double = 6.179
        static let maxSpeed: Double = 8.827
        
        static let avgHeartRate: Double = 140.0
        static let maxHeartRate: Double = 152.0
        
        static let avgCadence: Double = 70.0
        static let maxCadence: Double = 90.0
        
        static let avgTemp: Double = 18.0
        static let maxTemp: Double = 19.0
    }
    
}

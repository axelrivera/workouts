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
        // Main Values
        XCTAssertEqual(cycling.timestamp.dateValue, Cycling.timestamp)
        XCTAssertEqual(cycling.startDate, Cycling.startTime)
        XCTAssertEqual(cycling.totalElapsedTime.timeValue, Cycling.totalElapsedTime)
        XCTAssertEqual(cycling.totalTimerTime.timeValue, Cycling.totalTimerTime)
        
        let coordinate = cycling.startPosition.coordinateValue!
        XCTAssertEqual(coordinate.latitude, Cycling.startPositionLat)
        XCTAssertEqual(coordinate.longitude, Cycling.startPositionLong)
        
        XCTAssertEqual(cycling.totalDistance.distanceValue, Cycling.totalDistance)
        XCTAssertEqual(cycling.avgSpeed.speedValue, Cycling.avgSpeed)
        XCTAssertEqual(cycling.maxSpeed.speedValue, Cycling.maxSpeed)
        
        XCTAssertEqual(cycling.avgHeartRate.heartRateValue, Cycling.avgHeartRate)
        XCTAssertEqual(cycling.maxHeartRate.heartRateValue, Cycling.maxHeartRate)
        
        XCTAssertEqual(cycling.totalAvgCadence.cadenceValue, Cycling.avgCadence + Cycling.avgFractionalCadence)
        XCTAssertEqual(cycling.totalMaxCadence.cadenceValue, Cycling.maxCadence + Cycling.maxFractionalCadence)
        
        XCTAssertEqual(cycling.avgTemperature.temperatureValue, Cycling.avgTemp)
        XCTAssertEqual(cycling.maxTemperature.temperatureValue, Cycling.maxTemp)
        
        XCTAssertEqual(cycling.records.count, Cycling.totalRecords)
        XCTAssertEqual(cycling.locations.count, Cycling.totalLocations)
        
        // Single Record
        let record = cycling.records.first(where: { $0.timestamp.dateValue == Record.timestamp })!
        
        XCTAssertEqual(record.timestamp.dateValue, Record.timestamp)
        
        let recordCoordinate = record.position.coordinateValue!
        XCTAssertEqual(recordCoordinate.latitude, Record.positionLat)
        XCTAssertEqual(recordCoordinate.longitude, Record.positionLong)
        
        let altitude = Double(floor(10000 * record.altitude.altitudeValue!) / 10000)
        XCTAssertEqual(altitude, Record.altitude)
        XCTAssertEqual(record.distance.distanceValue, Record.distance)
        XCTAssertEqual(record.speed.speedValue, Record.speed)
        XCTAssertEqual(record.heartRate.heartRateValue, Record.heartRate)
        XCTAssertEqual(record.totalCadence.cadenceValue, Record.cadence + Record.fractionalCadence)
        XCTAssertEqual(record.temperature.temperatureValue, Record.temperature)
    }

}

private extension GarminFitTests {
    
    struct Cycling {
        static let sport = Sport.cycling
        static let indoor = false

        static let totalRecords = 2075
        static let totalLocations = 2070
        
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
        static let avgFractionalCadence: Double = 0.859375
        
        static let maxCadence: Double = 90.0
        static let maxFractionalCadence: Double = 0.0
        
        static let avgTemp: Double = 18.0
        static let maxTemp: Double = 19.0
    }
    
    struct Record {
        static let timestamp = GarminDate(for: 979073094)
        static let positionLat: Double = SemicircleToDegree(340926889)
        static let positionLong: Double = SemicircleToDegree(-970272231)
        static let altitude: Double = 87.2000
        static let distance: Double = 16.41
        static let speed: Double = 2.799
        static let heartRate: Double = 108.0
        static let cadence: Double = 23.0
        static let fractionalCadence: Double = 0.0
        static let temperature: Double = 19.0
        
    }
    
}

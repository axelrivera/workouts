//
//  WorkoutImport+Sample.swift
//  Workouts
//
//  Created by Axel Rivera on 7/4/22.
//

import Foundation
import HealthKit

extension WorkoutImport {
    
    struct Sample {
        static let CHUNK_COUNT: Int = 2
        
        let start: Date
        let end: Date
        let distance: Double
        let heartRate: Double?
        let calories: Double?
        let cyclingCadence: Double?
        let temperature: Double?
    }
    
    func samples() -> [Sample] {
        let samples = normalizedSamples()
        let chunked = samples.chunked(into: Sample.CHUNK_COUNT)
        
        var resultSamples: [Sample] = chunked.compactMap { chunk in
            guard chunk.count == Sample.CHUNK_COUNT else { return nil }
            return sample(forChunk: Array(chunk))
        }
        
        let totalSamples = Double(samples.count)
        let reminder = totalSamples.truncatingRemainder(dividingBy: Double(Sample.CHUNK_COUNT))
        if let lastSample = resultSamples.last, reminder > 0 {
            let nextChunk = Array(samples.suffix(Int(reminder)))
            if let nextSample = sample(forChunk: nextChunk), nextSample.start > lastSample.end {
                resultSamples.append(nextSample)
            }
        }
        
        return resultSamples
    }
    
    private func sample(forChunk chunk: [Sample]) -> Sample? {
        guard let start = chunk.first?.start else { return nil }
        guard let end = chunk.last?.start else { return nil }
        
        let distanceValues = chunk.map({ $0.distance })
        let heartRateValues = chunk.compactMap({ $0.heartRate })
        let calorieValues = chunk.compactMap({ $0.calories })
        let cyclingCadenceValues = chunk.compactMap({ $0.cyclingCadence })
        let temperatureValues = chunk.compactMap({ $0.temperature })
        
        let distance = distanceValues.reduce(0, +)
        let heartRate = heartRateValues.max()
        let cyclingCadence = cyclingCadenceValues.max()
        let temperature = temperatureValues.max()
        
        var calories: Double?
        if calorieValues.isPresent {
            calories = calorieValues.reduce(0, +)
        }
        
        let sample = Sample(
            start: start,
            end: end,
            distance: distance,
            heartRate: heartRate,
            calories: calories,
            cyclingCadence: cyclingCadence,
            temperature: temperature
        )
                
        return sample
    }
    
    func normalizedSamples() -> [Sample] {
        var samples = [Sample]()
                
        for (prevRecord, record) in zip(records, records.dropFirst()) {
            let distance = distanceSample(prevRecord: prevRecord, record: record)
            let cadence = record.totalCadence.cadenceValue
            let temperature = record.temperature.temperatureValue
            let heartRate = record.heartRate.heartRateValue
            let calories = energySample(prevRecord: prevRecord, record: record)
            
            let sample = Sample(
                start: record.date,
                end: record.date,
                distance: distance,
                heartRate: heartRate,
                calories: calories,
                cyclingCadence: cadence,
                temperature: temperature
            )
            
            samples.append(sample)
        }
        
        return samples
    }
    
    func distanceSample(prevRecord: Record, record: Record) -> Double {
        guard let start = prevRecord.distance.distanceValue else { return 0 }
        guard let end = record.distance.distanceValue else { return 0 }
        return end - start
    }
    
    func energySample(prevRecord: Record, record: Record) -> Double {
        guard let start = prevRecord.calories.caloriesValue else { return 0 }
        guard let end = record.calories.caloriesValue else { return 0 }
        return end - start
    }
}

extension WorkoutImport.Sample: CustomStringConvertible {
    
    var description: String {
        let values = [
            "start", start.timeIntervalSince1970.formatted(),
            "end", end.timeIntervalSince1970.formatted(),
            "distance", distance.formatted(),
            "heartRate", heartRate?.formatted() ?? "n/a",
            "calories", calories?.formatted() ?? "n/a",
            "cyclingCadence", cyclingCadence?.formatted() ?? "n/a",
            "temperature", temperature?.formatted() ?? "n/a"
        ]
        return values.joined(separator: ", ")
    }
}

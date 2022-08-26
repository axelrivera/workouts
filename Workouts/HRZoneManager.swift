//
//  HRZoneManager.swift
//  Workouts
//
//  Created by Axel Rivera on 6/25/21.
//

import CoreData
import HealthKit

typealias HRZoneManagerAction = (_ maxHeartRate: Int, _ values: [Int]) -> Void

class HRZoneManager: ObservableObject {
    @Published var values: [Int] = []
    
    private(set) var calculator: HRZonesCalculator = HRZonesCalculator(maxHeartRate: 0, values: [])
    let provider: HealthProvider = HealthProvider.shared
}

extension HRZoneManager {
    
    // NOTE: calculator should be updated before values variable
    // Since values is publishable that's what triggers the redraw
    // If you change values first, values on screen might not update
    
    func load() {
        let maxHeartRate = provider.maxHeartRate()
        let values = provider.heartRateZones()
        
        DispatchQueue.main.async {
            self.calculator = HRZonesCalculator(maxHeartRate: maxHeartRate, values: values)
            self.values = values
        }
    }
    
    var maxHeartRateString: String {
        formattedHeartRateString(for: Double(calculator.maxHeartRate))
    }
    
    func autoCalculate() {
        let newValues = calculator.defaultValues()
        calculator.updateValues(newValues)
        
        Log.debug("CALCULATE: values - \(values), percents: \(calculator.percentValues)")
        
        DispatchQueue.main.async {
            self.values = newValues
        }
    }
        
    func incrementZone(_ zone: HRZone) {
        calculator.incrementZone(zone)
        let newValues = calculator.values
        
        DispatchQueue.main.async {
            self.values = newValues
        }
    }
    
    func decrementZone(_ zone: HRZone) {
        calculator.decrementZone(zone)
        let newValues = calculator.values
        
        DispatchQueue.main.async {
            self.values = newValues
        }
    }
    
}

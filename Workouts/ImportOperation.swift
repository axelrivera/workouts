//
//  ImportOperation.swift
//  Workouts
//
//  Created by Axel Rivera on 2/1/21.
//

import Foundation

class ImportOperation: Operation {
    
    var workout: WorkoutImport
    
    private var _executing = false
    private var _finished = false
    
    init(workout: WorkoutImport) {
        self.workout = workout
        super.init()
    }
    
    override var isExecuting: Bool { return _executing }
    override var isFinished: Bool { return _finished }
    
    override func cancel() {
        if isCancelled {
            finish()
            return
        }
    }
    
    override func start() {
        if isCancelled {
            finish()
            return
        }
        
        willChangeValue(forKey: "isExecuting")
        _executing = true
        didChangeValue(forKey: "isExecuting")
        
        DispatchQueue.main.async {
            self.workout.status = .processing
        }
        
        WorkoutDataStore.saveWorkoutImport(workout) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.workout.status = .processed
                case .failure:
                    self.workout.status = .failed
                }
                                    
                self.finish()
            }
        }
    }
    
    func finish() {
        willChangeValue(forKey: "isExecuting")
        willChangeValue(forKey: "isFinished")
        _executing = false
        _finished = true
        didChangeValue(forKey: "isExecuting")
        didChangeValue(forKey: "isFinished")
    }
    
    override func main() {
        if isCancelled && !isFinished {
            finish()
            return
        }
    }
    
}

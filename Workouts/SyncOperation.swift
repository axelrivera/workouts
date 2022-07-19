//
//  DetailOperation.swift
//  Workouts
//
//  Created by Axel Rivera on 3/19/21.
//

import Foundation

class SyncOperation: Operation {
        
    private var _executing = false
    private var _finished = false
    
    override var isExecuting: Bool { return _executing }
    override var isFinished: Bool { return _finished }
    
    override func cancel() {
        if isCancelled {
            finish()
            return
        }
    }
    
    /*
        ## Notes:
        * Subclasses must always call super.start() first
        * Subclasses must call finish() at some point during start() method
     */
    
    override func start() {
        if isCancelled {
            finish()
            return
        }
        
        willChangeValue(forKey: "isExecuting")
        _executing = true
        didChangeValue(forKey: "isExecuting")
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
    
    // Subclassed must implement process to do any needed logic
    
    func process() async {
        fatalError("implement in subclass")
    }
    
}

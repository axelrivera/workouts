//
//  Log.swift
//  Workouts
//
//  Created by Axel Rivera on 1/20/21.
//

import Foundation
import os

class Log {
    private static let logger = Logger()
    
    private init() {
        fatalError("dont init this structure")
    }
    
    static func debug(_ message: String, filename: String = #file, function: String = #function, line: Int = #line) {
        let url = URL(fileURLWithPath: filename)
        logger.debug("[\(url.lastPathComponent):\(line)] \(function) - \(message)")
    }
    
    static func info(_ message: String) {
        logger.info("\(message)")
    }
    
}

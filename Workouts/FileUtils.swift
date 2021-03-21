//
//  FileUtils.swift
//  Workouts
//
//  Created by Axel Rivera on 3/21/21.
//

import Foundation

struct FileUtils {
    enum Directories {
        static let workoutImports = "imports"
    }
    
    init() {
        fatalError("dont init this struct")
    }
    
    static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    static var temporaryDirectory: URL {
        URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    }
    
    static var workoutImportDirectory: URL {
        documentsDirectory.appendingPathComponent(Directories.workoutImports, isDirectory: true)
    }
    
}

//
//  UTType+Additions.swift
//  Workouts
//
//  Created by Axel Rivera on 1/15/21.
//

import UniformTypeIdentifiers
import CoreServices
import UIKit
import FitFileParser

extension UTType {
    static var fitDocument: UTType {
        UTType(importedAs: "me.axelrivera.Workouts.fit")
    }
}

class FitDocument: UIDocument {
    
    var fitFile: FitFile?
   
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        if let data = contents as? Data {
            fitFile = FitFile(data: data)
        }
    }
    
}

//
//  UTType+Additions.swift
//  Workouts
//
//  Created by Axel Rivera on 1/15/21.
//

import UniformTypeIdentifiers
import CoreServices

extension UTType {
    static var fitDocument: UTType {
        UTType(importedAs: "me.axelrivera.Workouts.fit")
    }
}

extension URL {
    
    var isZipFile: Bool {
        guard let resourceValues = try? self.resourceValues(forKeys: [URLResourceKey.typeIdentifierKey]),
              let typeID = resourceValues.typeIdentifier else { return false }
        return UTType(typeID) == UTType.zip
    }
    
}

//
//  Dictionary+RawRepresentable.swift
//  Workouts
//
//  Created by Axel Rivera on 7/16/22.
//

import Foundation

extension Dictionary where Key: RawRepresentable, Key.RawValue == String, Value: Any {
    
    var rawValuesDictionary: [String: Value] {
        var result: [String: Value] = [:]
        for key in keys {
            result[key.rawValue] = self[key]
        }
        return result
    }
    
}

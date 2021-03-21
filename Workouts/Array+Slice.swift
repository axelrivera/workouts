//
//  Array+Slice.swift
//  Workouts
//
//  Created by Axel Rivera on 3/10/21.
//

import Foundation

extension Array {
    
    
    func slicedInSeconds(_ seconds: Int, key: KeyPath<Element, Date>) -> [Date: [Element]] {
        var dictionary: [Date: [Element]] = [:]
        guard let first = self.first else { return dictionary }
        
        let secondsInterval = Double(seconds)
        let start = first[keyPath: key].timeIntervalSince1970
        var nextInterval = start + secondsInterval
        
        var group = [Element]()
        
        for element in self {
            let interval = element[keyPath: key].timeIntervalSince1970
            
            if interval <= nextInterval {
                group.append(element)
            } else {
                dictionary[Date(timeIntervalSince1970: nextInterval)] = group
                group = [Element]()
                group.append(element)
                nextInterval = nextInterval + secondsInterval
            }
        }
        return dictionary
    }
    
}

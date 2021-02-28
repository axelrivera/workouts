//
//  Array+Chunked.swift
//  Workouts
//
//  Created by Axel Rivera on 2/27/21.
//

import Foundation

extension Array {
    
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
    
}

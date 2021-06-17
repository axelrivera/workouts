//
//  String+Additions.swift
//  Workouts
//
//  Created by Axel Rivera on 3/19/21.
//

import Foundation

extension Collection {
    
    var isPresent: Bool {
        !self.isEmpty
    }
    
}

extension String {
    
    func removingCharacters(in set: CharacterSet) -> String {
        var chars = self
        for idx in chars.indices.reversed() {
            if set.contains(String(chars[idx]).unicodeScalars.first!) {
                chars.remove(at: idx)
            }
        }
        return String(chars)
    }
    
}

extension StringProtocol {
    var firstUppercased: String { prefix(1).uppercased() + dropFirst() }
    var firstCapitalized: String { prefix(1).capitalized + dropFirst() }
}

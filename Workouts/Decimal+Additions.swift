//
//  Decimal+Additions.swift
//  Workouts
//
//  Created by Axel Rivera on 8/5/22.
//

import Foundation

extension Decimal {

    var doubleValue: Double {
        NSDecimalNumber(decimal: self).doubleValue
    }

    var intValue: Int {
        NSDecimalNumber(decimal: self).intValue
    }

}

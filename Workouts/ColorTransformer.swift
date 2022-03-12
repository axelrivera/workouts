//
//  ColorTransformer.swift
//  Workouts
//
//  Created by Axel Rivera on 10/29/21.
//

import UIKit

@objc(ColorTransformer)
class ColorTransformer: NSSecureUnarchiveFromDataTransformer {
    public static let transformerName = NSValueTransformerName(rawValue: "ColorTransformer")
    override class var allowedTopLevelClasses: [AnyClass] {
        return [UIColor.self]
    }
}

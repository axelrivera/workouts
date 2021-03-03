//
//  WorkoutAnnotation.swift
//  Workouts
//
//  Created by Axel Rivera on 3/3/21.
//

import MapKit

class WorkoutAnnotation: NSObject, MKAnnotation {
    enum AnnotationType {
        case start, end
    }
    
    var annotationType: AnnotationType
    var title: String?
    var coordinate: CLLocationCoordinate2D
    
    init(annotationType: AnnotationType, coordinate: CLLocationCoordinate2D) {
        self.annotationType = annotationType
        self.coordinate = coordinate
        super.init()
    }
    
    var color: UIColor {
        switch annotationType {
        case .start:
            return .systemGreen
        case .end:
            return .systemRed
        }
    }
}

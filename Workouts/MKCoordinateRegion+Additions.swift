//
//  MKCoordinateRegion+Additions.swift
//  Workouts
//
//  Created by Axel Rivera on 1/28/21.
//

import MapKit

extension MKCoordinateRegion {
    
    init?(coordinates: [CLLocationCoordinate2D]) {
        if coordinates.isEmpty { return nil }
        
        var minLat: CLLocationDegrees = 90.0
        var maxLat: CLLocationDegrees = -90.0
        var minLon: CLLocationDegrees = 180.0
        var maxLon: CLLocationDegrees = -180.0
        
        for coordinate in coordinates {
            guard CLLocationCoordinate2DIsValid(coordinate) else { continue }
            
            let lat = Double(coordinate.latitude)
            let long = Double(coordinate.longitude)
            if lat < minLat {
                minLat = lat
            }
            if long < minLon {
                minLon = long
            }
            if lat > maxLat {
                maxLat = lat
            }
            if long > maxLon {
                maxLon = long
            }
        }
        
        let spanFactor = 1.1
        let centerFactor = spanFactor * 2.0
        
        let span = MKCoordinateSpan(latitudeDelta: (maxLat - minLat) * spanFactor, longitudeDelta: (maxLon - minLon) * spanFactor)
        let center = CLLocationCoordinate2DMake(maxLat - span.latitudeDelta / centerFactor, maxLon - span.longitudeDelta / centerFactor)
        
        guard CLLocationCoordinate2DIsValid(center) else { return nil }
        
        self.init(center: center, span: span)
    }
    
}

extension MKMapRect {
    
    static func rectForCoordinates(_ coordinates: [CLLocationCoordinate2D]) -> MKMapRect {
        var zoomRect = MKMapRect.null
        for coordinate in coordinates {
            guard CLLocationCoordinate2DIsValid(coordinate) else { continue }
            
            let mapPoint = MKMapPoint(coordinate)
            let pointRect = MKMapRect(x: mapPoint.x, y: mapPoint.y, width: 0.1, height: 0.1)
            zoomRect = zoomRect.union(pointRect)
        }
        return zoomRect
    }
    
}

extension MKCoordinateRegion{
    
    var mapRect: MKMapRect {
        get{
            let a = MKMapPoint.init(CLLocationCoordinate2DMake(
                   self.center.latitude + self.span.latitudeDelta / 2,
                   self.center.longitude - self.span.longitudeDelta / 2)
            )

            let b = MKMapPoint.init(CLLocationCoordinate2DMake(
                    self.center.latitude - self.span.latitudeDelta / 2,
                    self.center.longitude + self.span.longitudeDelta / 2)
            )
            
            return MKMapRect.init(x: min(a.x, b.x), y: min(a.y, b.y), width: abs(a.x - b.x), height: abs(a.y - b.y))
        }
    }
    
}

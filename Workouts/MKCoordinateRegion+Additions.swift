//
//  MKCoordinateRegion+Additions.swift
//  Workouts
//
//  Created by Axel Rivera on 1/28/21.
//

import MapKit

fileprivate let MIN_LAT: CLLocationDegrees = 90
fileprivate let MAX_LAT: CLLocationDegrees = -90
fileprivate let MIN_LON: CLLocationDegrees = 180
fileprivate let MAX_LON: CLLocationDegrees = -180

fileprivate let COORDINATE_LIMITS: (minLat: Double, maxLat: Double, minLong: Double, maxLong: Double) = (90, -90, 180, -180)

extension MKCoordinateRegion {
    typealias RegionLimits = (minLat: CLLocationDegrees, maxLat: CLLocationDegrees, minLon: CLLocationDegrees, maxLong: CLLocationDegrees)
    
    static func regionLimitsForCoordinates(_ coordinates: [CLLocationCoordinate2D]) -> RegionLimits? {
        if coordinates.isEmpty { return nil }
                
        var minLat = MIN_LAT
        var maxLat = MAX_LAT
        var minLon = MIN_LON
        var maxLon = MAX_LON
        
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
        return (minLat, maxLat, minLon, maxLon)
    }
    
    init?(coordinates: [CLLocationCoordinate2D]) {
        guard let limits = Self.regionLimitsForCoordinates(coordinates) else { return nil }
        let (minLat, maxLat, minLon, maxLon) = limits
        
        let spanFactor = 1.1
        let centerFactor = spanFactor * 2.0
        
        let span = MKCoordinateSpan(latitudeDelta: (maxLat - minLat) * spanFactor, longitudeDelta: (maxLon - minLon) * spanFactor)
        let center = CLLocationCoordinate2DMake(maxLat - span.latitudeDelta / centerFactor, maxLon - span.longitudeDelta / centerFactor)
        
        guard CLLocationCoordinate2DIsValid(center) else { return nil }
        self.init(center: center, span: span)
    }
    
    static func workoutShareRegion(for coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion? {
        guard let limits = Self.regionLimitsForCoordinates(coordinates) else { return nil }
        let (minLat, maxLat, minLon, maxLon) = limits
                
        let latFactor = 1.4
        let longFactor = 1.2
        
        let latCenterFactor = latFactor * 2.5
        let longCenterFactor = longFactor * 2.0
        
        let span = MKCoordinateSpan(latitudeDelta: (maxLat - minLat) * latFactor, longitudeDelta: (maxLon - minLon) * longFactor)
        
        let centerLat = maxLat - (span.latitudeDelta / latCenterFactor)
        let centerLong = maxLon - (span.longitudeDelta / longCenterFactor)
        let center = CLLocationCoordinate2DMake(centerLat, centerLong)
        
        guard CLLocationCoordinate2DIsValid(center) else { return nil }
        return MKCoordinateRegion(center: center, span: span)
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

extension MKCoordinateRegion {

    var mapRect: MKMapRect {
        get {
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

//
//  MKMapView+Additions.swift
//  MKMapView+Additions
//
//  Created by Axel Rivera on 8/30/21.
//

import MapKit
import SwiftUI

extension MKMapView {
    
    class func workoutMapImage(coordinates: [CLLocationCoordinate2D], colorScheme: ColorScheme) async throws -> UIImage? {
        let data = try await workoutMapData(coordinates: coordinates, colorScheme: colorScheme)
        return UIImage(data: data)
    }
    
    class func workoutMapData(coordinates: [CLLocationCoordinate2D], colorScheme: ColorScheme) async throws -> Data {
        return try await mapImageData(
            coordinates: coordinates,
            size: Constants.cachedWorkoutImageSize,
            colorScheme: colorScheme
        )
    }
    
    class func mapImageData(
        coordinates: [CLLocationCoordinate2D],
        size: CGSize,
        colorScheme: ColorScheme,
        linneColor: Color = .accentColor,
        lineWidth: Double = 5.0) async throws ->  Data
    {
            
        let region: MKCoordinateRegion
        if let _region = MKCoordinateRegion(coordinates: coordinates) {
            region = _region
        } else {
            region = MKCoordinateRegion(.world)
        }
                    
        let userInterfaceStyle: UIUserInterfaceStyle = UIUserInterfaceStyle(colorScheme)
        let colorSchemeCollection = UITraitCollection(userInterfaceStyle: userInterfaceStyle)
        
        let options = MKMapSnapshotter.Options()
        options.size = size
        options.scale = UIScreen.main.scale
        options.region = region
        options.traitCollection = UITraitCollection(traitsFrom: [colorSchemeCollection])
        options.showsBuildings = false
        
        let snapshotter = MKMapSnapshotter(options: options)
        let snapshot = try await snapshotter.start()
        
        let image = snapshot.image
        let data = UIGraphicsImageRenderer(size: image.size).jpegData(withCompressionQuality: 0.9) { context in
            image.draw(at: .zero)
            
            if coordinates.isPresent {
                let points = coordinates.map { snapshot.point(for: $0) }

                let path = UIBezierPath()
                path.move(to: points[0])

                for point in points.dropFirst() {
                    path.addLine(to: point)
                }

                // stroke it

                path.lineCapStyle = .round
                path.lineJoinStyle = .round
                path.flatness = 0
                path.lineWidth = lineWidth
                UIColor(.accentColor).setStroke()
                path.stroke()
            }
        }
        
        return data
    }
    
    class func mapImage(coordinates: [CLLocationCoordinate2D], size: CGSize, completionHandler: @escaping (_ image: UIImage?) -> Void) {
        if coordinates.isEmpty {
            completionHandler(nil)
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            guard let region = MKCoordinateRegion(coordinates: coordinates) else {
                DispatchQueue.main.async {
                    completionHandler(nil)
                }
                return
            }
            
            let options = MKMapSnapshotter.Options()
            options.size = size
            options.scale = UIScreen.main.scale
            options.region = region
            options.showsBuildings = false

            MKMapSnapshotter(options: options).start { snapshot, error in
                guard let snapshot = snapshot else { return }

                let mapImage = snapshot.image
                let finalImage = UIGraphicsImageRenderer(size: mapImage.size).image { _ in
                    mapImage.draw(at: .zero)

                    if coordinates.isEmpty { return }

                    let points = coordinates.map { snapshot.point(for: $0) }

                    let path = UIBezierPath()
                    path.move(to: points[0])

                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }

                    // stroke it

                    path.lineWidth = 4.0
                    UIColor(.accentColor).setStroke()
                    path.stroke()
                }
                
                DispatchQueue.main.async {
                    completionHandler(finalImage)
                }
            }
        }
    }
    
}

//
//  MKMapView+Additions.swift
//  MKMapView+Additions
//
//  Created by Axel Rivera on 8/30/21.
//

import MapKit
import SwiftUI

extension MKMapView {
    
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

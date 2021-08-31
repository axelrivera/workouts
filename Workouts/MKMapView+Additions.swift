//
//  MKMapView+Additions.swift
//  MKMapView+Additions
//
//  Created by Axel Rivera on 8/30/21.
//

import MapKit

extension MKMapView {
    
    class func routeMapOutline(coordinates: [CLLocationCoordinate2D], size: CGSize? = nil, completionHandler: @escaping (_ image: UIImage?) -> Void) {
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
            
            let imageSize = size ?? CGSize(width: CGFloat(300), height: CGFloat(300))
            
            let options = MKMapSnapshotter.Options()
            options.region = region
            options.size = imageSize
            options.showsBuildings = false

            MKMapSnapshotter(options: options).start { snapshot, error in
                guard let snapshot = snapshot else {
                    DispatchQueue.main.async {
                        completionHandler(nil)
                    }
                    return
                }

                let mapImage = snapshot.image
                let finalImage = UIGraphicsImageRenderer(size: mapImage.size).image { _ in
                    let points = coordinates.map { snapshot.point(for: $0) }

                    let path = UIBezierPath()
                    path.move(to: points[0])

                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }

                    // stroke it

                    path.lineWidth = CGFloat(2.0)
                    UIColor(white: 1.0, alpha: 1.0).setStroke()
                    path.stroke()
                }
                
                DispatchQueue.main.async {
                    completionHandler(finalImage)
                }
            }
        }
    }
    
}

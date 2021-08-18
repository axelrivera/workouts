//
//  MapImage.swift
//  MapImage
//
//  Created by Axel Rivera on 8/16/21.
//

import SwiftUI
import MapKit

struct MapImage: UIViewRepresentable {
    var workoutIdentifier: UUID
    var coordinates: [CLLocationCoordinate2D]
    var imageSize: CGSize
    var cachePrefix: MapImageCache.Prefix
    var scheme: ColorScheme
}

extension MapImage {
    
    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .systemFill
        imageView.clipsToBounds = true
        
        return imageView
    }
    
    func updateUIView(_ imageView: UIImageView, context: Context) {
        if coordinates.isEmpty { return }
        
        let imageCache = MapImageCache.getImageCache()
        if let image = imageCache.get(forKey: workoutIdentifier.uuidString, prefix: cachePrefix, scheme: scheme) {
            UIView.transition(with: imageView,
                              duration: 0.25,
                              options: .transitionCrossDissolve,
                              animations: { imageView.image = image },
                              completion: nil)
        } else {
            let options = MKMapSnapshotter.Options()

            if let region = MKCoordinateRegion(coordinates: coordinates) {
                options.region = region
            } else {
                let center = CLLocationCoordinate2D.init(latitude: 37.33182, longitude: -122.03118) // apple headquarters
                options.region = MKCoordinateRegion(center: center, latitudinalMeters: 250.0, longitudinalMeters: 250.0)
            }

            options.size = imageSize
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

                    path.lineWidth = cachePrefix == .home ? 2.0 : 4.0
                    UIColor(.accentColor).setStroke()
                    path.stroke()
                }

                imageCache.set(forKey: workoutIdentifier.uuidString, image: finalImage, prefix: cachePrefix, scheme: scheme)

                UIView.transition(with: imageView,
                                  duration: 0.25,
                                  options: .transitionCrossDissolve,
                                  animations: { imageView.image = finalImage },
                                  completion: nil)
            }
        }
    }
    
}

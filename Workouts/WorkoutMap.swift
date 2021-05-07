//
//  WorkoutMap.swift
//  Workouts
//
//  Created by Axel Rivera on 1/28/21.
//

import SwiftUI
import MapKit

struct WorkoutMap: UIViewRepresentable {
    @Binding var points: [CLLocationCoordinate2D]
}

extension WorkoutMap {
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.layoutMargins = UIEdgeInsets(top: 20.0, left: 20.0, bottom: 20.0, right: 20.0)
        mapView.isZoomEnabled = false
        mapView.isScrollEnabled = false
        mapView.isUserInteractionEnabled = false
        mapView.delegate = context.coordinator
        
        return mapView
    }
    
    func updateUIView(_ view: MKMapView, context: Context) {
        if points.isEmpty { return }
        
        if !view.overlays.isEmpty {
            view.removeOverlays(view.overlays)
        }
        
        if !view.annotations.isEmpty {
            view.removeAnnotations(view.annotations)
        }
        
        var zoomRect = MKMapRect.null
        for coordinate in points {
            let mapPoint = MKMapPoint(coordinate)
            let pointRect = MKMapRect(x: mapPoint.x, y: mapPoint.y, width: 0.1, height: 0.1)
            zoomRect = zoomRect.union(pointRect)
        }
        
        let mapFrame = view.mapRectThatFits(zoomRect, edgePadding: .zero)
        view.setVisibleMapRect(mapFrame, animated: false)
                        
        let line = MKGeodesicPolyline(coordinates: points, count: points.count)
        view.addOverlay(line)
        
        if let coordinate = points.first {
            let start = WorkoutAnnotation(annotationType: .start, coordinate: coordinate)
            view.addAnnotation(start)
        }
        
        if let coordinate = points.last, points.count > 1 {
            let end = WorkoutAnnotation(annotationType: .end, coordinate: coordinate)
            view.addAnnotation(end)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
}

extension WorkoutMap {
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: WorkoutMap
        
        init(_ parent: WorkoutMap) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let annotation = annotation as? WorkoutAnnotation else { return nil }

            let identifier = "annotation"
            var annotationView: MKMarkerAnnotationView! = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView

            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView.titleVisibility = .hidden
            } else {
                annotationView.annotation = annotation
            }

            annotationView.markerTintColor = annotation.color

            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, didAdd renderers: [MKOverlayRenderer]) {
            
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = UIColor(.distance)
            renderer.lineWidth = 5.0
            return renderer
        }
    }
    
}

struct WorkoutMap_Previews: PreviewProvider {
    @State static var points = [CLLocationCoordinate2D]()
    
    static var previews: some View {
        WorkoutMap(points: $points)
    }
}

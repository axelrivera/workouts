//
//  WorkoutMap.swift
//  Workouts
//
//  Created by Axel Rivera on 1/28/21.
//

import SwiftUI
import MapKit

struct WorkoutMap: UIViewRepresentable {
    var points: [CLLocationCoordinate2D]
}

extension WorkoutMap {
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.layoutMargins = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
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
        
        let zoomRect = MKMapRect.rectForCoordinates(points)
        let mapFrame = view.mapRectThatFits(zoomRect, edgePadding: .zero)
        view.setVisibleMapRect(mapFrame, animated: false)
                        
        let line = MKGeodesicPolyline(coordinates: points, count: points.count)
        view.addOverlay(line)
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
            return nil
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
    static var points = [CLLocationCoordinate2D]()
    
    static var previews: some View {
        WorkoutMap(points: points)
    }
}

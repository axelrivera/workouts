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
        mapView.delegate = context.coordinator
        
        return mapView
    }
    
    func updateUIView(_ view: MKMapView, context: Context) {
        if points.isEmpty { return }
        
        if !view.overlays.isEmpty {
            view.removeOverlays(view.overlays)
        }
        
        var zoomRect = MKMapRect.null
        for coordinate in points {
            let mapPoint = MKMapPoint(coordinate)
            let pointRect = MKMapRect(x: mapPoint.x, y: mapPoint.y, width: 0.1, height: 0.1)
            zoomRect = zoomRect.union(pointRect)
        }
        
        view.setVisibleMapRect(view.mapRectThatFits(zoomRect, edgePadding: .init(top: 10, left: 10, bottom: 10, right: 10)), animated: false)
                        
        let line = MKGeodesicPolyline(coordinates: points, count: points.count)
        view.addOverlay(line)
        
        
//        if points.count == view.overlays.count { return }
        
//        for overlay in view.overlays {
//            if let line = overlay as? MKGeodesicPolyline {
//                view.removeOverlay(line)
//            }
//        }
        
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
        
//        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
//            return nil
//        }
        
        func mapView(_ mapView: MKMapView, didAdd renderers: [MKOverlayRenderer]) {
            
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = .blue
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

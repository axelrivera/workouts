//
//  DetailMapView.swift
//  Workouts
//
//  Created by Axel Rivera on 2/3/21.
//

import SwiftUI
import MapKit

struct DetailMapView: View {
    enum MapType: String, CaseIterable, Identifiable {
        case standard, satellite, hybrid
        
        var id: String { rawValue }
        
        init(systemType: MKMapType) {
            self = Self.mapType(for: systemType)
        }
        
        var title: String { rawValue.capitalized }
        
        var systemType: MKMapType {
            Self.systemType(for: self)
        }
        
        static func systemType(for mapType: MapType) -> MKMapType {
            switch mapType {
            case .standard:
                return .standard
            case .satellite:
                return .satellite
            case .hybrid:
                return .hybrid
            }
        }
        
        static func mapType(for systemType: MKMapType) -> MapType {
            switch systemType {
            case .satellite:
                return .satellite
            case .hybrid:
                return .hybrid
            default:
                return .standard
            }
        }
    }
    
    @Environment(\.presentationMode) var presentationMode
    
    var title: String
    var points: [CLLocationCoordinate2D]
    
    @State private var selectedMapType: MKMapType = .standard
    
    var body: some View {
        NavigationView {
            DetailMap(points: .constant(points), mapType: $selectedMapType)
                .ignoresSafeArea(.all, edges: [.bottom])
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", action: { presentationMode.wrappedValue.dismiss() })
                    }
                    
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            ForEach(MapType.allCases) { mapType in
                                Button(action: { selectedMapType = mapType.systemType }) {
                                    HStack {
                                        Text(mapType.title)
                                        
                                        if selectedMapType == mapType.systemType {
                                            Spacer()
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "map")
                        }
                    }
                }
        }
    }
}

struct DetailMapView_Previews: PreviewProvider {
    static var previews: some View {
        DetailMapView(title: "Map", points: [])
            .colorScheme(.dark)
    }
}

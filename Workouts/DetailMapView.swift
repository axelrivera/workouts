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
    @ObservedObject var workout: Workout
    @ObservedObject var detailManager: DetailManager
    
    @State var selectedMapType: MKMapType = .standard
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            DetailMap(points: $detailManager.points, mapType: $selectedMapType)
                .ignoresSafeArea()
            
            HStack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.red)
                        .frame(width: 28, height: 28)
                        .background(Circle().scale(1.3).fill(Color.primary))
                        .shadow(radius: 5.0)
                }
                
                Spacer()
                
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
                        .frame(width: 28.0, height: 28.0)
                        .background(Circle().scale(1.3).fill(Color.primary))
                        .shadow(radius: 5.0)
                }
            }
            .padding()
        }
    }
}

struct DetailMapView_Previews: PreviewProvider {
    static var previews: some View {
        DetailMapView(workout: Workout.sample, detailManager: DetailManager(workoutID: Workout.sample.id))
            .colorScheme(.dark)
    }
}

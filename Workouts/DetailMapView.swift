//
//  DetailMapView.swift
//  Workouts
//
//  Created by Axel Rivera on 2/3/21.
//

import SwiftUI
import MapKit

struct DetailMapView: View {
    let mapTypes: [MKMapType] = [.standard, .satellite, .hybrid]
    let mapTitles: [String] = ["Standard", "Satellite", "Hybrid"]
    
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var workout: Workout
    @ObservedObject var detailManager: DetailManager
    
    @State var selectedMapTitle: Int = 0
    @State var selectedMapType: MKMapType = .standard
    
    var body: some View {
        NavigationView {
            ZStack {
                DetailMap(points: $detailManager.points, mapType: $selectedMapType)
                    .ignoresSafeArea()
                
                VStack {
                    Picker(selection: $selectedMapTitle, label: Text("Workout Map")) {
                        ForEach(0 ..< mapTypes.count) { index in
                            Text(mapTitles[index])
                        }
                    }
                    .onChange(of: selectedMapTitle) { selectedMapType = mapTypes[$0] }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    Spacer()
                }
            }
            .navigationBarTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Text("Done")
                    }
                }
            }
        }
    }
}

struct DetailMapView_Previews: PreviewProvider {
    static var previews: some View {
        DetailMapView(workout: Workout.sample, detailManager: DetailManager())
    }
}

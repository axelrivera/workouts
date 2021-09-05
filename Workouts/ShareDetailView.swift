//
//  ShareDetailView.swift
//  ShareDetailView
//
//  Created by Axel Rivera on 8/31/21.
//

import SwiftUI

struct ShareDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @Binding var color: Color
    @Binding var showLocation: Bool
    @Binding var showRoute: Bool
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Background Color")) {
                    WorkoutColorPicker(selectedColor: $color) { newColor in
                        Log.debug("selected color: \(newColor)")
                    }
                    .padding([.top, .bottom])
                }
                
                Section {
                    Toggle("Show Location", isOn: $showLocation)
                    Toggle("Show Route Outline", isOn: $showRoute)
                }
            }
            .navigationTitle("Share Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done", action: { presentationMode.wrappedValue.dismiss() })
                }
            }
        }
    }
}

struct ShareDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ShareDetailView(color: .constant(.red), showLocation: .constant(false), showRoute: .constant(false))
    }
}

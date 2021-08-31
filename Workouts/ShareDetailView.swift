//
//  ShareDetailView.swift
//  ShareDetailView
//
//  Created by Axel Rivera on 8/31/21.
//

import SwiftUI

struct ShareDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @Binding var showLocation: Bool
    @Binding var showRoute: Bool
    
    var body: some View {
        NavigationView {
            Form {
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
        ShareDetailView(showLocation: .constant(false), showRoute: .constant(false))
    }
}

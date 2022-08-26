//
//  HUDView.swift
//  Workouts
//
//  Created by Axel Rivera on 11/28/21.
//

import SwiftUI

struct HUDView: View {
    var body: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle())
            .padding()
            .background(Material.regularMaterial)
            .cornerRadius(12.0)
            .scaleEffect(x: 1.5, y: 1.5, anchor: .center)
    }
}

struct HUDView_Previews: PreviewProvider {
    static var previews: some View {
        HUDView()
            .preferredColorScheme(.dark)
    }
}

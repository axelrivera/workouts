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
            .scaleEffect(x: 2.0, y: 2.0, anchor: .center)
            .padding()
            .frame(width: 100.0, height: 100, alignment: .center)
            .background(Material.regularMaterial)
            .cornerRadius(12.0)
    }
}

struct HUDView_Previews: PreviewProvider {
    static var previews: some View {
        HUDView()
    }
}

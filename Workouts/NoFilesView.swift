//
//  NoFilesView.swift
//  Workouts
//
//  Created by Axel Rivera on 2/7/21.
//

import SwiftUI

struct NoFilesView: View {
    var body: some View {
        VStack(alignment: .center, spacing: 20.0) {
            Image(systemName: "icloud.and.arrow.down")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100, alignment: .center)
            Text("Tap the + icon to import one or more workouts from iCloud. Only FIT files are supported.")
                .multilineTextAlignment(.center)
                .padding()
        }
        .foregroundColor(.secondary)
    }
}

struct NoFilesView_Previews: PreviewProvider {
    static var previews: some View {
        NoFilesView()
    }
}

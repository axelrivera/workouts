//
//  WriteUnauthorizedView.swift
//  Workouts
//
//  Created by Axel Rivera on 2/7/21.
//

import SwiftUI

struct WriteDeniedView: View {
    var body: some View {
        VStack(spacing: 20.0) {
            Image(systemName: "heart.slash.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100, alignment: .center)
                .foregroundColor(.red)
            Text(
                NSLocalizedString(
                    "Health data is not available on this device or writing permission is disabled. To enable writing permissions open the Health app. Then go to Profile, Apps, and select the Better Workouts icon.",
                    comment: "Workout write denied message"
                )
            )
            .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct WriteUnauthorizedView_Previews: PreviewProvider {
    static var previews: some View {
        WriteDeniedView()
    }
}

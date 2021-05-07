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
            Text("Writing permission for workouts is disabled. Open the Health app and go to to Profile, Apps, Workouts to enable write permissions.")
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

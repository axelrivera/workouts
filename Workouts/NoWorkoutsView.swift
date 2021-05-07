//
//  NoWorkoutsView.swift
//  Workouts
//
//  Created by Axel Rivera on 2/7/21.
//

import SwiftUI

struct NoWorkoutsView: View {
    var body: some View {
        VStack(alignment: .center, spacing: 20.0) {
            Text("No Workouts")
                .font(.title)
                .foregroundColor(.secondary)
            Image(systemName: "exclamationmark.triangle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100, alignment: .center)
                .foregroundColor(.red)
            Text("There are no workouts available or reading permissions are disabled. Open the Health app and go to to Profile, Apps, Workouts to enable reading permissions.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.bottom)
        }
        .padding()
    }
}

struct NoWorkoutsView_Previews: PreviewProvider {
    static var previews: some View {
        NoWorkoutsView()
    }
}

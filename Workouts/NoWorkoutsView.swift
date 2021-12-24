//
//  NoWorkoutsView.swift
//  Workouts
//
//  Created by Axel Rivera on 2/7/21.
//

import SwiftUI

struct NoWorkoutsView: View {
    var body: some View {
        VStack(alignment: .center, spacing: 5.0) {
            HStack(spacing: 5.0) {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.red)

                Text("No Workouts")
                    .font(.body)
                    .foregroundColor(.red)
            }
            Text("There are no workouts available on Apple Health or reading permissions are disabled. Open the Health app and go to to Profile, Apps, Workouts to enable reading permissions.")
                .font(.footnote)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
        }
        .padding([.top, .bottom], CGFloat(10.0))
        .frame(maxWidth: .infinity)
        .background(Color.yellow.opacity(0.5))
        .background(.regularMaterial)
    }
}

struct ProcessingLocationView: View {
    
    var body: some View {
        VStack(spacing: 5.0) {
            HStack(spacing: 10.0) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                Text("Processing Location Data")
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            Text("Some data may be missing while processing")
                .font(.footnote)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding([.top, .bottom], CGFloat(10.0))
        .frame(maxWidth: .infinity)
        .background(Color.red.opacity(0.5))
        .background(.regularMaterial)
    }
    
}

struct NoWorkoutsView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            NoWorkoutsView()
            ProcessingLocationView()
        }
    }
}

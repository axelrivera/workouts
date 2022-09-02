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
            Image(systemName: "heart.slash.fill")
                .font(.largeTitle)
                .foregroundColor(.red)
            
            Text(NSLocalizedString("There are no workouts available on Apple Health or reading permissions are disabled. Open the Health app and go to to Profile, Apps, Workouts to enable reading permissions.", comment: "Text"))
                .font(.footnote)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
        .padding([.top, .bottom], CGFloat(10.0))
        .frame(maxWidth: .infinity)
        .background(Color.red.opacity(0.2))
        .background(.regularMaterial)
    }
}

struct ProcessingWorkoutDataView: View {
    
    var body: some View {
        VStack(spacing: 5.0) {
            HStack(spacing: 10.0) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                Text(NSLocalizedString("Processing Workouts…", comment: "Label"))
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            Text(NSLocalizedString("Some data may not be available while processing", comment: "Text"))
                .font(.footnote)
                .foregroundColor(.primary.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding([.top, .bottom], CGFloat(10.0))
        .frame(maxWidth: .infinity)
        .background(Color.red.opacity(0.2))
        .background(.regularMaterial)
    }
    
}

struct NoWorkoutsView_Previews: PreviewProvider {
    
    static var previews: some View {
        NavigationView {
            VStack {
                NoWorkoutsView()
                ProcessingWorkoutDataView()
            }
        }
        .preferredColorScheme(.light)
    }
}

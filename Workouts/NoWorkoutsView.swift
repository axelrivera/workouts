//
//  NoWorkoutsView.swift
//  Workouts
//
//  Created by Axel Rivera on 2/7/21.
//

import SwiftUI

struct NoWorkoutsView: View {
    var action = {}
    
    var body: some View {
        VStack(alignment: .center, spacing: 20.0) {
            Spacer()
            Text("No Workouts")
                .font(.title)
                .foregroundColor(.secondary)
            Image(systemName: "exclamationmark.triangle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100, alignment: .center)
                .foregroundColor(.red)
            Text("There are no workouts available on Apple Health or reading permissions are disabled. Open the Health app and go to to Profile, Apps, Workouts to enable reading permissions.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.bottom)
            
            Spacer()
            
            RoundButton(text: "Dismiss", action: action)
        }
        .padding()
    }
}

struct NoWorkoutsView_Previews: PreviewProvider {
    static var previews: some View {
        NoWorkoutsView()
    }
}

struct NoWorkoutsModifier: ViewModifier {
    @EnvironmentObject var workoutManager: WorkoutManager

    func body(content: Content) -> some View {
        content.overlay(overlay())
    }

    @ViewBuilder
    func overlay() -> some View {
        if workoutManager.showNoWorkoutsOverlay {
            ZStack {
                Color.systemBackground
                    .ignoresSafeArea()
                NoWorkoutsView {
                    withAnimation {
                        workoutManager.showNoWorkoutsOverlay = false
                    }
                }
            }
        }
    }

}

extension View {
    
    func noWorkoutsOverlay() -> some View {
        modifier(NoWorkoutsModifier())
    }
    
}

//
//  AuthMessageView.swift
//  Workouts
//
//  Created by Axel Rivera on 2/6/21.
//

import SwiftUI

struct WorkoutEmptyView: View {
    var workoutState: WorkoutManager.State
    
    var body: some View {
        Group {
            switch workoutState {
            case .empty:
                NoWorkoutsView()
            case .notAvailable, .permissionDenied:
                NotAvailableView()
            default:
                EmptyView()
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
    }
}

struct AuthMessageView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutEmptyView(workoutState: .notAvailable)
    }
}

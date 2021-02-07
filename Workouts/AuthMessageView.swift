//
//  AuthMessageView.swift
//  Workouts
//
//  Created by Axel Rivera on 2/6/21.
//

import SwiftUI

/*

 Auth Status: Undetermined, Authorized, Unauthorized, Data Not Available
 Possible actions:
 
 1. Undeternined: Ask user to request permissions. Show Button with Action.
 2. Authorized -- Do nothing. Show workouts
 3. Unauthorized -- Tell user to go to HealthKit and update permissions
 4. Data Not Available -- Show Error Message with Data Not available
 */

struct AuthMessageView: View {
    var workoutState: WorkoutManager.State
    
    var body: some View {
        VStack(alignment: .center, spacing: 20.0) {
            switch workoutState {
            case .empty:
                Text("No Workouts")
                    .font(.title)
                    .foregroundColor(.secondary)
                Image(systemName: "figure.walk")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/, height: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                    .foregroundColor(.yellow)
                Text("There are no workouts available or reading permissions are disabled. Open the Health app and go to to Profile, Apps, Workouts to enable reading permissions.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom)
            case .notAvailable:
                DataErrorView()
            default:
                EmptyView()
            }
        }
        .padding()
        .frame(minWidth: /*@START_MENU_TOKEN@*/0/*@END_MENU_TOKEN@*/, maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, minHeight: /*@START_MENU_TOKEN@*/0/*@END_MENU_TOKEN@*/, maxHeight: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
    }
}

struct AuthMessageView_Previews: PreviewProvider {
    static var previews: some View {
        AuthMessageView(workoutState: .empty)
    }
}

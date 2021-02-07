//
//  OnboardingView.swift
//  Workouts
//
//  Created by Axel Rivera on 2/7/21.
//

import SwiftUI

struct OnboardingView: View {
    var action = {}
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 10) {
                Text("Welcome to Workouts")
                    .font(.largeTitle)
                    .padding(.bottom, 40.0)
                Image(systemName: "heart.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/, height: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                    .foregroundColor(.red)
                Text("Workouts needs your permission to display your workout info from the Apple Health app.")
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
                            
            RoundButton(text: "Request Permission", action: action)
        }
        .padding()
        .frame(minWidth: /*@START_MENU_TOKEN@*/0/*@END_MENU_TOKEN@*/, maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, minHeight: /*@START_MENU_TOKEN@*/0/*@END_MENU_TOKEN@*/, maxHeight: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, alignment: .center)
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}

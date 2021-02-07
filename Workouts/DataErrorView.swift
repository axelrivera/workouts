//
//  DataErrorView.swift
//  Workouts
//
//  Created by Axel Rivera on 2/7/21.
//

import SwiftUI

struct DataErrorView: View {
    var body: some View {
        VStack(spacing: 20.0) {
            Image(systemName: "heart.slash.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/, height: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                .foregroundColor(.red)
            Text("Health data is not available on this device.")
                .multilineTextAlignment(.center)
        }
    }
}

struct DataErrorView_Previews: PreviewProvider {
    static var previews: some View {
        DataErrorView()
    }
}

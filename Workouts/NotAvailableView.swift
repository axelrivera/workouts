//
//  NotAvailableView.swift
//  Workouts
//
//  Created by Axel Rivera on 2/7/21.
//

import SwiftUI

struct NotAvailableView: View {
    var body: some View {
        VStack(spacing: 20.0) {
            Image(systemName: "heart.slash.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100, alignment: .center)
                .foregroundColor(.red)
            Text("Health data is not available on this device.")
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct NotAvailableView_Previews: PreviewProvider {
    static var previews: some View {
        NotAvailableView()
    }
}

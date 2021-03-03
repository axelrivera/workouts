//
//  DetailAnalysisView.swift
//  Workouts
//
//  Created by Axel Rivera on 3/1/21.
//

import SwiftUI

struct DetailAnalysisView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Hello, World!")
            }
            .navigationBarTitle("Workout Analysis")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Text("Done")
                    }
                }
            }
        }
    }
}

struct DetailAnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        DetailAnalysisView()
    }
}

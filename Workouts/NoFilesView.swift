//
//  NoFilesView.swift
//  Workouts
//
//  Created by Axel Rivera on 2/7/21.
//

import SwiftUI

struct NoFilesView: View {
    var addAction = {}
    
    var body: some View {
        VStack(alignment: .center, spacing: 20.0) {
            Image(systemName: "icloud.and.arrow.down")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100, alignment: .center)
            
            Button(action: addAction, label: {
                Text("Add Workout Files")
            })
            .foregroundColor(.accentColor)
            
            Text("Tap on \"Add Workout Files\" to import one or more workouts from iCloud. FIT files only.")
                .multilineTextAlignment(.center)
                .padding([.leading, .trailing])
        }
        .foregroundColor(.secondary)
    }
}

struct NoFilesView_Previews: PreviewProvider {
    static var previews: some View {
        NoFilesView()
    }
}

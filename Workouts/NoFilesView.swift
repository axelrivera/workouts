//
//  NoFilesView.swift
//  Workouts
//
//  Created by Axel Rivera on 2/7/21.
//

import SwiftUI

struct NoFilesView: View {
    var addAction = {}
    var reviewAction = {}
    
    var body: some View {
        VStack(alignment: .center, spacing: 30.0) {
            Spacer()
            
            Image(systemName: "archivebox")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100, alignment: .center)
                .foregroundColor(.secondary)
            
            Text("Add Workout Files")
                .font(.largeTitle)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 15.0) {
                HStack(spacing: 10.0) {
                    Image(systemName: "1.circle")
                        .font(.title)
                        .foregroundColor(.green)
                    Group {
                        Text("Save your FIT file to the ") +
                        Text("Files App").foregroundColor(.yellow).bold() +
                        Text(" on this device.")
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
                HStack(spacing: 10.0) {
                    Image(systemName: "2.circle")
                        .font(.title)
                        .foregroundColor(.green)
                    Group {
                        Text("Tap on ") +
                        Text("Add FIT Files").foregroundColor(.yellow).bold() +
                        Text(" button and select one or more files.")
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
                
                HStack(spacing: 10.0) {
                    Image(systemName: "3.circle")
                        .font(.title)
                        .foregroundColor(.green)
                    Group {
                        Text("Review the workout and tap on the ") +
                        Text("Import").foregroundColor(.yellow).bold() +
                        Text(" button for each file.")
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            Spacer()
            
            VStack(alignment: .center, spacing: 20.0) {
                RoundButton(text: "Add FIT Files", action: addAction)
                //Button("Review Tutorial", action: reviewAction)
            }
        }
        .padding()
    }
}

struct NoFilesView_Previews: PreviewProvider {
    static var previews: some View {
        NoFilesView()
            .background(Color.systemBackground)
            .colorScheme(.dark)
    }
}

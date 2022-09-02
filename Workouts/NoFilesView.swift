//
//  NoFilesView.swift
//  Workouts
//
//  Created by Axel Rivera on 2/7/21.
//

import SwiftUI

struct NoFilesView: View {
    
    var body: some View {
        VStack(alignment: .center, spacing: 30.0) {
            Spacer()
            
            Image(systemName: "archivebox")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100, alignment: .center)
                .foregroundColor(.secondary)
            
            Text(NSLocalizedString("Add Workout Files", comment: "Label"))
                .font(.largeTitle)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 15.0) {
                HStack(spacing: 10.0) {
                    Image(systemName: "1.circle")
                        .font(.title)
                        .foregroundColor(.green)
                    Group {
                        Text(NSLocalizedString("Save your FIT file to the ", comment: "No files section 1 line 1")) +
                        Text(NSLocalizedString("Files App", comment: "No files section 1 line 2")).foregroundColor(.yellow).bold() +
                        Text(NSLocalizedString(" on this device.", comment: "No files section 1 line 3"))
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
                HStack(spacing: 10.0) {
                    Image(systemName: "2.circle")
                        .font(.title)
                        .foregroundColor(.green)
                    Group {
                        Text(NSLocalizedString("Tap on the ", comment: "No files section 2 line 1")) +
                        Text(NSLocalizedString("add (+)", comment: "No files section 2 line 2")).foregroundColor(.yellow).bold() +
                        Text(NSLocalizedString(" button above and select one or more files.", comment: "No files section 2 line 3"))
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
                
                HStack(spacing: 10.0) {
                    Image(systemName: "3.circle")
                        .font(.title)
                        .foregroundColor(.green)
                    Group {
                        Text(NSLocalizedString("Review the workout and tap on the ", comment: "No files section 3 line 1")) +
                        Text(NSLocalizedString("Import", comment: "No files section 3 line 2")).foregroundColor(.yellow).bold() +
                        Text(NSLocalizedString(" button.", comment: "No files section 3 line 3"))
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            Spacer()
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

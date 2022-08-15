//
//  ImportEmptyView.swift
//  Workouts
//
//  Created by Axel Rivera on 8/14/22.
//

import SwiftUI

struct ImportEmptyView: View {
    let state: ImportManager.EmptyState
    
    var body: some View {
        switch state {
        case .default:
            NoFilesView()
        case .notAvailable:
            VStack {
                Spacer()
                WriteDeniedView()
                Spacer()
            }
        }
    }
}

struct ImportEmptyView_Previews: PreviewProvider {
    static var previews: some View {
        ImportEmptyView(state: .notAvailable)
    }
}

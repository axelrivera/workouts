//
//  ImportEmptyView.swift
//  Workouts
//
//  Created by Axel Rivera on 2/7/21.
//

import SwiftUI

struct ImportEmptyView: View {
    var importState: ImportManager.State
    var addAction = {}
    
    var body: some View {
        Group {
            switch importState {
            case .empty:
                NoFilesView(addAction: addAction)
            case .notAuthorized:
                WriteDeniedView()
            case .notAvailable:
                NotAvailableView()
            default:
                EmptyView()
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
    }
}

struct ImportEmptyView_Previews: PreviewProvider {
    static var previews: some View {
        ImportEmptyView(importState: .empty)
    }
}

//
//  ImportEmptyView.swift
//  Workouts
//
//  Created by Axel Rivera on 2/7/21.
//

import SwiftUI

struct ImportEmptyModifier: ViewModifier {
    let importState: ImportManager.State
    
    func body(content: Content) -> some View {
        switch importState {
        case .ok:
            content
        case .notAuthorized:
            VStack {
                Spacer()
                WriteDeniedView()
                Spacer()
            }
        case .notAvailable:
            VStack {
                Spacer()
                NotAvailableView()
                Spacer()
            }
        case .empty:
            NoFilesView()
        case .processing:
            VStack {
                Spacer()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                Spacer()
            }
        }
    }
    
}

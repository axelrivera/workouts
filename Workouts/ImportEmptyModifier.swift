//
//  ImportEmptyView.swift
//  Workouts
//
//  Created by Axel Rivera on 2/7/21.
//

import SwiftUI

struct ImportEmptyModifier: ViewModifier {
    let importState: ImportManager.State
    let isActive: Bool
    
    func body(content: Content) -> some View {
        if !isActive {
            NoFilesView()
        } else {
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
    
}

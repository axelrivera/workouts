//
//  EmptyListHeader.swift
//  Workouts
//
//  Created by Axel Rivera on 10/30/21.
//

import SwiftUI

struct EmptyListHeader: View {
    var body: some View {
        Color.clear
            .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
}

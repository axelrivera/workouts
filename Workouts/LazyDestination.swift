//
//  LazyDestination.swift
//  Workouts
//
//  Created by Axel Rivera on 8/2/21.
//

import SwiftUI

struct LazyDestination<Content: View>: View {
    let build: () -> Content
    
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }
    
    var body: Content {
        build()
    }
}

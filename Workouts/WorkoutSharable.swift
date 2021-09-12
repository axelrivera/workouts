//
//  WorkoutSharable.swift
//  WorkoutSharable
//
//  Created by Axel Rivera on 9/5/21.
//

import SwiftUI

let WORKOUT_CARD_WIDTH: CGFloat = 540.0
let WORKOUT_ROUTE_IMAGE_WIDTH: CGFloat = 250.0

protocol WorkoutSharable {
    var viewModel: WorkoutCardViewModel { get }
    var showBranding: Bool { get }
}

extension WorkoutSharable {
    
    var size: CGSize { CGSize(width: WORKOUT_CARD_WIDTH, height: WORKOUT_CARD_WIDTH) }
    
    var titleFont: Font {
        .system(size: CGFloat(44.0))
    }
    
    var title2Font: Font {
        .system(size: CGFloat(36.0))
    }
    
    var textFont: Font {
        .system(size: CGFloat(28.0))
    }
    
    var subheadlineFont: Font {
        .system(size: CGFloat(22.0))
    }
    
    var footnoteFont: Font {
        .system(size: CGFloat(22.0))
    }
    
    var defaultOpacity: Double { 0.75 }
    
}

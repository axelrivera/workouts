//
//  WorkoutCard.swift
//  WorkoutCard
//
//  Created by Axel Rivera on 8/23/21.
//

import SwiftUI

struct WorkoutCard: View {
    @ObservedObject var shareManager: ShareManager
    
    var showBranding: Bool {
        !shareManager.removeBranding
    }
    
    var body: some View {
        if shareManager.style == .map && shareManager.viewModel.includesLocation {
            WorkoutMapCard(
                viewModel: shareManager.viewModel,
                backgroundImage: shareManager.mapImage,
                showTitle: shareManager.showTitle,
                showDate: shareManager.showDate,
                showBranding: showBranding
            )
        } else {
            WorkoutColorCard(
                viewModel: shareManager.viewModel,
                color: shareManager.backgroundColor,
                location: shareManager.locationString,
                routeImage: shareManager.routeImage,
                showBranding: showBranding
            )
        }
    }
    
}

// MARK: - Preview

struct WorkoutCard_Previews: PreviewProvider {
    static var viewModel: WorkoutCardViewModel = {
        let preview = WorkoutCardViewModel.preview()
        return preview
    }()
    
    static var manager: ShareManager = {
        let manager = ShareManager()
        return manager
    }()
    
    static var previews: some View {
        WorkoutCard(shareManager: manager)
            .padding()
            .previewLayout(.sizeThatFits)
    }
    
}

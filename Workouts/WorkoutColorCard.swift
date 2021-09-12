//
//  WorkoutColorCard.swift
//  WorkoutColorCard
//
//  Created by Axel Rivera on 9/5/21.
//

import SwiftUI

import SwiftUI
import Polyline
import CoreLocation
import MapKit

struct WorkoutColorCard: View, WorkoutSharable {
    let viewModel: WorkoutCardViewModel
    var metric: WorkoutCardViewModel.Metric = .none
    var color: Color = .accentColor
    var location: String? = "Orlando, FL"
    var routeImage: UIImage? = nil
    var showBranding = true
    
    init(viewModel: WorkoutCardViewModel, metric: WorkoutCardViewModel.Metric, color: Color, location: String?, routeImage: UIImage?, showBranding: Bool) {
        self.viewModel = viewModel
        self.metric = metric
        self.color = color
        self.location = location
        self.routeImage = routeImage
        self.showBranding = showBranding
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            color
            
            VStack(alignment: .leading, spacing: spacing) {
                VStack(alignment: .leading, spacing: 0.0) {
                    Text(viewModel.title)
                        .font(titleFont)

                    if let date = viewModel.date {
                        Text(date)
                            .font(textFont)
                            .opacity(defaultOpacity)
                    }

                    if let location = location {
                        HStack {
                            Image(systemName: "location.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: locationIconWidth)
                            Text(location)
                                .font(textFont)
                        }
                        .opacity(defaultOpacity)
                        .padding(.top, headerPadding)
                    }
                }
                
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: metricSpacing) {
                        if let distance = viewModel.distance {
                            metricView(text: "Distance", detail: distance)
                        }

                        metricView(text: "Time", detail: viewModel.duration)
                        
                        if let text = metric.displayTitle, let detail = viewModel.value(for: metric) {
                            metricView(text: text, detail: detail)
                        }
                    }

                    if let image = routeImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(CGFloat(1.0), contentMode: .fit)
                            .frame(width: WORKOUT_ROUTE_IMAGE_WIDTH, height: WORKOUT_ROUTE_IMAGE_WIDTH, alignment: .center)
                            
                    }
                }
            }
            .padding(.all, defaultPadding)
        }
        .foregroundColor(.white)
        .frame(width: size.width, height: size.height, alignment: .top)
        .overlay(brandingOverlay(), alignment: .bottomTrailing)
    }
    
    @ViewBuilder
    func brandingOverlay() -> some View {
        if showBranding {
            Text("Shared with betterworkouts.app")
                .font(.system(size: 18.0))
                .foregroundColor(.white)
                .padding(EdgeInsets(top: CGFloat(5.0), leading: CGFloat(15.0), bottom: CGFloat(5.0), trailing: CGFloat(15.0)))
                .background(Color.darkGray)
        }
    }
    
    @ViewBuilder
    func metricView(text: String, detail: String) -> some View {
        VStack(alignment: .leading) {
            Text(text)
                .font(subheadlineFont)
                .opacity(defaultOpacity)
            Text(detail)
                .font(title2Font)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
}

// MARK: - Helper Methods

extension WorkoutColorCard {
    
    var defaultPadding: CGFloat { 25.0 }
    
    var spacing: CGFloat {
        showBranding ? 28.0 : 38.0
    }
    
    var metricSpacing: CGFloat { 16.0 }
    
    var headerPadding: CGFloat { 3.0 }
    
    var locationIconWidth: CGFloat { 16.0 }
    
}

// MARK: - Preview

struct WorkoutColorCard_Previews: PreviewProvider {
    static var viewModel: WorkoutCardViewModel = {
        let preview = WorkoutCardViewModel(
            sport: .cycling,
            indoor: false,
            title: "Outdoor Cycle",
            date: "Jan 1, 2021 @ 7:00 AM",
            duration: "2h 30m",
            distance: "30 mi",
            speed: "15.0 mph",
            pace: nil,
            heartRate: "145 bpm",
            elevation: "1,000 ft",
            coordinates: sampleCoordinates()
        )
        return preview
    }()
    
    static var previews: some View {
        WorkoutColorCard(
            viewModel: viewModel,
            metric: .none,
            color: .accentColor,
            location: "Orlando, FL",
            routeImage: nil,
            showBranding: true
        )
            .padding()
            .previewLayout(.sizeThatFits)
    }
    
}

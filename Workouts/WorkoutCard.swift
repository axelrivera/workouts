//
//  WorkoutCard.swift
//  WorkoutCard
//
//  Created by Axel Rivera on 8/23/21.
//

import SwiftUI
import Polyline
import CoreLocation
import MapKit

struct WorkoutCard: View {
    private let maxWidth: Double = 540.0
    private let titleFactor = 0.08
    private let title2Factor = 0.07
    private let textFactor = 0.05
    private let subheadlineFactor = 0.04
    private let footnoteFactor = 0.04
    private let defaultOpacity = 0.75
    
    let viewModel: WorkoutCardViewModel
    var color: Color = .accentColor
    var locationString: String? = "Orlando, FL"
    var locationImage: UIImage? = nil
    var showBranding = true
    var isScreen = false
    
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

                    if let location = locationString {
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

                        if let elevation = elevationString {
                            metricView(text: "Elevation", detail: elevation)
                        }

                        if let pace = paceString  {
                            metricView(text: "Pace", detail: pace)
                        }
                    }

                    if let image = locationImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(CGFloat(1.0), contentMode: .fit)
                            .frame(width: mapImageWidth, height: mapImageWidth, alignment: .center)
                            
                    }
                }
            }
            .padding(.all, defaultPadding)
        }
        .foregroundColor(.white)
        .overlay(brandingOverlay(), alignment: .bottom)
    }
    
    @ViewBuilder
    func brandingOverlay() -> some View {
        if showBranding {
            Text("Shared with betterworkouts.app")
                .font(footnoteFont)
                .foregroundColor(.white)
                .opacity(defaultOpacity)
                .frame(maxWidth: .infinity, alignment: .center)
                .offset(x: CGFloat(0), y: -defaultPadding)
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
    
    var elevationString: String? {
        guard viewModel.sport == .cycling else { return nil }
        return viewModel.elevation
    }
    
    var paceString: String? {
        guard viewModel.sport == .running || viewModel.sport == .walking else { return nil }
        return viewModel.pace
    }
    
}

// MARK: - Helper Methods

extension WorkoutCard {
    
    var defaultPadding: CGFloat {
        if isScreen {
            return 20.0
        } else {
            return maxWidth * 0.05
        }
    }
    
    var spacing: CGFloat {
        if isScreen {
            if showBranding {
                return 30.0
            } else {
                return 50.0
            }
        } else {
            if showBranding {
                return maxWidth * 0.05
            } else {
                return maxWidth * 0.07
            }
        }
    }
    
    var metricSpacing: CGFloat {
        if isScreen {
            return 10.0
        } else {
            return maxWidth * 0.03
        }
    }
    
    var headerPadding: CGFloat {
        if isScreen {
            return 5.0
        } else {
            return maxWidth * 0.005
        }
    }
    
    var locationIconWidth: CGFloat {
        if isScreen {
            return 13.0
        } else {
            return maxWidth * 0.03
        }
    }
    
    var width: CGFloat {
        if isScreen {
            return maxWidth
        } else {
            return .infinity
        }
    }
    
    var mapImageWidth: CGFloat {
        if isScreen {
            return 180.0
        } else {
            return maxWidth * 0.5
        }
    }
    
    var titleFont: Font {
        if isScreen {
            return .fixedLargeTitle
        } else {
            return .system(size: CGFloat(titleFactor * maxWidth))
        }
    }
    
    var title2Font: Font {
        if isScreen {
            return .fixedTitle
        } else {
            return .system(size: CGFloat(title2Factor * maxWidth))
        }
    }
    
    var textFont: Font {
        if isScreen {
            return .fixedBody
        } else {
            return .system(size: CGFloat(textFactor * maxWidth))
        }
    }
    
    var subheadlineFont: Font {
        if isScreen {
            return .fixedSubheadline
        } else {
            return .system(size: CGFloat(subheadlineFactor * maxWidth))
        }
    }
    
    var footnoteFont: Font {
        if isScreen {
            return .system(size: CGFloat(14.0), weight: .regular, design: .default)
        } else {
            return .system(size: CGFloat(footnoteFactor * maxWidth), weight: .regular, design: .default)
        }
    }
    
}

// MARK: - Preview

struct WorkoutCard_Previews: PreviewProvider {
    static var viewModel: WorkoutCardViewModel = {
        let preview = WorkoutCardViewModel.preview()
        return preview
    }()
    
    static var previews: some View {
        VStack {
            WorkoutCard(viewModel: viewModel, isScreen: true)
                .aspectRatio(CGFloat(1.0), contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .fixedSize(horizontal: false, vertical: true)
            
            PreviewMapImage(viewModel: viewModel)
        }
        .padding()
    }
    
}

struct PreviewMapImage: View {
    let viewModel: WorkoutCardViewModel
    
    @State private var cardImage: UIImage?
    @State private var mapImage: UIImage?
    
    var body: some View {
        if let image = cardImage {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(CGFloat(1.0), contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            Text("Missing Image")
                .onAppear { generateMap() }
        }
    }
    
    
    func reloadImage() {
        let width = 540.0
        cardImage = WorkoutCard(
            viewModel: viewModel,
            color: .red,
            locationString: "Orlando, FL",
            locationImage: mapImage,
            showBranding: true,
            isScreen: false
        )
            .frame(width: width, height: width, alignment: .top)
            .takeScreenshot(origin: .zero, size: CGSize(width: CGFloat(width), height: CGFloat(width)))
    }
    
    
    func generateMap() {
        MKMapView.routeMapOutline(coordinates: viewModel.coordinates) { image in
            self.mapImage = image
            reloadImage()
        }
    }
}

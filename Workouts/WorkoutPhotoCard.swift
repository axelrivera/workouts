//
//  WorkoutPhotoCard.swift
//  WorkoutColorCard
//
//  Created by Axel Rivera on 9/5/21.
//

import SwiftUI
import Polyline
import CoreLocation
import MapKit

struct WorkoutPhotoCard: View, WorkoutSharable {
    let OPACITY = 0.9
    
    let viewModel: WorkoutCardViewModel
    var metric: WorkoutCardViewModel.Metric = .none
    var backgroundImage: UIImage?
    var showTitle = false
    var showDate: Bool = false
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.black
            
            if let backgroundImage = backgroundImage {
                Image(uiImage: backgroundImage)
                    .resizable()
                    .scaledToFit()
                    .opacity(0.70)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .bottom, spacing: 10.0) {
                    Image(uiImage: UIImage(named: "bw_logo_horizontal")!)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 36.0)
                        .modifier(WorkoutPhotoShadowModifier())
                    
                    if let date = viewModel.date, showDate {
                        Spacer()
                        Text(date)
                            .font(.system(size: 18.0))
                            .opacity(OPACITY)
                            .shadow(radius: CGFloat(2.0))
                            .modifier(WorkoutPhotoShadowModifier())
                    }
                }
                
                Spacer()
                
                if showTitle {
                    Text(viewModel.title)
                        .font(.system(size: 28.0))
                        .opacity(OPACITY)
                        .modifier(WorkoutPhotoShadowModifier())
                }
                
                HStack(spacing: CGFloat(20.0)) {
                    if let distance = viewModel.distance, showDistance {
                        metricView(text: distanceTitle, detail: distance)
                    }

                    metricView(text: timeTitle, detail: viewModel.duration)
                    
                    if let text = metric.displayTitle, let detail = viewModel.value(for: metric) {
                        metricView(text: text, detail: detail)
                        
                        if let maxSpeed = viewModel.maxSpeed, metric == .speed {
                            metricView(text: "Max Speed", detail: maxSpeed)
                        } else if let maxHR = viewModel.maxHeartRate, metric == .heartRate {
                            metricView(text: ("Max HR"), detail: maxHR)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.all, CGFloat(20.0))
        }
        .foregroundColor(.white)
        .frame(width: size.width, height: size.height, alignment: .top)
    }
    
    @ViewBuilder
    func metricView(text: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 5.0) {
            Text(text)
                .font(.system(size: 18.0))
                .opacity(OPACITY)
                .modifier(WorkoutPhotoShadowModifier())
            Text(detail)
                .font(.system(size: 22.0, weight: .medium))
                .modifier(WorkoutPhotoShadowModifier())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    var timeTitle: String {
        if let _ = viewModel.distance, showDistance {
            return "Time"
        }
        
        if showTitle {
            return "Time"
        } else {
            return viewModel.sport.altName
        }
    }
}

struct WorkoutPhotoShadowModifier: ViewModifier {
    
    func body(content: Content) -> some View {
        content
            .shadow(color: Color.black, radius: CGFloat(1.0), x: CGFloat(0.0), y: CGFloat(1.0))
    }
    
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
            maxSpeed: "30 mph",
            pace: nil,
            heartRate: "145 bpm",
            maxHeartRate: "180 bpm",
            elevation: "1,000 ft",
            calories: "500 cal",
            coordinates: sampleCoordinates()
        )
        return preview
    }()
    
    static var backgroundImage: UIImage? {
        UIImage(named: "image_preview.jpg")
    }
    
    static var previews: some View {
        WorkoutPhotoCard(
            viewModel: viewModel,
            metric: .speed,
            backgroundImage: backgroundImage,
            showTitle: true,
            showDate: true
        )
            .padding()
            .previewLayout(.sizeThatFits)
    }
    
}

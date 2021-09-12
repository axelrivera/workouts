//
//  WorkoutMapCard.swift
//  WorkoutMapCard
//
//  Created by Axel Rivera on 9/5/21.
//

import SwiftUI

struct WorkoutMapCard: View, WorkoutSharable {
    private let contentPadding = EdgeInsets(
        top: CGFloat(10.0),
        leading: CGFloat(20.0),
        bottom: CGFloat(10.0),
        trailing: CGFloat(20.0)
    )
    
    let viewModel: WorkoutCardViewModel
    var metric: WorkoutCardViewModel.Metric = .none
    var backgroundImage: UIImage?
    var showTitle = true
    var showDate = true
    var showBranding: Bool = true
    
    var body: some View {
        ZStack(alignment: .top) {
            if let image = backgroundImage {
                Image(uiImage: image)
            } else {
                Color.systemFill
            }
            
            VStack(alignment: .leading, spacing: 10.0) {
                if showTitle || showDate {
                    HStack(alignment: .lastTextBaseline) {
                        if showTitle {
                            Text(viewModel.title)
                                .font(.system(size: 22.0, weight: .bold))
                                .shadow(radius: CGFloat(2.0))
                            
                            Spacer()
                        }
                        
                        if let date = viewModel.date, showDate {
                            Text(date)
                                .font(.system(size: 18.0))
                                .shadow(radius: CGFloat(2.0))
                                .padding(.bottom, CGFloat(3.0))
                        }
                    }
                }
                
                HStack {
                    if let distance = viewModel.distance {
                        metricView(text: distanceTitle, detail: distance)
                    }

                    metricView(text: "Time", detail: viewModel.duration)

                    if let text = metric.displayTitle, let detail = viewModel.value(for: metric) {
                        metricView(text: text, detail: detail)
                    }
                }
            }
            .padding(contentPadding)
            .background(Color.black.opacity(0.5))
        }
        .foregroundColor(.white)
        .frame(width: size.width, height: size.height, alignment: .top)
        .overlay(brandingOverlay(), alignment: .bottomTrailing)
    }
    
    @ViewBuilder
    func metricView(text: String, detail: String) -> some View {
        VStack(alignment: .leading) {
            Text(text)
                .font(.system(size: 18.0))
                .shadow(radius: CGFloat(2.0))
            Text(detail)
                .font(.system(size: 22.0, weight: .bold))
                .shadow(radius: CGFloat(2.0))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
}

extension WorkoutMapCard {
    
    var distanceTitle: String {
        if showTitle {
            return "Distance"
        } else {
            return viewModel.sport.altName
        }
    }
    
}

struct WorkoutMapCard_Previews: PreviewProvider {
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
        
    @State static var manager: ShareManager = {
        let manager = ShareManager()
        return manager
    }()
    
    static var previews: some View {
        WorkoutMapCard(viewModel: viewModel)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}

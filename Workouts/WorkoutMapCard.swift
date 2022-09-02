//
//  WorkoutMapCard.swift
//  WorkoutMapCard
//
//  Created by Axel Rivera on 9/5/21.
//

import SwiftUI

struct WorkoutMapCard: View, WorkoutSharable {
    static let headerHeight: CGFloat = 160
    static let footerHeight: CGFloat = 160
    
    private let contentPadding = EdgeInsets(
        top: CGFloat(20),
        leading: CGFloat(20),
        bottom: CGFloat(20),
        trailing: CGFloat(20)
    )
    
    let viewModel: WorkoutCardViewModel
    var metric1: WorkoutCardViewModel.Metric = .none
    var metric2: WorkoutCardViewModel.Metric = .none
    var backgroundImage: UIImage?
    var showTitle = true
    var showDate = true
    var mapColor = ShareManager.MapColor.dark
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0.0) {
                ZStack {
                    backgroundColor
                    
                    HStack(alignment: .bottom) {
                        Image(uiImage: UIImage(named: "bw_logo_horizontal")!)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 72)
                        
                        Spacer()
                        
                        if showTitle || showDate {
                            VStack(alignment: .trailing, spacing: 4) {
                                if showTitle {
                                    Text(viewModel.title)
                                        .font(.system(size: 40))
                                }

                                if let date = viewModel.date, showDate {
                                    Text(date)
                                        .font(.system(size: 36))
                                        .foregroundColor(secondaryColor)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding([.leading, .trailing], 40)
                }
                .frame(maxHeight: Self.headerHeight, alignment: .center)
                
                Group {
                    if let image = backgroundImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                    } else {
                        Color.systemFill
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)
                
                ZStack {
                    backgroundColor
                    
                    HStack(spacing: 40) {
                        if let distance = viewModel.distance {
                            metricView(text: distanceTitle, detail: distance, color: .distance)
                        }

                        metricView(text: LabelStrings.time, detail: viewModel.duration, color: timeColor)
                        
                        if let text = metric1.displayTitle, let detail = viewModel.value(for: metric1) {
                            metricView(text: text, detail: detail, color: color(for: metric1))
                        }
                        
                        if let text = metric2.displayTitle, let detail = viewModel.value(for: metric2) {
                            metricView(text: text, detail: detail, color: color(for: metric2))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding([.leading, .trailing], 40)
                }
                .frame(maxHeight: Self.footerHeight, alignment: .bottom)
            }
        }
        .foregroundColor(foregroundColor)
        .background(backgroundColor)
        .frame(width: size.width, height: size.height, alignment: .top)
    }
    
    @ViewBuilder
    func metricView(text: String, detail: String, color: Color? = nil) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(text)
                .font(.system(size: 36))
            Text(detail)
                .font(.system(size: 44, weight: .medium))
                .foregroundColor(color ?? foregroundColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension WorkoutMapCard {
    
    func colorTrait(for style: UIUserInterfaceStyle) -> UITraitCollection {
        UITraitCollection(userInterfaceStyle: style)
    }
    
    func color(named: String) -> Color {
        let color = UIColor(named: named)!
        let resultColor: UIColor
        
        switch mapColor {
        case .light:
            resultColor = color.resolvedColor(with: colorTrait(for: .light))
        case .dark:
            resultColor = color.resolvedColor(with: colorTrait(for: .dark))
        }
        return Color(uiColor: resultColor)
    }
    
    var speedColor: Color {
        color(named: "SpeedColor")
    }
    
    var paceColor: Color {
        color(named: "CadenceColor")
    }
    
    var timeColor: Color {
        color(named: "TimeColor")
    }
    
    func color(for metric: WorkoutCardViewModel.Metric) -> Color {
        switch metric {
        case .speed, .maxSpeed:
            return speedColor
        case .pace:
            return paceColor
        case .heartRate, .maxHeartRate, .calories:
            return .calories
        case .elevation:
            return .elevation
        default:
            return foregroundColor
        }
    }
    
    var foregroundColor: Color {
        switch mapColor {
        case .dark:
            return .white
        case .light:
            return .black
        }
    }
    
    var secondaryColor: Color {
        switch mapColor {
        case .dark:
            return Color(uiColor: UIColor(red: 235/255, green: 235/255, blue: 245/255, alpha: 0.6))
        case .light:
            return Color(uiColor: UIColor(red: 60/255, green: 60/255, blue: 67/255, alpha: 0.6))
        }
    }
    
    var backgroundColor: Color {
        switch mapColor {
        case .dark:
            return .black
        case .light:
            return .white
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
        
    @State static var manager: ShareManager = {
        let manager = ShareManager()
        return manager
    }()
    
    static var previews: some View {
        WorkoutMapCard(viewModel: viewModel, mapColor: .dark)
            .padding()
            .background(Color.red)
            .previewLayout(.sizeThatFits)
    }
}

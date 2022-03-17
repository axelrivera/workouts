//
//  DashboardCard.swift
//  Workouts
//
//  Created by Axel Rivera on 3/10/22.
//

import SwiftUI

struct DashboardCard: View {
    let PADDING: CGFloat = 30
    let OPACITY: CGFloat = 0.5
    
    let WORKOUTS_HEIGHT: CGFloat = 450
    
    let metrics: [DashboardMetricViewModel]
    let workout: DashboardWorkoutViewModel
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.white
            VStack(spacing: 0) {
                HStack {
                    logo()
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(workout.subtitle)
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.7))
                        Text(workout.title)
                            .bold()
                    }
                }
                .font(.system(size: 32))
                .foregroundColor(.white)
                .padding([.leading, .trailing], PADDING)
                .padding([.top, .bottom])
                .frame(maxWidth: .infinity, minHeight: 120 , maxHeight: 120)
                .background(Color.black)
                
                metricsView()
                
                if workout.isVisible {
                    workoutView()
                        .frame(height: WORKOUTS_HEIGHT)
                }
            }
            
        }
        .frame(width: workout.size.width, height: workout.size.height, alignment: .top)
    }
}

// MARK: - View Builders

extension DashboardCard {
    
    @ViewBuilder
    func logo() -> some View {
        Image(uiImage: UIImage(named: "bw_logo_text")!)
            .resizable()
            .scaledToFit()
            .frame(height: 42.0)
    }
    
    @ViewBuilder
    func metricsView() -> some View {
        ForEach(metrics, id: \.self) { viewModel in
            if viewModel.isVisible {
                HStack(spacing: PADDING) {
                    image(uiImage: viewModel.metric.image, color: viewModel.metric.color)
                    Text(viewModel.metric.title)
                    Spacer()
                    Text(viewModel.formattedValue)
                        .bold()
                }
                .font(.system(size: 42))
                .foregroundColor(.black)
                .padding([.leading, .trailing], PADDING)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(viewModel.metric.color.opacity(OPACITY))
            }
        }
    }
    
    @ViewBuilder
    func workoutView() -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                HStack(spacing: PADDING) {
                    image(uiImage: workout.total.metric.image, color: workout.total.metric.color)
                    Text(workout.total.metric.title)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity)
                .padding([.leading, .trailing], PADDING)
                .offset(x: 0, y: 5)
                
                Rectangle()
                    .fill(workout.total.metric.color)
                    .frame(width: 4)
                
                HStack {
                    Text("TOP WORKOUTS")
                        .foregroundColor(.white)
                        .bold()
                    
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(workout.total.metric.color)
            }
            .font(.system(size: 42))
            .foregroundColor(.black)
            .frame(height: 100, alignment: .center)
            
            HStack(spacing: 0) {
                VStack {
                    Text(workout.total.formattedValue)
                        .font(.system(size: 88))
                        .bold()
                    Text(workout.duration.formattedValue)
                }
                .frame(maxWidth: .infinity)
                
                Rectangle()
                    .fill(workout.total.metric.color)
                    .frame(width: 4)
                
                sportsView(activities: workout.activities)
                    .padding(20.0)
                    .frame(maxWidth: .infinity)
            }
            .font(.system(size: 42))
        }
        .foregroundColor(.black)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(workout.total.metric.color.opacity(OPACITY))
    }
    
    @ViewBuilder
    func sportsView(activities: [DashboardActivityViewModel]) -> some View {
        VStack(spacing: 0) {
            ForEach(activities, id: \.self) { viewModel in
                HStack(spacing: 20) {
                    activityImage(uiImage: viewModel.activity.image, color: DashboardMetric.workouts.color)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text(viewModel.activity.name)
                            .font(.system(size: 28))
                        
                        HStack {
                            if let distance = viewModel.formattedDistance {
                                Text(distance)
                                    .font(.system(size: 32))
                                    .bold()
                                    .minimumScaleFactor(0.5)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            if let duration = viewModel.formattedDuration {
                                Text(duration)
                                    .font(.system(size: 32))
                                    .minimumScaleFactor(0.5)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .font(.system(size: 42))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    @ViewBuilder
    func image(uiImage: UIImage, color: Color) -> some View {
        Image(uiImage: uiImage)
            .resizable()
            .scaledToFit()
            .frame(width: 44, height: 44, alignment: .center)
            .foregroundColor(.white)
            .padding()
            .background(Circle().fill(color))
    }
    
    @ViewBuilder
    func activityImage(uiImage: UIImage, color: Color) -> some View {
        Image(uiImage: uiImage)
            .resizable()
            .scaledToFit()
            .frame(width: 44, height: 44, alignment: .center)
            .foregroundColor(color)
            .padding()
            .background(Circle().strokeBorder(color, lineWidth: 6.0))
    }
    
}

struct DashboardCard_Previews: PreviewProvider {
    static let metrics = DashboardMetricViewModel.cardSample
    static let activities = DashboardActivityViewModel.sample
    
    static let workout = DashboardWorkoutViewModel(
        title: "January 2022",
        subtitle: "Fitness Stats",
        total: DashboardMetricViewModel(metric: .workouts, value: 99),
        duration: DashboardMetricViewModel(metric: .workoutTime, value: 3600),
        activities: activities
    )
    
    static var previews: some View {
        DashboardCard(metrics: metrics, workout: workout)
            .previewLayout(.sizeThatFits)
    }
}

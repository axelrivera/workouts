//
//  DashboardView.swift
//  Workouts
//
//  Created by Axel Rivera on 3/5/22.
//

import SwiftUI

struct DashboardView: View {
    enum ActiveCover: Identifiable {
        case settings
        var id: Self { self }
    }
    
    enum ActiveSheet: Identifiable {
        case filter
        case activity
        case metrics
        var id: Self { self }
    }
    
    @EnvironmentObject var purchaseManager: IAPManager
    
    @StateObject var manager = DashboardViewManager()
    @State private var activeCover: ActiveCover?
    @State private var activeSheet: ActiveSheet?
    
    private let metricColumns: [GridItem] = [
        GridItem(.flexible(), alignment: .center),
        GridItem(.flexible(), alignment: .center)
    ]
    
    private let activityColumns: [GridItem] = [
        GridItem(.flexible())
    ]
    
    var metricHeaderString: String {
        manager.rangeString
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                Group {
                    LazyVGrid(columns: metricColumns) {
                        Section(header: sectionHeader(metricHeaderString, showButton: true)) {
                            ForEach(manager.metrics, id: \.self) { viewModel in
                                metricView(viewModel: viewModel)
                            }
                        }
                    }
                    
                    if manager.activities.isPresent {
                        LazyVGrid(columns: activityColumns) {
                            Section(header: sectionHeader("Workout Summary", showButton: false)) {
                                ForEach(manager.activities, id: \.self) { viewModel in
                                    activityView(viewModel: viewModel)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .overlay(overlayView())
            .task {
                try? await manager.load()
            }
            .navigationTitle(manager.title)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { activeCover = .settings }) {
                       Image(systemName: "gearshape")
                    }
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: { activeSheet = .filter }) {
                        Image(systemName: "calendar")
                    }
                    
                    Button(action: { activeSheet = .activity }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .disabled(manager.isLoading)
                }
            }
            .sheet(item: $activeSheet, onDismiss: { manager.reload() }) { item in
                switch item {
                case .filter:
                    DashboardFilterView(
                        selected: $manager.currentInterval,
                        startDate: $manager.startDate,
                        endDate: $manager.endDate,
                        dateRange: $manager.dateRange
                    )
                case .activity:
                    activityView()
                case .metrics:
                    DashboardMetricsView()
                }
            }
            .fullScreenCover(item: $activeCover) { item in
                switch item {
                case .settings:
                    SettingsView()
                        .environmentObject(purchaseManager)
                }
            }
        }
    }
}

extension DashboardView {
    
    var showEmptyHUD: Bool {
        manager.isLoading && manager.metrics.isEmpty
    }
    
    var showHUD: Bool {
        manager.isLoading && manager.metrics.isPresent
    }
    
    @ViewBuilder
    func overlayView() -> some View {
        if showEmptyHUD {
            VStack(spacing: CGFloat(10)) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                Text("LOADING")
                    .font(.caption)
            }
        }
    }
    
    @ViewBuilder
    func sectionHeader(_ text: String, showButton: Bool) -> some View {
        HStack {
            Text(text)
                .font(.title2)
            if showButton {
                Spacer()
                
                if showHUD {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Button(action: { activeSheet = .metrics }) {
                        Image(systemName: "info.circle")
                            .font(.title3)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding([.top, .bottom], CGFloat(10))
    }
    
    @ViewBuilder
    func metricView(viewModel: DashboardMetricViewModel) -> some View {
        VStack(alignment: .leading, spacing: CGFloat(10)) {
            HStack(alignment: .center) {
                image(uiImage: viewModel.metric.image, color: viewModel.metric.color)
                Text(viewModel.metric.title)
                    .font(.fixedSubheadline)
                    .foregroundColor(viewModel.metric.color)
                    .lineLimit(2)
            }
            Spacer()
                            
            Text(viewModel.formattedValue)
                .font(.title2)
        }
        .padding([.top, .bottom], CGFloat(15))
        .padding([.leading, .trailing], CGFloat(10))
        .frame(maxWidth: .infinity, minHeight: CGFloat(120), alignment: .leading)
        .background(viewModel.metric.color.opacity(CGFloat(0.15)))
        .cornerRadius(CGFloat(12))
    }
    
    @ViewBuilder
    func image(uiImage: UIImage, color: Color) -> some View {
        Image(uiImage: uiImage)
            .resizable()
            .scaledToFit()
            .frame(width: CGFloat(20), height: CGFloat(20))
            .foregroundColor(color)
    }
    
    @ViewBuilder
    func activityView(viewModel: DashboardActivityViewModel) -> some View {
        VStack(alignment: .leading, spacing: CGFloat(20)) {
            HStack(alignment: .center) {
                image(uiImage: viewModel.activity.image, color: DashboardMetric.workouts.color)
                Text(viewModel.activity.name)
                    .font(.title3)
                    .foregroundColor(DashboardMetric.workouts.color)
                Spacer()
                Text(viewModel.totalLabel)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if viewModel.hasMetrics {
                HStack {
                    if let distance = viewModel.formattedDistance {
                        Text(distance)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if let duration = viewModel.formattedDuration {
                        Text(duration)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .font(.fixedTitle2)
            }
        }
        .padding(CGFloat(15))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Material.thinMaterial)
        .cornerRadius(CGFloat(12))
    }
    
    func activityView() -> AnyView {
        if let image = manager.image {
            return AnyView(ImageActivitySheet(image: image, imageType: .png, imageName: imageName))
        } else {
            return AnyView(Text("Image Missing"))
        }
    }
    
    var imageName: String {
        let date = Date()
        let timestamp = Int(date.timeIntervalSince1970)
        return String(format: "HealthStats_%@", timestamp as NSNumber)
    }
    
}

struct DashboardView_Previews: PreviewProvider {
    static var purchaseManager = IAPManagerPreview.manager(isActive: true)
    
    static var manager: DashboardViewManager = {
       let manager = DashboardViewManager()
        manager.metrics = DashboardMetricViewModel.sample
        manager.activities = DashboardActivityViewModel.sample
        return manager
    }()
    
    static var previews: some View {
        DashboardView(manager: manager)
            .environmentObject(purchaseManager)
            .preferredColorScheme(.dark)
    }
}

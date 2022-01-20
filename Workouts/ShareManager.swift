//
//  ShareManager.swift
//  ShareManager
//
//  Created by Axel Rivera on 9/5/21.
//

import SwiftUI
import Combine
import CoreLocation
import MapKit

extension ShareManager {
    enum ShareStyle: String, Identifiable, CaseIterable {
        case map
        case photo
        
        var id: String { rawValue }
        var title: String { rawValue.capitalized }
    }
    
    enum MapColor: String, Identifiable, CaseIterable {
        case dark
        case light
        
        var id: String { rawValue }
        var title: String { rawValue.capitalized }
    }
}

class ShareManager: ObservableObject {
    private(set) var viewModel = WorkoutCardViewModel.empty()
    private var shouldRefreshImages = false
    
    @Published var style = ShareStyle.photo {
        didSet {
            if style == .map && mapImage == nil {
                reloadMapImage()
            } else {
                reloadImage()
            }
        }
    }
    
    @Published var isGeneratingImage = false
    @Published var selectedMetric: WorkoutCardViewModel.Metric
    @Published var sharedImage: UIImage?
    
    // Map
    @Published var mapColor = MapColor.dark {
        didSet {
            reloadMapImage()
        }
    }
    
    @Published var showTitle = true
    @Published var showDate = true
    
    // Photo
    @Published var filter = PhotoFilterType.original
    @Published var filterPreviews = [PhotoFilterViewModel]()
    @Published var backgroundOriginalImage: UIImage?
    private(set) var backgroundImage: UIImage?
    
    private(set) var darkMapImage: UIImage?
    private(set) var lightMapImage: UIImage?
    
    private let settings: ShareSettings
    private var coordinates: [CLLocationCoordinate2D] { viewModel.coordinates }
    
    init() {
        let settings = AppSettings.shareSettings
        
        self.settings = settings
        style = settings.style
        selectedMetric = .none
        showTitle = settings.showTitle
        showDate = settings.showDate
        shouldRefreshImages = true
    }
    
    var mapImage: UIImage? {
        switch mapColor {
        case .dark:
            return darkMapImage
        case .light:
            return lightMapImage
        }
    }
    
    func loadValues(viewModel: WorkoutCardViewModel) async {
        let darkMapImage = try? await generateBackgroundMap(for: viewModel.coordinates, colorScheme: .dark)
        let lightMapImage = try? await generateBackgroundMap(for: viewModel.coordinates, colorScheme: .light)
        let selectedMetric = settings.metric(for: viewModel.sport)
        
        Log.debug("selected metric: \(String(describing: selectedMetric))")
        
        DispatchQueue.main.async {
            self.selectedMetric = selectedMetric ?? Self.defaultMetric(for: viewModel.sport)
            self.viewModel = viewModel
            
            // cached values
            self.darkMapImage = darkMapImage
            self.lightMapImage = lightMapImage
            
            self.reloadImage()
        }
    }
    
    static func defaultMetric(for sport: Sport) -> WorkoutCardViewModel.Metric {
        if sport.isCycling {
            return .speed
        } else if sport.isWalkingOrRunning {
            return .pace
        } else {
            return .none
        }
    }
    
}

// MARK: - Generate Image

extension ShareManager {
    
    func reloadMapImage() {
        guard shouldRefreshImages else { return }
        
        DispatchQueue.main.async {
            self.isGeneratingImage = true
        }
                
        Task(priority: .userInitiated) {
            let darkMapImage: UIImage?
            let lightMapImage: UIImage?
            if style == .map && viewModel.includesLocation {
                darkMapImage = try? await generateBackgroundMap(for: viewModel.coordinates, colorScheme: .dark)
                lightMapImage = try? await generateBackgroundMap(for: viewModel.coordinates, colorScheme: .light)
            } else {
                darkMapImage = nil
                lightMapImage = nil
            }
            
            self.darkMapImage = darkMapImage
            self.lightMapImage = lightMapImage
            self.reloadImage()
        }
    }
    
    func reloadImage(ignorePreviews: Bool = false) {
        guard shouldRefreshImages else { return }
        
        if !isGeneratingImage {
            DispatchQueue.main.async {
                self.isGeneratingImage = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let original = self.backgroundOriginalImage, self.style == .photo {
                self.backgroundImage = original.addFilter(filter: self.filter)
                
                if !ignorePreviews {
                    self.filterPreviews = PhotoFilterType.allCases.map { filter in
                        PhotoFilterViewModel(filter: filter, preview: original.addFilter(filter: filter))
                    }
                }
            }
            
            let view = WorkoutCard(shareManager: self)
            let image = view.takeScreenshot(origin: .zero, size: CGSize(width: WORKOUT_CARD_WIDTH, height: WORKOUT_CARD_WIDTH))
            
            withAnimation(.linear) {
                self.isGeneratingImage = false
                self.sharedImage = image
            }
            
            self.updateSettings()
        }
    }
    
    func updateSettings() {
        let newSettings = ShareSettings(
            styleValue: style.rawValue,
            cyclingMetricValue: viewModel.sport.isCycling ? selectedMetric.rawValue : settings.cyclingMetricValue,
            runningMetricValue: viewModel.sport.isWalkingOrRunning ? selectedMetric.rawValue : settings.runningMetricValue,
            showTitle: showTitle,
            showDate: showDate
        )
        
        DispatchQueue.global(qos: .background).async {
            AppSettings.shareSettings = newSettings
        }
    }
    
    func selectMapColor(_ mapColor: MapColor) {
        if self.mapColor == mapColor { return }
        self.mapColor = mapColor
    }
    
}

// MARK: - Location Methods

extension ShareManager {
    
    func generateBackgroundMap(for coordinates: [CLLocationCoordinate2D], colorScheme: ColorScheme) async throws -> UIImage? {
        guard style == .map else { return nil }
        if coordinates.isEmpty { return nil }
        guard let region = MKCoordinateRegion(coordinates: coordinates) else { return nil }

        let userInterfaceStyle: UIUserInterfaceStyle = UIUserInterfaceStyle(colorScheme)
        let colorSchemeCollection = UITraitCollection(userInterfaceStyle: userInterfaceStyle)
        let scaleCollection = UITraitCollection(displayScale: 2.0)

        let size = CGSize(width: WORKOUT_CARD_WIDTH, height: WORKOUT_CARD_WIDTH - (WorkoutMapCard.footerHeight + WorkoutMapCard.headerHeight))
        let options = MKMapSnapshotter.Options()
        options.region = region
        options.size = size
        options.traitCollection = UITraitCollection(traitsFrom: [colorSchemeCollection, scaleCollection])
        options.showsBuildings = false

        let snapshotter = MKMapSnapshotter(options: options)
        let snapshot = try await snapshotter.start()
        let mapImage = snapshot.image

        let image = UIGraphicsImageRenderer(size: size).image { _ in
            mapImage.draw(at: .zero)

            if coordinates.isEmpty { return }

            let points = coordinates.map { snapshot.point(for: $0) }

            let path = UIBezierPath()
            path.move(to: points[0])

            for point in points.dropFirst() {
                path.addLine(to: point)
            }

            // stroke it

            path.lineWidth = 5.0
            UIColor(.accentColor).setStroke()
            path.stroke()
        }
        return image
    }
    
}

extension ShareManager {
    
    func selectFilter(_ filter: PhotoFilterType) {
        self.filter = filter
        reloadImage(ignorePreviews: true)
    }
    
    func isFilterSelected(_ filter: PhotoFilterType) -> Bool {
        self.filter == filter
    }
    
}

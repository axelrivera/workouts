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
        case color
        
        var id: String { rawValue }
        var title: String { rawValue.capitalized }
    }
    
    enum MapColor: String, Identifiable, CaseIterable {
        case system
        case dark
        case light
        
        var id: String { rawValue }
        var title: String { rawValue.capitalized }
        
        var colorScheme: ColorScheme? {
            switch self {
            case .dark:
                return .dark
            case .light:
                return .light
            default:
                return nil
            }
        }
    }
}

class ShareManager: ObservableObject {
    private(set) var viewModel = WorkoutCardViewModel.empty()
    private var colorScheme = ColorScheme.light
    private var shouldRefreshImages = false
    
    @Published var style = ShareStyle.color {
        didSet {
            if style == .map && mapImage == nil {
                reloadMapImage()
            } else {
                reloadImage()
            }
        }
    }
    
    @Published var removeBranding = false {
        didSet {
            reloadImage()
        }
    }
    
    @Published var selectedMetric: WorkoutCardViewModel.Metric
    @Published var sharedImage: UIImage?
    
    // Map
    @Published var mapColor = MapColor.system {
        didSet {
            reloadMapImage()
        }
    }
    
    @Published var showTitle = true
    @Published var showDate = true
    
    // Color
    @Published var backgroundColor: Color = .accentColor
    @Published var showLocation = true
    @Published var showRoute = true
    
    private(set) var mapImage: UIImage?
    private var cachedLocationString: String?
    private var cachedRouteImage: UIImage?
    
    private let settings: ShareSettings
    private let geocoder = CLGeocoder()
    private var coordinates: [CLLocationCoordinate2D] { viewModel.coordinates }
    
    init() {
        let settings = AppSettings.shareSettings
        
        self.settings = settings
        style = settings.style
        selectedMetric = .none
        removeBranding = settings.removeBranding
        mapColor = settings.mapColor
        showTitle = settings.showTitle
        showDate = settings.showDate
        backgroundColor = settings.backgroundColor
        showLocation = settings.showLocation
        showRoute = settings.showRoute
        shouldRefreshImages = true
    }
    
    func loadValues(viewModel: WorkoutCardViewModel, colorScheme: ColorScheme) async {
        let currentColorScheme = mapColor.colorScheme ?? colorScheme
        let mapImage = try? await generateBackgroundMap(for: viewModel.coordinates, colorScheme: currentColorScheme)
        let locationString = try? await fetchLocationString(for: viewModel.coordinates)
        let routeImage = try? await generateMapOutline(for: viewModel.coordinates)
        
        let selectedMetric = settings.metric(for: viewModel.sport)
        
        Log.debug("selected metric: \(String(describing: selectedMetric))")
        
        DispatchQueue.main.async {
            self.selectedMetric = selectedMetric ?? Self.defaultMetric(for: viewModel.sport)
            self.viewModel = viewModel
            self.colorScheme = colorScheme
            
            // cached values
            self.mapImage = mapImage
            self.cachedLocationString = locationString
            self.cachedRouteImage = routeImage
            
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
    
    var locationString: String? {
        showLocation ? cachedLocationString : nil
    }
    
    var routeImage: UIImage? {
        showRoute ? cachedRouteImage : nil
    }
    
    func reloadMapImage() {
        guard shouldRefreshImages else { return }
        
        Task(priority: .userInitiated) {
            let mapImage: UIImage?
            if style == .map && viewModel.includesLocation {
                mapImage = try? await generateBackgroundMap(for: viewModel.coordinates, colorScheme: mapColor.colorScheme ?? colorScheme)
            } else {
                mapImage = nil
            }
            
            self.mapImage = mapImage
            self.reloadImage()
        }
    }
    
    func reloadImage() {
        guard shouldRefreshImages else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let view = WorkoutCard(shareManager: self)
            let image = view.takeScreenshot(origin: .zero, size: CGSize(width: WORKOUT_CARD_WIDTH, height: WORKOUT_CARD_WIDTH))
            
            withAnimation(.linear) {
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
            removeBranding: removeBranding,
            mapColorValue: mapColor.rawValue,
            showTitle: showTitle,
            showDate: showDate,
            backgroundColorDictionary: backgroundColor.colorDictionary,
            showLocation: showLocation,
            showRoute: showRoute
        )
        
        DispatchQueue.global(qos: .background).async {
            AppSettings.shareSettings = newSettings
        }
    }
    
}

// MARK: - Location Methods

extension ShareManager {
    
    func fetchLocationString(for coordinates: [CLLocationCoordinate2D]) async throws -> String? {
        guard cachedLocationString == nil else { return nil }
        guard let coordinate = coordinates.first else { return nil }
        
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let placemarks = try await geocoder.reverseGeocodeLocation(location)
        
        guard let placemark = placemarks.first else { return nil }
        var strings = [String]()
        
        if let city = placemark.locality {
            strings.append(city)
        }
        
        if let state = placemark.administrativeArea {
            strings.append(state)
        }
        
        return strings.joined(separator: ", ")
    }
    
    func generateMapOutline(for coordinates: [CLLocationCoordinate2D]) async throws -> UIImage? {
        if coordinates.isEmpty { return nil }
        guard let region = MKCoordinateRegion(coordinates: coordinates) else { return nil }
        
        let size = CGSize(width: WORKOUT_ROUTE_IMAGE_WIDTH, height: WORKOUT_ROUTE_IMAGE_WIDTH)
        let options = MKMapSnapshotter.Options()
        options.region = region
        options.size = size
        options.showsBuildings = false
        
        let snapshotter = MKMapSnapshotter(options: options)
        let snapshot = try await snapshotter.start()
        
        let image = UIGraphicsImageRenderer(size: size).image { _ in
            let points = coordinates.map { snapshot.point(for: $0) }

            let path = UIBezierPath()
            path.move(to: points[0])

            for point in points.dropFirst() {
                path.addLine(to: point)
            }

            // stroke it

            path.lineWidth = CGFloat(2.0)
            UIColor(white: 1.0, alpha: 1.0).setStroke()
            path.stroke()
        }
        return image
    }
    
    func generateBackgroundMap(for coordinates: [CLLocationCoordinate2D], colorScheme: ColorScheme) async throws -> UIImage? {
        guard style == .map else { return nil }
        if coordinates.isEmpty { return nil }
        guard let region = MKCoordinateRegion.workoutShareRegion(for: coordinates) else { return nil }
        
        let userInterfaceStyle: UIUserInterfaceStyle = UIUserInterfaceStyle(colorScheme)
        let colorSchemeCollection = UITraitCollection(userInterfaceStyle: userInterfaceStyle)
        let scaleCollection = UITraitCollection(displayScale: 2.0)
        
        let size = CGSize(width: WORKOUT_CARD_WIDTH, height: WORKOUT_CARD_WIDTH)
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

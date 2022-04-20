//
//  AnalyticsManager.swift
//  Workouts
//
//  Created by Axel Rivera on 4/18/22.
//

import Foundation
import PostHog

final class AnalyticsManager {
    #if PRODUCTION_BUILD
    private let API_KEY = "phc_WOyYn7kxZpG1wYfE6Phyk8o4rvVhA4OWdjl6icKShIE"
    #else
    private let API_KEY = "phc_n2V2JUBbvUzdqFGZ3mACKAKnclvdLhuyoJ8qbWQryeS"
    #endif
    
    private let HOST = "https://app.posthog.com"
    static let shared = AnalyticsManager()
    
    private var posthog: PHGPostHog?
        
    init() {        
        let configuration = PHGPostHogConfiguration(apiKey: API_KEY, host: HOST)
        configuration.captureApplicationLifecycleEvents = true
        configuration.recordScreenViews = false

        PHGPostHog.setup(with: configuration)
        posthog = PHGPostHog.shared()
    }
    
}

// MARK: - Pages

extension AnalyticsManager {
    
    func logPage(_ page: Page, properties: [String: Any]? = nil) {
        posthog?.screen(page.rawValue, properties: properties)
    }
   
}

// MARK: - Events

extension AnalyticsManager {
    
    func capture(_ event: Event, properties: [String: Any]? = nil) {
        posthog?.capture(event.rawValue, properties: properties)
    }
    
    // MARK: Custom Events
    
    func captureInstallOrUpdate() {
        if AppSettings.version == 0 {
            capture(.installed)
            AppSettings.version = AppSettings.CURRENT_VERSION
        } else if AppSettings.version < AppSettings.CURRENT_VERSION {
            capture(.updated)
            AppSettings.version = AppSettings.CURRENT_VERSION
        }
    }
    
    func captureOpen(isBackground: Bool, isPro: Bool) {
        capture(.opened, properties: ["from_background": isBackground, "$set": ["is_pro": isPro]])
    }
    
    func purchase(source: String, price: Double, displayPrice: String, identifier: String) {
        let properties: [String: Any] = [
            "source": source,
            "price": price,
            "display_price": displayPrice,
            "product": identifier,
            "$set": ["is_pro": true]
        ]
        
        capture(.purchased, properties: properties)
    }
    
    func sharedWorkout(style: ShareManager.ShareStyle, metric1: WorkoutCardViewModel.Metric, metric2: WorkoutCardViewModel.Metric) {
        let properties: [String: Any] = [
            "style": style.rawValue, "metric1": metric1.rawValue, "metric2": metric2.rawValue
        ]
        capture(.sharedWorkout, properties: properties)
    }
    
    func sharedDashboard(filter: DashboardViewManager.IntervalType) {
        capture(.sharedWorkout, properties: ["filter": filter.rawValue])
    }
    
    func saveTag(source: TagSource, isNew: Bool) {
        capture(.savedTag, properties: ["source": source.rawValue, "is_new": isNew])
    }
    
    func updateWorkoutTags(workouts: Bool) {
        capture(.workoutTags, properties: ["from_workouts": workouts])
    }
    
}


extension AnalyticsManager {
    
    struct Page: RawRepresentable {
        let rawValue: String
        
        static let workoutsFilter = Page(rawValue: "Workouts Filter")
        static let workoutAnalysis = Page(rawValue: "Workout Analysis")
        static let workoutSplits = Page(rawValue: "Workout Splits")
        static let workoutMap = Page(rawValue: "Workout Map")

        static let calendarFilter = Page(rawValue: "Calendar Filter")
        
        static let weeklyProgress = Page(rawValue: "Weekly Progress")
        static let monthlyProgress = Page(rawValue: "Monthly Progress")
        static let yearToDateProgress = Page(rawValue: "Year to Date Progress")
        static let allTimeProgress = Page(rawValue: "All Time Progress")
        
        static let dashboardFilter = Page(rawValue: "Dashboard Filter")
        
        static let tagMetrics = Page(rawValue: "Tag Metrics")
        
        static let editHRZones = Page(rawValue: "Edit HR Zones")
        
        static let paywall = Page(rawValue: "Paywall")
    }
    
    enum PaywallSource: String {
        case settings, calendar, progress, dashboard, tags
        case workoutAnalytics, workoutSplits
    }
    
}

extension AnalyticsManager {
    
    struct Event: RawRepresentable {
        let rawValue: String
        
        static let installed = Event(rawValue: "App Installed")
        static let updated = Event(rawValue: "App Updated")
        static let opened = Event(rawValue: "App Opened")
                
        static let onboarded = Event(rawValue: "Onboarded")
        
        static let workoutTags = Event(rawValue: "Updated Workout Tags")
        static let workoutHRZone = Event(rawValue: "Updated Workout HR Zones")
        static let sharedWorkout = Event(rawValue: "Shared Workout")
        
        static let addWorkoutFile = Event(rawValue: "Tapped Add File")
        static let importedWorkout = Event(rawValue: "Imported Workout")
        
        static let favorited = Event(rawValue: "Favorited")
        static let unfavorited = Event(rawValue: "Unfavorited")
        
        static let favoriteAll = Event(rawValue: "Favorited All")
        static let unfavoriteAll = Event(rawValue: "Unfavorited All")
        static let tagAll = Event(rawValue: "Tagged All")
        
        static let changedCalendarDisplay = Event(rawValue: "Changed Calendar Display")
        
        static let sharedDashboard = Event(rawValue: "Shared Dashboard")
        
        static let purchased = Event(rawValue: "Purchased")
        static let restoredPurchase = Event(rawValue: "Restored Purchase")
        
        static let savedTag = Event(rawValue: "Saved Tag")
        
        static let savedHRZone = Event(rawValue: "Saved HR Zone")
        static let applyAllHRZones = Event(rawValue: "Apply All HR Zones")
    }
    
    enum TagSource: String {
        case manage, selector, tags
    }
        
}

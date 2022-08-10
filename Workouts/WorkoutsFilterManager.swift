//
//  WorkoutsFilter.swift
//  Workouts
//
//  Created by Axel Rivera on 11/13/21.
//

import Foundation
import Combine
import CoreData
import SwiftUI

final class WorkoutsFilterManager: ObservableObject {
    enum WorkoutLocation: Identifiable {
        case `default`, indoor, outdoor
        var id: Int { hashValue }
        
        var isActive: Bool {
            self != .default
        }
    }
    
    enum DayOfWeek: Identifiable {
        case `default`, weekday, weekend

        var id: Int { hashValue}
        
        var isActive: Bool {
            self != .default
        }
    }
    
    enum SortBy: String, Hashable, Identifiable, CaseIterable {
        case date, distance, duration
        var id: String { rawValue }
        
        var title: String { rawValue.capitalized }
    }
    
    private let nonDecimalCharacters = CharacterSet.decimalDigits.inverted
    
    @Published var sortBy = SortBy.date {
        willSet {
            if sortBy == newValue {
                sortAscending.toggle()
            } else {
                sortAscending = false
            }
        }
    }
    
    @Published var sortAscending = false
    
    @Published var supportedSports = [Sport]()
    @Published var sports = Set<Sport>()
    @Published var workoutLocation = WorkoutLocation.default
    @Published var dayOfWeek = DayOfWeek.default
    
    @Published var showFavorites = false
    @Published var showDateRange = false
    
    @Published var dateRange: ClosedRange<Date>
    
    @Published var startDate: Date = Date()
    @Published var endDate: Date = Date()
    
    @Published var minDistance: String = ""
    @Published var maxDistance: String = ""
    
    @Published var total: Int = 0
    @Published var distance: Double = 0
    @Published var duration: Double = 0
    
    @Published var tags = [TagLabelViewModel]()
    @Published var selectedTags = Set<TagLabelViewModel>()
    
    @Published var isProcessingActions = false
        
    private let context: NSManagedObjectContext
    private let backgroundContext: NSManagedObjectContext
    private let dataProvider: DataProvider
    private let metaProvider: MetadataProvider
    private let tagProvider: TagProvider
    private let workoutTagProvider: WorkoutTagProvider
    
    private var tagsCancellable: Cancellable?
    
    init(context: NSManagedObjectContext) {
//        sports = [.cycling]
        
        self.context = context
        self.backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        self.backgroundContext.parent = context
        
        self.dataProvider = DataProvider(context: context)
        self.metaProvider = MetadataProvider(context: context)
        self.tagProvider = TagProvider(context: context)
        self.workoutTagProvider = WorkoutTagProvider(context: context)
                
        // Dates
        let dateInterval = dataProvider.dateIntervalForActiveWorkouts()
        dateRange = dateInterval.start ... dateInterval.end
        
        let interval = DateInterval.lastSixMonths()
        startDate = interval.start
        endDate = interval.end
        
        addObservers()
    }
    
}

extension WorkoutsFilterManager {
    
    func loadSports() {
        DispatchQueue.global(qos: .userInteractive).async {  [weak self] in
            guard let self = self else { return }
            
            self.context.perform {
                let sports = Workout.availableSports(in: self.context)
                let interval = self.dataProvider.dateIntervalForActiveWorkouts()
                
                DispatchQueue.main.async {
                    self.supportedSports = sports
                    self.dateRange = interval.start ... interval.end
                }
            }
        }
    }
    
    func count() -> Int {
        context.performAndWait {
            let request = Workout.defaultFetchRequest()
            request.predicate = filterPredicate()

            do {
                return try context.count(for: request)
            } catch {
                return 0
            }
        }
    }
    
    func updateTotals() {
        let (total, distance, duration) = dataProvider.fetchTotalDistanceAndDuration(for: filterPredicate())
        DispatchQueue.main.async {
            self.total = total
            self.distance = distance
            self.duration = duration
        }
    }
    
    var isFilterActive: Bool {
        if sports.isPresent { return true }
        if workoutLocation.isActive { return true }
        if dayOfWeek.isActive { return true }
        if showFavorites { return true }
        if showDateRange { return true }
        if let _ = minDistanceValue { return true }
        if let _ = maxdistanceValue { return true }
        if selectedTags.isPresent { return true }
        return false
    }
    
    func reset() {
        let interval = DateInterval.lastSixMonths()
        
        sports = Set<Sport>()
        workoutLocation = .default
        dayOfWeek = .default
        showFavorites = false
        showDateRange = false
        startDate = interval.start
        endDate = interval.end
        maxDistance = ""
        minDistance = ""
        tags = fetchTags()
        selectedTags = Set<TagLabelViewModel>()
        sortBy = .date
        sortAscending = false
    }
    
    func isSportSelected(_ sport: Sport) -> Bool {
        sports.contains(sport)
    }
    
    func togggleSport(_ sport: Sport) {
        withAnimation {
            if isSportSelected(sport) {
                sports.remove(sport)
            } else {
                sports.insert(sport)
            }
            reloadTags()
        }
    }
    
    func toggleSort(_ sortBy: SortBy) {
        withAnimation {
            self.sortBy = sortBy
        }
    }
    
}

extension WorkoutsFilterManager {
    
    var totalString: String {
        "\(total.formatted()) Workouts"
    }
    
    var distanceString: String {
        formattedDistanceStringInTags(for: distance)
    }
    
    var durationString: String {
        formattedHoursMinutesPrettyStringInTags(for: duration)
    }
    
}

// MARK: - Tags

extension WorkoutsFilterManager {
    typealias GearType = Tag.GearType
    
    var isBikeGearType: Bool {
        sports.contains(.cycling) && sports.count == 1
    }
    
    var isShoesGearType: Bool {
        let isCycling = sports.contains(.cycling)
        let isRunning = sports.contains(.running)
        let isWalking = sports.contains(.walking)
        
        return !isCycling && (isRunning || isWalking)
    }
    
    func availableSetGearTypes() -> [GearType] {
        if isBikeGearType {
            return [.bike, .none]
        } else if isShoesGearType {
            return [.shoes, .none]
        } else {
            return [.none]
        }
    }
    
    func availableFilterGearTypes() -> [GearType] {
        if sports.isEmpty { return GearType.allCases }
        
        var gearTypes: [GearType] = [.none]
        
        if sports.contains(.cycling) {
            gearTypes.append(.bike)
        }
        
        if sports.contains(.running) || sports.contains(.walking) {
            gearTypes.append(.shoes)
        }
        
        return gearTypes
    }
    
    func fetchTags() -> [TagLabelViewModel] {
        tagProvider.activeTags(gearTypes: availableFilterGearTypes()).map { $0.viewModel() }
    }
    
    func reloadTags() {
        let tags = fetchTags()
        let tagSet = Set<TagLabelViewModel>(tags)
        
        self.tags = tags
        selectedTags.formIntersection(tagSet)
    }
    
    func isTagSelected(_ tag: TagLabelViewModel) -> Bool {
        selectedTags.contains(tag)
    }
    
    func toggleTag(_ tag: TagLabelViewModel) {
        withAnimation {
            if isTagSelected(tag) {
                selectedTags.remove(tag)
            } else {
                selectedTags.insert(tag)
            }
        }
    }
    
    func updateWorkoutLocation(for location: WorkoutLocation) {
        withAnimation {
            if location == workoutLocation {
                workoutLocation = .default
            } else {
                workoutLocation = location
            }
        }
    }
    
    func updateDayOfWeek(for dayOfWeek: DayOfWeek) {
        withAnimation {
            if dayOfWeek == self.dayOfWeek {
                self.dayOfWeek = .default
            } else {
                self.dayOfWeek = dayOfWeek
            }
        }
    }
    
}

// MARK: - Actions

extension WorkoutsFilterManager {
    
    func favoriteAll() {
        if isProcessingActions { return }
        
        isProcessingActions = true
        let predicate = filterPredicate()
        
        context.perform { [unowned self] in
            let ids = self.dataProvider.workoutIdentifiers(for: predicate)
            ids.forEach { uuid in
                do {
                    try self.metaProvider.favoriteWorkout(for: uuid)
                    WorkoutStorage.updateFavorite(true, forID: uuid)
                } catch {
                    Log.debug("failed to add favorite: \(error.localizedDescription)")
                }
            }
            
            DispatchQueue.main.async {
                self.isProcessingActions = false
                NotificationCenter.default.post(name: .refreshWorkoutsFilter, object: nil)
                AnalyticsManager.shared.capture(.favoriteAll)
            }
        }
    }
    
    func unfavoriteAll() {
        if isProcessingActions { return }
        
        isProcessingActions = true
        let predicate = filterPredicate()
        
        context.perform { [unowned self] in
            let ids = self.dataProvider.workoutIdentifiers(for: predicate)
            ids.forEach { uuid in
                do {
                    try self.metaProvider.unfavoriteWorkout(for: uuid)
                    WorkoutStorage.updateFavorite(false, forID: uuid)
                } catch {
                    Log.debug("failed to remove favorite: \(error.localizedDescription)")
                }
            }
            
            DispatchQueue.main.async {
                self.isProcessingActions = false
                NotificationCenter.default.post(name: .refreshWorkoutsFilter, object: nil)
                AnalyticsManager.shared.capture(.unfavoriteAll)
            }
        }
    }
    
    func addTags(_ uuids: [UUID]) {
        if isProcessingActions { return }
        
        let predicate = filterPredicate()
        isProcessingActions = true
        
        backgroundContext.perform { [unowned self] in
            let workouts = self.dataProvider.workoutIdentifiers(for: predicate)
            for workoutId in workouts {
                guard let workout = Workout.find(using: workoutId, in: self.backgroundContext) else { continue }
                
                Log.debug("adding tags for workout: \(workoutId)")
                
                for tagId in uuids {
                    guard let tag = Tag.find(using: tagId, in: self.backgroundContext) else { continue }
                    guard workout.sport.supportsGearType(tag.gearType) else { continue }
                    Log.debug("adding tag: \(tag.name)")
                    
                    if let workoutTag = WorkoutTag.find(workout: workoutId, tag: tagId, context: self.backgroundContext) {
                        workoutTag.restore()
                    } else {
                        WorkoutTag.insert(into: self.backgroundContext, workout: workoutId, tag: tagId)
                    }
                }
                
                do {
                    try backgroundContext.save()
                    try context.save()
                    
                    WorkoutStorage.reloadWorkouts(for: workouts)
                } catch {
                    Log.debug("failed to save adding tags: \(error.localizedDescription)")
                }
            }
            
            DispatchQueue.main.async {
                WorkoutStorage.resetAll()
                self.isProcessingActions = false
                NotificationCenter.default.post(name: .refreshWorkoutsFilter, object: nil)
            }
        }
    }
    
}

// MARK: - Core Data

extension WorkoutsFilterManager {
    
    var isUsingIdentifiers: Bool {
        showFavorites || selectedTags.isPresent
    }
    
    func filterSort() -> [NSSortDescriptor] {
        if isFilterActive {
            switch sortBy {
            case .distance:
                return [Workout.sortedByDistanceDescriptor(ascending: sortAscending)]
            case .duration:
                return [Workout.sortedByDurationDescriptor(ascending: sortAscending)]
            case .date:
                return [Workout.sortedByDateDescriptor(ascending: sortAscending)]
            }
        } else {
            return [Workout.sortedByDateDescriptor()]
        }
    }
    
    func filterPredicate() -> NSPredicate {
        if endDate < startDate {
            endDate = startDate
        }
        
        var predicates = [Workout.notMarkedForLocalDeletionPredicate]
        
        var ids = Set<UUID>()
        
        if showFavorites {
            let workouts = WorkoutMetadata.favorites(in: context)
            let active = dataProvider.workoutIdentifiers(for: Workout.activePredicate(for: workouts))
            ids.formUnion(active)
        }
        
        if selectedTags.isPresent {
            let tagIds = selectedTags.map { $0.id }
            let workouts = workoutTagProvider.workoutIdentifiers(allTags: tagIds)
            let active = dataProvider.workoutIdentifiers(for: Workout.activePredicate(for: workouts))
            
            if ids.isEmpty {
                ids.formUnion(active)
            } else {
                ids.formIntersection(active)
            }
        }
        
        // query should be false if validating by identifiers and there are no identifiers present
        if isUsingIdentifiers && ids.isEmpty {
            return NSPredicate(value: false)
        }
        
        if ids.isPresent {
            predicates.append(Workout.activePredicate(for: Array(ids)))
        }
        
        if showDateRange {
            let start = startDate.startOfDay
            let end = endDate.endOfDay
            
            let interval = DateInterval(start: start, end: end)
            predicates.append(Workout.predicateForInterval(interval))
        }
        
        if sports.isPresent {
            predicates.append(Workout.predicateForSports(Array(sports)))
        }
        
        if workoutLocation.isActive {
            predicates.append(Workout.predicateForIndoor(workoutLocation == .indoor))
        }
        
        if dayOfWeek.isActive {
            switch dayOfWeek {
            case .weekday:
                predicates.append(Workout.predicateForWeekday())
            case .weekend:
                predicates.append(Workout.predicateForWeekend())
            default:
                break
            }
        }
        
        if let distance = minDistanceValue {
            predicates.append(Workout.predicateForMinDistance(distance))
        }
        
        if let distance = maxdistanceValue {
            predicates.append(Workout.predicateForMaxDistance(distance))
        }
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
    
    private var minDistanceValue: Double? {
        guard let distance = Double(minDistance.removingCharacters(in: nonDecimalCharacters)) else { return nil }
        return localizedDistanceToMeters(for: distance)
    }
    
    private var maxdistanceValue: Double? {
        guard let distance = Double(maxDistance.removingCharacters(in: nonDecimalCharacters)) else { return nil }
        return localizedDistanceToMeters(for: distance)
    }
    
}

// MARK: - Observers

extension Notification.Name {
    
    static var addTagsToAll = Notification.Name("arn_add_tags_to_all")
    static var refreshWorkoutsFilter = Notification.Name("arn_refresh_workouts_filter")
    
}

extension Notification {
    static var tagsKey = "tags"
}

extension WorkoutsFilterManager {
    
    func addObservers() {
        tagsCancellable = NotificationCenter.default.publisher(for: Notification.Name.addTagsToAll).sink { [unowned self] notification in
            guard let tags = notification.userInfo?[Notification.tagsKey] as? [UUID] else { return }
            self.addTags(tags)
        }
    }
    
}

extension Sport {
    
    func supportsGearType(_ gearType: Tag.GearType) -> Bool {
        switch self {
        case .cycling:
            return [.bike, .none].contains(gearType)
        case .running, .walking:
            return [.shoes, .none].contains(gearType)
        default:
            return gearType == .none
        }
    }
    
}

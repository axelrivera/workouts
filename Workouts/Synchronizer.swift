//
//  Synchronizer.swift
//  Workouts
//
//  Created by Axel Rivera on 5/27/21.
//

import CoreData
import HealthKit

class Synchronizer {
    let context: NSManagedObjectContext
    let importer: RemoteImporter
    let updator: RemoteUpdator
        
    var isAuthorizedToFetchWorkouts = false
    var anchor: HKQueryAnchor?
    var regenerate: Bool = false
    var isFetchingWorkouts = false
    
    init(context: NSManagedObjectContext) {
        self.context = context
        self.importer = RemoteImporter(context: context)
        self.updator = RemoteUpdator(context: context)
        self.anchor = AppSettings.workoutsQueryAnchor
        addObservers()
    }
    
    func fetchLatestWorkouts(resetAnchor: Bool = false, regenerate: Bool = false) async {
        // reset anchor even if is fetching
        // request will be ignored but anchor will be respected on next fetch
        if resetAnchor {
            anchor = nil
            AppSettings.workoutsQueryAnchor = anchor
        }

        self.regenerate = regenerate

        if isFetchingWorkouts {
            Log.debug("ignore remote data fetch - already fetching workouts")
            return
        }

        guard isAuthorizedToFetchWorkouts else {
            Log.debug("ignore remote data fetch - not authorized yet")
            return
        }
        
        // import workouts first
        Log.debug("importing workouts")
        self.isFetchingWorkouts = true
        let newAnchor =  await importer.importLatestWorkouts(anchor: anchor, regenerate: regenerate)
        
        // save anchor and regenerate flat before processing
        AppSettings.workoutsQueryAnchor = newAnchor
        self.anchor = newAnchor
        self.regenerate = false
        
        // update heart rate and location data
        await updator.updatePendingWorkouts()
        
        // reset fetching flag last
        self.isFetchingWorkouts = false
    }
    
    deinit {
        removeObservers()
    }
    
}

extension Synchronizer {
    
    @objc
    func fetchRemoteDataAction(_ notification: Notification) {
        if let isAuthorized = notification.userInfo?[Notification.isAuthorizedToFetchRemoteDataKey] as? Bool {
            isAuthorizedToFetchWorkouts = isAuthorized
        }

        // if regenerate is true we want to reset the anchor an fetch all workouts from health kit
        let regenerate = notification.userInfo?[Notification.regenerateDataKey] as? Bool ?? self.regenerate
        let resetAnchor = regenerate ? true : notification.userInfo?[Notification.resetAnchorKey] as? Bool ?? false
        
        let _ = context.performAndWait {
            Task {
                Log.debug("fetching remote data")
                await fetchLatestWorkouts(resetAnchor: resetAnchor, regenerate: regenerate)
            }
        }
    }
    
    func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(fetchRemoteDataAction), name: .shouldFetchRemoteData, object: nil)
    }
    
    func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: .shouldFetchRemoteData, object: nil)
    }
    
}

extension Notification.Name {
    
    static var shouldFetchRemoteData = Notification.Name("arn_should_fetch_remote_data")
    static var didInsertRemoteData = Notification.Name("arn_did_insert_remote_data")
    static var willBeginProcessingRemoteData = Notification.Name("arn_will_begin_processing_remote_data")
    static var didFinishProcessingRemoteData = Notification.Name("arn_did_finish_processing_remote_data")
    static var willBeginProcessingRemoteLocationData = Notification.Name("arn_will_begin_processing_remote_location_data")
    static var didFinishProcessingRemoteLocationData = Notification.Name("arn_did_finish_processing_remote_location_data")
    static var didUpdateRemoteLocationData = Notification.Name("arn_did_update_remote_location_data")
    
}

extension Notification {
    
    static var isAuthorizedToFetchRemoteDataKey = "arn_is_authorized_to_fetch_remote_data"
    static var remoteWorkoutKey = "arn_remote_workout"
    static var resetAnchorKey = "arn_reset_anchor"
    static var regenerateDataKey = "arn_regenerate_data"
    static var coordinatesKey = "arn_coordinates"
    
}

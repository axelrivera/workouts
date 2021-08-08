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
        
    var isAuthorizedToFetchWorkouts = false
    var anchor: HKQueryAnchor?
    var regenerate: Bool = false
    var isFetchingWorkouts = false
    
    init(context: NSManagedObjectContext) {
        self.context = context
        self.importer = RemoteImporter(context: context)
        addObservers()
    }
    
    func fetchLatestWorkouts(resetAnchor: Bool = false, regenerate: Bool = false) {
        // reset anchor even if is fetching
        // request will be ignored but anchor will be respected on next fetch
        if resetAnchor {
            anchor = nil
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
        
        Log.debug("fetching remote data")
        context.performAndWait {
            self.isFetchingWorkouts = true
            self.importer.importLatestWorkouts(anchor: anchor, regenerate: self.regenerate) { [unowned self] newAnchor in
                self.anchor = newAnchor
                self.isFetchingWorkouts = false
                self.regenerate = false
                
                DispatchQueue.main.async {
                    Log.debug("LOG - send did refresh notification")
                    NotificationCenter.default.post(name: .didRefreshWorkouts, object: nil)
                }
            }
        }
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
        
        var resetAnchor = notification.userInfo?[Notification.resetAnchorKey] as? Bool ?? false
        let regenerate = notification.userInfo?[Notification.regenerateDataKey] as? Bool ?? false
        
        if regenerate {
            // if regenerate is true we want to reset the anchor an fetch all workouts from health kit
            resetAnchor = true
        }
        
        fetchLatestWorkouts(resetAnchor: resetAnchor, regenerate: regenerate)
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
    
}

extension Notification {
    
    static var isAuthorizedToFetchRemoteDataKey = "arn_is_authorized_to_fetch_remote_data"
    static var totalRemoteWorkoutsKey = "arn_total_remote_workouts"
    static var remoteWorkoutKey = "arn_remote_workout"
    static var resetAnchorKey = "arn_reset_anchor"
    static var regenerateDataKey = "arn_regenerate_data"
    
}

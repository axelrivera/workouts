//
//  Synchronizer.swift
//  Workouts
//
//  Created by Axel Rivera on 5/27/21.
//

import CoreData
import Combine

class Synchronizer {
    let context: NSManagedObjectContext
    let importer: RemoteImporter
        
    var isAuthorizedToFetchWorkouts = false
    
    init(context: NSManagedObjectContext) {
        self.context = context
        self.importer = RemoteImporter(context: context)
        addObservers()
    }
    
    func fetchLatestWorkouts() {
        guard isAuthorizedToFetchWorkouts else {
            Log.debug("ignore remote data fetch - not authorzed yet")
            return
        }
        
        Log.debug("fetching remote data")
        context.performAndWait {
            self.importer.importLatestWorkouts()
        }
        
        Log.debug("send refresh workouts notification")
        NotificationCenter.default.post(name: .didRefreshWorkouts, object: nil)
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
        fetchLatestWorkouts()
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
    
}

extension Notification {
    
    static var isAuthorizedToFetchRemoteDataKey = "arn_is_authorized_to_fetch_remote_data"
    
}

//
//  NotificationCenter+Publisher.swift
//  NotificationCenter+Publisher
//
//  Created by Axel Rivera on 9/3/21.
//

import SwiftUI

fileprivate let memoryNotification = UIApplication.didReceiveMemoryWarningNotification
fileprivate let finishedProcessingWorkoutsNotification = Notification.Name.didFinishProcessingRemoteData
fileprivate let finishedFetchingWorkoutsNotification = Notification.Name.didFinishFetchingRemoteData

extension NotificationCenter.Publisher {
    
    static func memoryPublisher() -> NotificationCenter.Publisher {
        NotificationCenter.default.publisher(for: memoryNotification)
    }
    
    static func workoutsFetchNotification() -> NotificationCenter.Publisher {
        NotificationCenter.default.publisher(for: finishedFetchingWorkoutsNotification)
    }
    
    static func workoutsProcessNotification() -> NotificationCenter.Publisher {
        NotificationCenter.default.publisher(for: finishedProcessingWorkoutsNotification)
    }
    
    static func foregroundPublisher() -> NotificationCenter.Publisher {
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
    }
    
}

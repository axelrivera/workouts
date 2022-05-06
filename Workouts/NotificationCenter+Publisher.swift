//
//  NotificationCenter+Publisher.swift
//  NotificationCenter+Publisher
//
//  Created by Axel Rivera on 9/3/21.
//

import SwiftUI

fileprivate let memoryNotification = UIApplication.didReceiveMemoryWarningNotification
fileprivate let refreshNotification = Notification.Name.didFinishProcessingRemoteData

extension NotificationCenter.Publisher {
    
    static func memoryPublisher() -> NotificationCenter.Publisher {
        NotificationCenter.default.publisher(for: memoryNotification)
    }
    
    static func workoutRefreshPublisher() -> NotificationCenter.Publisher {
        NotificationCenter.default.publisher(for: refreshNotification)
    }
    
    static func foregroundPublisher() -> NotificationCenter.Publisher {
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
    }
    
}

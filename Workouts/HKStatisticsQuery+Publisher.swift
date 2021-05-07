//
//  StatsProvider+Publisher.swift
//  Workouts
//
//  Created by Axel Rivera on 2/17/21.
//

import Combine
import HealthKit

extension Publishers {
    
    class StatisticsSubscription<S: Subscriber>: Subscription where S.Input == HKStatistics, S.Failure == Error {
        private let quantityType: HKQuantityType
        private let options: HKStatisticsOptions
        private let predicate: NSPredicate?
        private let start: Date
        private let end: Date
        private var subscriber: S?
        
        init(quantityType: HKQuantityType, options: HKStatisticsOptions, predicate: NSPredicate?, start: Date, end: Date, subscriber: S) {
            self.quantityType = quantityType
            self.options = options
            self.predicate = predicate
            self.start = start
            self.end = end
            self.subscriber = subscriber
            runQuery()
        }
        
        func cancel() {
            subscriber = nil
        }
        
        func request(_ demand: Subscribers.Demand) {
            // No Demand Updates
        }
        
        private func runQuery() {
            guard let subscriber = subscriber else { return }
            
            var predicates = [NSPredicate]()
            if let predicate = predicate {
                predicates.append(predicate)
            }
            
            let datePredicate = HKQuery.predicateForSamples(
                withStart: start,
                end: end,
                options: [.strictStartDate, .strictEndDate]
            )
            predicates.append(datePredicate)
            
            let finalPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            
            let query = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: finalPredicate,
                options: options) { (query, statistics, error) in
                _ = statistics.map(subscriber.receive)
                _ = error.map { subscriber.receive(completion: Subscribers.Completion.failure($0)) }
            }
            HealthData.healthStore.execute(query)
        }
    }
}

extension Publishers {
    
    struct StatisticsPublisher: Publisher {
        typealias Output = HKStatistics
        typealias Failure = Error
        
        private let quantityType: HKQuantityType
        private let options: HKStatisticsOptions
        private let predicate: NSPredicate?
        private let start: Date
        private let end: Date
        
        init(quantityType: HKQuantityType, options: HKStatisticsOptions, predicate: NSPredicate?, start: Date, end: Date) {
            self.quantityType = quantityType
            self.options = options
            self.predicate = predicate
            self.start = start
            self.end = end
        }
        
        func receive<S: Subscriber>(subscriber: S) where
            StatisticsPublisher.Failure == S.Failure, StatisticsPublisher.Output == S.Input {
                let subscription = StatisticsSubscription(
                    quantityType: quantityType,
                    options: options,
                    predicate: predicate,
                    start: start,
                    end: end,
                    subscriber: subscriber
                )
                subscriber.receive(subscription: subscription)
        }
    }
    
}

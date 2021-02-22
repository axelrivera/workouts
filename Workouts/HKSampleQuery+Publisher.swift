//
//  HKSampleQuery+Publisher.swift
//  Workouts
//
//  Created by Axel Rivera on 2/19/21.
//

import HealthKit
import Combine

extension Publishers {
    
    class SampleQuerySubscription<S: Subscriber>: Subscription where S.Input == [HKSample], S.Failure == Error {
        private var sampleType: HKSampleType
        private var predicate: NSPredicate?
        private var limit: Int
        private var sortDescriptors: [NSSortDescriptor]?
        private var subscriber: S?
        
        init(sampleType: HKSampleType, predicate: NSPredicate?, limit: Int, sortDescriptors: [NSSortDescriptor]?, subscriber: S) {
            self.sampleType = sampleType
            self.predicate = predicate
            self.limit = limit
            self.sortDescriptors = sortDescriptors
            self.subscriber = subscriber
            runQuery()
        }
        
        func cancel() {
            subscriber = nil
        }
        
        func request(_ demand: Subscribers.Demand) {
            // OPTIONAL: Updates to demand
        }
        
        private func runQuery() {
            guard let subscriber = subscriber else { return }
            
            let query = HKSampleQuery(
                sampleType: sampleType,
                predicate: predicate,
                limit: limit,
                sortDescriptors: sortDescriptors) { (query, samples, error) in
                _ = samples.map(subscriber.receive)
                _ = error.map { subscriber.receive(completion: Subscribers.Completion.failure($0)) }
            }
            HealthData.healthStore.execute(query)
        }
    }
    
}

extension Publishers {
    
    struct SampleQueryPublisher: Publisher {
        typealias Output = [HKSample]
        typealias Failure = Error
        
        private var sampleType: HKSampleType
        private var predicate: NSPredicate?
        private var limit: Int
        private var sortDescriptors: [NSSortDescriptor]?
        
        init(sampleType: HKSampleType, predicate: NSPredicate?, limit: Int, sortDescriptors: [NSSortDescriptor]?) {
            self.sampleType = sampleType
            self.predicate = predicate
            self.limit = limit
            self.sortDescriptors = sortDescriptors
        }
        
        func receive<S: Subscriber>(subscriber: S) where SampleQueryPublisher.Failure == S.Failure, SampleQueryPublisher.Output == S.Input {
            let subscription = SampleQuerySubscription(
                sampleType: sampleType,
                predicate: predicate,
                limit: limit,
                sortDescriptors: sortDescriptors,
                subscriber: subscriber
            )
            subscriber.receive(subscription: subscription)
        }
    }
    
}

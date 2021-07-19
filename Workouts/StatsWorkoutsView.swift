//
//  StatsWorkoutsView.swift
//  Workouts
//
//  Created by Axel Rivera on 7/7/21.
//

import SwiftUI
import CoreData

struct StatsWorkoutsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    var fetchRequest: FetchRequest<Workout>
    var workouts: FetchedResults<Workout> { fetchRequest.wrappedValue }
    
    init(sport: Sport?, interval: DateInterval?) {
        let request = Self.fetchRequest(for: sport, interval: interval)
        fetchRequest = FetchRequest(fetchRequest: request, animation: .default)
    }
    
    var body: some View {
        ZStack {
            List(workouts) { workout in
                NavigationLink(destination: DetailView(workout: workout)) {
                    VStack(alignment: .leading) {
                        HStack {
                            Text(workout.title)
                                .font(.title3)
                            Spacer()
                            Text(date(for: workout))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Item(text: "Distance", detail: distance(for: workout), detailColor: .distance)
                            Divider()
                            Item(text: "Time", detail: time(for: workout), detailColor: .time)
                            Divider()
                            Item(text: "Calories", detail: calories(for: workout), detailColor: .calories)
                            Divider()
                            Item(text: "Elevation", detail: elevation(for: workout), detailColor: .elevation)
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
            
            if workouts.isEmpty {
                Text("No Workouts")
                    .foregroundColor(.secondary)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        
    }
    
    private static func fetchRequest(for sport: Sport?, interval: DateInterval?) -> NSFetchRequest<Workout> {
        let request = Workout.defaultFetchRequest()
        request.predicate = Workout.activePredicate(sport: sport, interval: interval)
        request.sortDescriptors = [Workout.sortedByDateDescriptor()]
        return request
    }
}

extension StatsWorkoutsView {
    
    func date(for workout: Workout) -> String {
        DateFormatter.localizedString(from: workout.start, dateStyle: .medium, timeStyle: .none)
    }
    
    func time(for workout: Workout) -> String {
        formattedHoursMinutesPrettyString(for: workout.duration)
    }
    
    func distance(for workout: Workout) -> String {
        formattedDistanceString(for: workout.distance, zeroPadding: true)
    }
    
    func calories(for workout: Workout) -> String {
        formattedCaloriesString(for: workout.energyBurned, zeroPadding: true)
    }
    
    func elevation(for workout: Workout) -> String {
        formattedElevationString(for: workout.elevationAscended, zeroPadding: true)
    }
    
}

struct StatsWorkoutsView_Previews: PreviewProvider {
    static var viewContext = StorageProvider.preview.persistentContainer.viewContext
    static var interval = DateInterval(start: Date.distantPast, end: Date.distantFuture)
    
    static var previews: some View {
        NavigationView {
            StatsWorkoutsView(sport: nil, interval: interval)
                .environment(\.managedObjectContext, viewContext)
        }
        .preferredColorScheme(.dark)
    }
}

extension StatsWorkoutsView {
    
    struct Item: View {
        var text: String
        var detail: String
        var detailColor: Color = .primary
        
        var body: some View {
            VStack(alignment: .leading, spacing: 5.0) {
                Text(text)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(detail)
                    .foregroundColor(detailColor)
            }
        }
    }
    
}

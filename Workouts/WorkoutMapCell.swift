//
//  WorkoutMapCell.swift
//  WorkoutMapCell
//
//  Created by Axel Rivera on 8/13/21.
//

import SwiftUI
import MapKit
import Combine

final class WorkoutMapCellManager: ObservableObject {
    @Published var viewModel: WorkoutViewModel
    @Published var isFavorite = false
    @Published var tags = [TagLabelViewModel]()
    @Published var image: UIImage?
    
    init(viewModel: WorkoutViewModel) { 
        self.viewModel = viewModel
        isFavorite = viewModel.isFavorite
        tags = viewModel.tags
    }
    
    func updateViewModel(_ viewModel: WorkoutViewModel) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.viewModel = viewModel
            
            withAnimation {
                self.isFavorite = viewModel.isFavorite
                self.tags = viewModel.tags
            }
        }
    }
    
    func loadImage(forScheme scheme: ColorScheme) {
        let image = WorkoutStorage.getDiskImage(forID: viewModel.id, scheme: scheme)
        
        DispatchQueue.main.async {
            self.image = image
        }
    }
    
    private func reloadViewModel(_ viewModel: WorkoutViewModel) {
        guard viewModel.id == self.viewModel.id else { return }
        Log.debug("update view model: \(viewModel.id)")
        updateViewModel(viewModel)
    }
    
}

struct WorkoutMapCell: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var workoutManager: WorkoutManager
    @StateObject var manager: WorkoutMapCellManager
    
    let mapHeight = Constants.cachedWorkoutImageHeight
    
    var id: UUID {
        manager.viewModel.id
    }
    
    var publisher: NotificationCenter.Publisher {
        NotificationCenter.default.publisher(for: WorkoutStorage.viewModelUpdatedNotification)
    }
        
    init(viewModel: WorkoutViewModel, isPreview: Bool = false) {
        _manager = StateObject(wrappedValue: WorkoutMapCellManager(viewModel: viewModel))
    }
    
    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 2.0) {
                HStack {
                    Text(manager.viewModel.dateString())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if manager.isFavorite {
                        Spacer()
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                    }
                }
                
                Text(manager.viewModel.title)
                    .font(.title)
                    .padding(.bottom, 5.0)
                
                if manager.tags.isPresent {
                    TagLine(tags: manager.tags)
                }
                
                statsView()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            if manager.viewModel.hasLocationData {
                if let image = manager.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(CGFloat(12))
                        .frame(height: mapHeight)
                } else {
                    Rectangle()
                        .background(.regularMaterial)
                        .cornerRadius(CGFloat(12))
                        .frame(height: mapHeight)
                }
            }
        }
        .padding([.leading, .trailing])
        .padding([.top, .bottom], CGFloat(10.0))
        .onAppear { manager.loadImage(forScheme: colorScheme )}
        .onReceive(publisher, perform: processNotification)
    }
    
    @ViewBuilder
    func statsView() -> some View {
        HStack {
            switch manager.viewModel.displayType() {
            case .cyclingDistance:
                distanceText()
                durationText()
                speedText()
                
                if !manager.viewModel.indoor {
                    elevationText()
                }
            case .runningWalkingDistance:
                distanceText()
                durationText()
                paceText()
                
                if !manager.viewModel.indoor {
                    elevationText()
                }
            case .other:
                durationText()
                
                if manager.viewModel.avgHeartRate > 0 {
                    heartRateText()
                }
                
                if manager.viewModel.calories > 0 {
                    caloriesText()
                }
            }
        }
    }
    
    @ViewBuilder
    func distanceText() -> some View {
        Text(manager.viewModel.distanceString)
            .font(.fixedBody)
            .foregroundColor(.distance)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    func durationText() -> some View {
        Text(manager.viewModel.durationString)
            .font(.fixedBody)
            .foregroundColor(.time)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    func speedText() -> some View {
        Text(manager.viewModel.speedString)
            .font(.fixedBody)
            .foregroundColor(.speed)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    func paceText() -> some View {
        Text(manager.viewModel.paceString)
            .font(.fixedBody)
            .foregroundColor(.pace)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    func caloriesText() -> some View {
        Text(manager.viewModel.calorieString)
            .font(.fixedBody)
            .foregroundColor(.calories)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    func heartRateText() -> some View {
        Text(manager.viewModel.avgHeartRateString)
            .font(.fixedBody)
            .foregroundColor(.calories)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    func elevationText() -> some View {
        Text(manager.viewModel.elevationString)
            .font(.fixedBody)
            .foregroundColor(.elevation)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
}

extension WorkoutMapCell {
    
    func processNotification(_ notification: Notification) {
        guard let viewModel = notification.userInfo?[WorkoutStorage.viewModelKey] as? WorkoutViewModel else { return }
        guard viewModel.id == manager.viewModel.id else { return }
        Log.debug("update view model: \(viewModel.id), date: \(viewModel.dateString())")
        manager.updateViewModel(viewModel)
        manager.loadImage(forScheme: colorScheme)
    }
    
}

struct WorkoutMapCell_Previews: PreviewProvider {
    static let viewContext = WorkoutsProvider.preview.container.viewContext
    static let workout = WorkoutsProvider.sampleWorkout(sport: .cycling, date: Date(), moc: viewContext)
    static let viewModel: WorkoutViewModel = WorkoutViewModel(workout: workout)
    
    static var previews: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 0.0) {
                    ForEach(1...5, id: \.self) { _ in
                        WorkoutMapCell(viewModel: viewModel)
                        Divider()
                    }
                }
            }
            .listStyle(PlainListStyle())
            .navigationTitle("Workouts")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

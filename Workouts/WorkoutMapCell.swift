//
//  WorkoutMapCell.swift
//  WorkoutMapCell
//
//  Created by Axel Rivera on 8/13/21.
//

import SwiftUI
import MapKit
import Combine

class WorkoutMapCellManager: ObservableObject {
    @Published var viewModel: WorkoutViewModel
    
    init(viewModel: WorkoutViewModel) {
        self.viewModel = viewModel
    }
}

struct WorkoutMapCell: View {
    @Environment(\.colorScheme) var colorScheme
    
    @StateObject var manager: WorkoutMapCellManager
    
    @State private var isFavorite = false
    @State private var tags = [TagLabelViewModel]()
    @State private var image: UIImage?
        
    private let mapHeight = Constants.cachedWorkoutImageHeight
    private let imageProvider = WorkoutImageProvider()
    
    var viewModel: WorkoutViewModel {
        manager.viewModel
    }
        
    init(viewModel: WorkoutViewModel) {
        _manager = StateObject(wrappedValue: WorkoutMapCellManager(viewModel: viewModel))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(viewModel.dateString())
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if isFavorite {
                    Spacer()
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                }
            }
            .padding(.top, CGFloat(3))
            
            Text(viewModel.title)
                .font(.title)
            
            if tags.isPresent {
                TagLine(tags: tags)
            }
            
            statsView()
            
            if viewModel.hasLocationData {
                if let image = image {
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
                        .opacity(0.5)
                        .overlay(ProgressView(), alignment: .center)
                }
            }
        }
        .onAppear(perform: load)
        .onReceive(publisher, perform: processNotification)
    }
    
    @ViewBuilder
    func statsView() -> some View {
        HStack(alignment: .center, spacing: 5) {
            switch viewModel.displayType() {
            case .cyclingDistance:
                distanceText()
                durationText()
                speedText()
                
                if !viewModel.indoor {
                    elevationText()
                }
            case .runningWalkingDistance:
                distanceText()
                durationText()
                paceText()
                
                if !viewModel.indoor {
                    elevationText()
                }
            case .other:
                durationText()
                
                if viewModel.avgHeartRate > 0 {
                    heartRateText()
                }
                
                if viewModel.calories > 0 {
                    caloriesText()
                }
            }
        }
    }
    
    @ViewBuilder
    func distanceText() -> some View {
        Text(viewModel.distanceString)
            .font(.fixedBody)
            .foregroundColor(.distance)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    func durationText() -> some View {
        Text(viewModel.durationString)
            .font(.fixedBody)
            .foregroundColor(.time)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    func speedText() -> some View {
        Text(viewModel.speedString)
            .font(.fixedBody)
            .foregroundColor(.speed)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    func paceText() -> some View {
        Text(viewModel.paceString)
            .font(.fixedBody)
            .foregroundColor(.pace)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    func caloriesText() -> some View {
        Text(viewModel.calorieString)
            .font(.fixedBody)
            .foregroundColor(.calories)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    func heartRateText() -> some View {
        Text(viewModel.avgHeartRateString)
            .font(.fixedBody)
            .foregroundColor(.calories)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    func elevationText() -> some View {
        Text(viewModel.elevationString)
            .font(.fixedBody)
            .foregroundColor(.elevation)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
}

extension WorkoutMapCell {
    
    func load() {
        let isFavorite = viewModel.isFavorite
        let tags = viewModel.tags
        let image = imageProvider.get(forID: viewModel.id, scheme: colorScheme)
        
        DispatchQueue.main.async {
            self.isFavorite = isFavorite
            self.tags = tags
            self.image = image
        }
    }
    
    func updateViewModel(_ viewModel: WorkoutViewModel) {
        let image = imageProvider.get(forID: viewModel.id, scheme: colorScheme)
        
        DispatchQueue.main.async {
            withAnimation {
                self.manager.viewModel = viewModel
                self.isFavorite = viewModel.isFavorite
                self.tags = viewModel.tags
                self.image = image
            }
        }
    }
    
    var publisher: NotificationCenter.Publisher {
        NotificationCenter.default.publisher(for: WorkoutStorage.viewModelUpdatedNotification)
    }
    
    func processNotification(_ notification: Notification) {
        guard let viewModel = notification.userInfo?[WorkoutStorage.viewModelKey] as? WorkoutViewModel else { return }
        guard viewModel.id == self.viewModel.id else { return }
        
        Log.debug("update view model: \(viewModel.id), date: \(viewModel.dateString())")
        updateViewModel(viewModel)
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

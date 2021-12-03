//
//  TagWorkoutsSelectButton.swift
//  Workouts
//
//  Created by Axel Rivera on 11/12/21.
//

import SwiftUI

struct TagWorkoutsSelectButton: View {
    @EnvironmentObject private var manager: TagWorkoutsSelectManager
    
    let viewModel: WorkoutCellViewModel
    let tags: [TagLabelViewModel]
    
    var body: some View {
        Button(action: toggle) {
            VStack(alignment: .leading, spacing: 5.0) {
                HStack(alignment: .center, spacing: 20.0) {
                    VStack(alignment: .leading, spacing: 5.0) {
                        HStack {
                            Text(viewModel.title)
                                .font(.fixedTitle3)
                            Spacer()
                            Text(viewModel.date.formatted(.dateTime.day().month().year().weekday()))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text(viewModel.distanceString)
                                .font(.fixedTitle2)
                                .foregroundColor(.distance)
                            
                            Divider()
                            
                            Text(viewModel.durationString)
                                .font(.fixedTitle2)
                                .foregroundColor(.time)
                            
                            Divider()
                            
                            Text(viewModel.speedOrPaceString)
                                .font(.fixedTitle2)
                                .foregroundColor(viewModel.speedOrPaceColor)
                            
                        }
                    }
                    Image(systemName: isSelected() ? "checkmark.circle" : "circle")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
                
                if tags.isPresent {
                    TagGrid(tags: tags)
                }
            }
            .padding()
            .background(backgroundColor())
        }
        .buttonStyle(WorkoutSelectButtonStyle())
    }
    
}

extension TagWorkoutsSelectButton {
    
    @ViewBuilder
    func backgroundColor() -> some View {
        if isSelected() {
            Color.accentColor.opacity(0.25)
        } else {
            Color.systemBackground
        }
    }
    
    func isSelected() -> Bool {
        manager.isSelected(workout: viewModel.id)
    }
    
    func toggle() {
        withAnimation {
            manager.toggleWorkout(viewModel.id)
        }
    }
    
}

struct WorkoutSelectButtonStyle: ButtonStyle {
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .foregroundColor(.primary)
    }

}

struct TagWorkoutsSelectButtoon_Previews: PreviewProvider {
    static let viewContext = StorageProvider.preview.persistentContainer.viewContext
    static let workout = StorageProvider.sampleWorkout(sport: .cycling, date: Date(), moc: viewContext)
    
    static let viewModel = workout.cellViewModel
    static let tagViewModel = TagSummaryViewModel(id: UUID(), name: "Sample Tag", color: .accentColor, gearType: .bike, archived: false)
    
    static let selectManager = TagWorkoutsSelectManager(viewModel: tagViewModel, context: viewContext)
    
    static let tags = [
        TagLabelViewModel(id: UUID(), name: "Sample Tag", color: .red, gearType: .none, archived: false),
        TagLabelViewModel(id: UUID(), name: "Sample Tag 2", color: .orange, gearType: .none, archived: false),
        TagLabelViewModel(id: UUID(), name: "Sample Tag 3", color: .purple, gearType: .none, archived: false),
    ]
    
    static var previews: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(1...5, id: \.self) { _ in
                        TagWorkoutsSelectButton(viewModel: viewModel, tags: tags)
                        Divider()
                    }
                }
            }
            .navigationTitle("Workouts")
            .navigationBarTitleDisplayMode(.inline)
            
        }
        .environmentObject(selectManager)
    }
    
    
}

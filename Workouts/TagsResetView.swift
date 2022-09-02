//
//  TagsResetView.swift
//  Workouts
//
//  Created by Axel Rivera on 11/28/21.
//

import SwiftUI
import CoreData

struct TagsResetView: View {
    @Environment(\.managedObjectContext) var viewContext
    
    var body: some View {
        TagsResetContentView(manager: TagsResetManager(context: viewContext))
    }
}

struct TagsResetContentView: View {
    enum ActiveAlert: Hashable, Identifiable {
        case allConfirmation
        case tagConfirmation(tag: Tag)
        var id: Self { self }
    }
    
    @StateObject var manager: TagsResetManager
    @State private var activeAlert: ActiveAlert?
    
    var body: some View {
        List {
            Section {
                Button(ActionStrings.resetAllTags, role: .destructive, action: { activeAlert = .allConfirmation })
                    .disabled(manager.isProcessing)
            } footer: {
                Text(TagStrings.resetAllTagsFooter)
            }
            
            if manager.tags.isPresent {
                Section {
                    ForEach(manager.tags, id: \.uuid) { tag in
                        row(for: tag)
                    }
                } header: {
                    Text(LabelStrings.activeTags)
                }
            }
            
            if manager.archived.isPresent {
                Section {
                    ForEach(manager.archived, id: \.uuid) { tag in
                        row(for: tag)
                    }
                } header: {
                    Text(LabelStrings.archivedTags)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .overlay(processOverlay())
        .onAppear { manager.reload() }
        .navigationTitle(NSLocalizedString("Reset Tags", comment: "Screen title"))
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $activeAlert) { alert in
            switch alert {
            case .allConfirmation:
                return Alert(
                    title: Text(TagStrings.areYouSureTitle),
                    message: Text(TagStrings.allResetConfirmationMessage),
                    primaryButton: Alert.Button.destructive(Text(ActionStrings.resetAll), action: manager.resetAllTags),
                    secondaryButton: Alert.Button.cancel()
                )
            case .tagConfirmation(let tag):
                return Alert(
                    title: Text(TagStrings.areYouSureTitle),
                    message: Text(TagStrings.singleResetConfirmationMessage(for: tag.name)),
                    primaryButton: Alert.Button.destructive(Text(ActionStrings.reset), action: { manager.resetTags(for: tag.uuid) }),
                    secondaryButton: Alert.Button.cancel()
                )
            }
        }
    }
    
    @ViewBuilder
    func row(for tag: Tag) -> some View {
        HStack {
            Text(tag.name)
            Spacer()
            Button(ActionStrings.reset, role: .destructive, action: { activeAlert = .tagConfirmation(tag: tag) })
                .foregroundColor(.red)
                .disabled(manager.isProcessing)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    func processOverlay() -> some View {
        if manager.isProcessing {
            HUDView()
        }
    }
}

struct TagsResetView_Previews: PreviewProvider {
    static var viewContext = WorkoutsProvider.preview.container.viewContext
    
    static var previews: some View {
        NavigationView {
            TagsResetView()
        }
        .environment(\.managedObjectContext, viewContext)
    }
}

// MARK: Manager

final class TagsResetManager: ObservableObject {
    
    @Published var tags = [Tag]()
    @Published var archived = [Tag]()
    @Published var isProcessing = false
    
    let context: NSManagedObjectContext
    let tagProvider: TagProvider
    let workoutTagProvider: WorkoutTagProvider
    
    init(context: NSManagedObjectContext) {
        self.context = context
        self.tagProvider = TagProvider(context: context)
        self.workoutTagProvider = WorkoutTagProvider(context: context)
    }
    
    func reload() {
        self.tags = tagProvider.activeTags(sport: nil)
        self.archived = tagProvider.archivedTags()
    }
    
    func resetAllTags() {
        if isProcessing { return }
        resetTags(forTag: nil)
    }
    
    func resetTags(for uuid: UUID) {
        if isProcessing { return }
        resetTags(forTag: uuid)
    }
    
    private func resetTags(forTag tag: UUID?) {
        DispatchQueue.main.async {
            self.isProcessing = true
        }
        
        context.performAndWait {
            var tags: [WorkoutTag]
            if let tag = tag {
                tags = workoutTagProvider.workoutTags(forTag: tag)
            } else {
                tags = workoutTagProvider.allWorkoutTags()
            }
            
            tags.forEach { $0.archive() }
        }
        
        do {
            try context.save()
            context.refreshAllObjects()
        } catch {
            Log.debug("failed to save context: \(error.localizedDescription)")
        }
        
        WorkoutStorage.resetAll()
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .refreshWorkoutsFilter,
                object: nil
            )
            
            self.isProcessing = false
        }
    }
    
}
